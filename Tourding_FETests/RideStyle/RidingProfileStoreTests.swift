//
//  RidingProfileStoreTests.swift
//  Tourding_FETests
//
//  라이딩 스타일 단일 공급원.
//
//  **서버는 `routeOption`을 안 보내면 디폴트로 계산한다** — 저장된 프로필을 꺼내 쓰지 않는다.
//  그래서 경로를 만드는 모든 호출부가 스타일을 직접 실어야 한다.
//  지금 그런 곳이 일곱이다 (라이딩 시작·DnD·삭제 / 스팟추가 / 상세 / 홈 routes·by-name).
//
//  일곱 곳이 각자 GET을 때리면 화면을 옮길 때마다 같은 값을 다시 받는다.
//  여기 한 곳에 모아 캐시하고, 스타일을 저장(PUT)할 때 갱신한다.
//
//  **조회 실패는 마지막 성공값으로 넘긴다.** nil로 떨어뜨리면 사용자가 설정한 스타일이
//  조용히 무시된 경로가 나온다 — 실패했다는 사실보다 그게 더 나쁘다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RidingProfileStoreTests {

    private let road = RouteOptionModel(
        cyclingProfile: "ROAD", fastRoute: true,
        avoidSteps: true, avoidFords: false, skillLevel: "INTERMEDIATE"
    )
    private let mtb = RouteOptionModel(
        cyclingProfile: "MTB", fastRoute: false,
        avoidSteps: false, avoidFords: true, skillLevel: "BEGINNER"
    )

    // MARK: - 캐시

    @Test func readsFromServerOnFirstUse() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = road
        let store = RidingProfileStore(userRepository: userRepository)

        let option = await store.currentOption(userId: 49)

        #expect(option == road)
        #expect(userRepository.getRidingProfileCallCount == 1)
        #expect(userRepository.capturedProfileUserIds == [49])
    }

    /// **핵심** — 두 번째부터는 네트워크를 타지 않는다.
    /// 일곱 호출부가 각자 GET하던 것을 없애려고 만든 타입이다.
    @Test func laterUsesHitCacheWithoutNetwork() async {
        let userRepository = FakeUserRepository()
        let store = RidingProfileStore(userRepository: userRepository)

        _ = await store.currentOption(userId: 49)
        _ = await store.currentOption(userId: 49)
        _ = await store.currentOption(userId: 49)

        #expect(userRepository.getRidingProfileCallCount == 1)
    }

    /// 스타일을 저장(PUT)하면 서버에 다시 묻지 않고 그 값으로 갱신한다.
    /// 설정 화면에서 바꾸고 돌아오는 경로가 이걸로 즉시 반영된다.
    @Test func updateReplacesCacheWithoutNetwork() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = road
        let store = RidingProfileStore(userRepository: userRepository)
        _ = await store.currentOption(userId: 49)

        store.update(mtb, userId: 49)
        let option = await store.currentOption(userId: 49)

        #expect(option == mtb)
        #expect(userRepository.getRidingProfileCallCount == 1, "저장한 값을 알고 있으므로 다시 읽지 않는다")
    }

    /// 저장을 먼저 한 경우(온보딩)에도 서버를 거치지 않는다
    @Test func updateBeforeAnyLoadSeedsTheCache() async {
        let userRepository = FakeUserRepository()
        let store = RidingProfileStore(userRepository: userRepository)

        store.update(mtb, userId: 49)
        let option = await store.currentOption(userId: 49)

        #expect(option == mtb)
        #expect(userRepository.getRidingProfileCallCount == 0)
    }

    // MARK: - 실패

    /// **실패해도 마지막 성공값을 쓴다.** nil로 떨어지면 디폴트 스타일로 경로가 나온다
    @Test func failureFallsBackToLastKnownValue() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = road
        let store = RidingProfileStore(userRepository: userRepository)
        _ = await store.currentOption(userId: 49)

        userRepository.getRidingProfileError = FakeUserRepository.FakeError.notConfigured
        store.invalidate()
        let option = await store.currentOption(userId: 49)

        #expect(option == road)
    }

    /// 한 번도 못 읽었고 실패까지 하면 줄 값이 없다.
    /// 이때만 키가 빠지고 서버 디폴트로 계산된다.
    @Test func returnsNilWhenNeverLoadedAndRequestFails() async {
        let userRepository = FakeUserRepository()
        userRepository.getRidingProfileError = FakeUserRepository.FakeError.notConfigured
        let store = RidingProfileStore(userRepository: userRepository)

        let option = await store.currentOption(userId: 49)

        #expect(option == nil)
    }

    /// 실패를 캐시하지 않는다 — 다음 요청에서 다시 시도해야 한다
    @Test func retriesAfterFailure() async {
        let userRepository = FakeUserRepository()
        userRepository.getRidingProfileError = FakeUserRepository.FakeError.notConfigured
        let store = RidingProfileStore(userRepository: userRepository)
        _ = await store.currentOption(userId: 49)

        userRepository.getRidingProfileError = nil
        userRepository.ridingProfile = mtb
        let option = await store.currentOption(userId: 49)

        #expect(option == mtb)
        #expect(userRepository.getRidingProfileCallCount == 2)
    }

    // MARK: - 동시 호출

    /// 화면 여럿이 같은 순간에 물어도 GET은 한 번이다.
    /// 진입 직후 라이딩 화면과 시트가 함께 뜨는 경로가 실제로 있다.
    @Test func concurrentCallersShareOneRequest() async {
        let userRepository = FakeUserRepository()
        let gate = TestGate()
        userRepository.beforeGetRidingProfile = { await gate.wait() }
        let store = RidingProfileStore(userRepository: userRepository)

        let callers = (0..<5).map { _ in Task { await store.currentOption(userId: 49) } }
        await Task.yield()
        gate.open()
        for caller in callers { _ = await caller.value }

        #expect(userRepository.getRidingProfileCallCount == 1)
    }

    // MARK: - 사용자 전환

    /// 다른 계정으로 로그인하면 남의 스타일을 쓰면 안 된다
    @Test func reloadsWhenUserChanges() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = road
        let store = RidingProfileStore(userRepository: userRepository)
        _ = await store.currentOption(userId: 49)

        userRepository.ridingProfile = mtb
        let option = await store.currentOption(userId: 777)

        #expect(option == mtb)
        #expect(userRepository.capturedProfileUserIds == [49, 777])
    }

    /// 로그아웃하면 캐시를 버린다 — 다음 사용자가 이어받으면 안 된다
    @Test func clearDropsCache() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = road
        let store = RidingProfileStore(userRepository: userRepository)
        _ = await store.currentOption(userId: 49)

        store.clear()
        userRepository.getRidingProfileError = FakeUserRepository.FakeError.notConfigured
        let option = await store.currentOption(userId: 49)

        #expect(option == nil, "지운 뒤에는 폴백할 값도 없어야 한다")
    }

    /// **저장만 하고 조회한 적 없는 값이 다른 사용자에게 새면 안 된다.**
    ///
    /// 온보딩이 정확히 그 경로다 — PUT 성공 후 조회 없이 캐시에 들어간다.
    /// 귀속을 안 하면 다음 계정이 그대로 물려받는다.
    @Test func updatedOptionDoesNotLeakToAnotherUser() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = mtb
        let store = RidingProfileStore(userRepository: userRepository)

        store.update(road, userId: 49)
        let optionForOther = await store.currentOption(userId: 777)

        #expect(optionForOther == mtb, "다른 계정은 자기 프로필을 받아야 한다")
    }

    // MARK: - 저장이 진행 중인 조회를 이긴다

    /// **저장 직후 뒤늦게 도착한 조회 응답이 새 스타일을 덮으면 안 된다.**
    ///
    /// `clear()` 는 `inFlight` 를 무효화하지만 `update()` 는 하지 않았다.
    /// 그래서 진입 때 걸어둔 GET 이 느리게 끝나면, 그 사이 저장한 값을
    /// **서버의 옛 값으로 되돌리고 `isFresh` 까지 세워** 재조회도 막았다.
    /// 프로덕션에 `invalidate()` 호출부가 없으므로 로그아웃 전까지 자가 치유되지 않는다.
    @Test func lateResponseDoesNotOverwriteSavedOption() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = road          // 서버에 남아 있는 옛 값
        let gate = TestGate()
        userRepository.beforeGetRidingProfile = { await gate.wait() }
        let store = RidingProfileStore(userRepository: userRepository)

        // 진입 시 조회 시작 — 아직 응답 전
        let pending = Task { await store.currentOption(userId: 49) }
        await Task.yield()

        // 그 사이 스타일 화면에서 MTB로 저장
        store.update(mtb, userId: 49)

        // 이제야 옛 값(ROAD)으로 응답이 도착
        gate.open()
        _ = await pending.value

        #expect(await store.currentOption(userId: 49) == mtb,
                "저장한 값이 늦게 온 응답에 덮이면 안 된다")
    }
}
