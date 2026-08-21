//
//  TemporaryRideStyleTests.swift
//  Tourding_FETests
//
//  코스 편집에서 연 라이딩 스타일은 **서버에 저장하지 않는다.**
//
//  같은 화면이 두 곳에서 열린다 —
//    마이페이지 → 프로필을 바꾼다 (PUT). 앞으로 만드는 모든 경로에 적용된다.
//    코스 편집 시트 → 이번 경로에만 적용한다. 서버 프로필은 건드리지 않는다.
//
//  일시 옵션은 저장되지 않으므로 **POST로 다시 계산해야만 반영된다.**
//  GET /routes는 서버에 저장된 경로를 그대로 읽을 뿐이다 —
//  실측 로그에서 스타일을 바꾸고 돌아와도 거리·좌표 개수가 글자 하나까지 같았다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct TemporaryRideStyleTests {

    private let saved = RouteOptionModel(
        cyclingProfile: "cycling-regular", fastRoute: true,
        avoidSteps: true, avoidFords: true, skillLevel: "BEGINNER"
    )
    private let temporary = RouteOptionModel(
        cyclingProfile: "cycling-mountain", fastRoute: false,
        avoidSteps: false, avoidFords: false, skillLevel: "PRO"
    )

    private var route: [LocationNameModel] {
        [
            TestRoute.location(sequenceNum: 0, name: "출발", type: "Start", lat: "37.0", lon: "127.0"),
            TestRoute.location(sequenceNum: 1, name: "경유", type: "WayPoint", lat: "37.1", lon: "127.1"),
            TestRoute.location(sequenceNum: 2, name: "도착", type: "Goal", lat: "37.2", lon: "127.2")
        ]
    }

    private func storeHolding(_ option: RouteOptionModel) -> (RidingProfileStore, FakeUserRepository) {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = option
        return (RidingProfileStore(userRepository: userRepository), userRepository)
    }

    // MARK: - 저장소의 세션 오버라이드

    /// 일시 옵션을 걸면 저장된 프로필 대신 그 값이 나온다
    @Test func sessionOverrideWinsOverSavedProfile() async {
        let (store, userRepository) = storeHolding(saved)
        _ = await store.currentOption(userId: 49)

        store.setSessionOverride(temporary)

        #expect(await store.currentOption(userId: 49) == temporary)
        #expect(userRepository.updateRidingProfileCallCount == 0, "서버에 저장하지 않는다")
    }

    /// 아직 프로필을 읽은 적이 없어도 일시 옵션은 바로 쓸 수 있다 — 네트워크를 타지 않는다
    @Test func sessionOverrideWorksBeforeAnyProfileLoad() async {
        let (store, userRepository) = storeHolding(saved)

        store.setSessionOverride(temporary)

        #expect(await store.currentOption(userId: 49) == temporary)
        #expect(userRepository.getRidingProfileCallCount == 0)
    }

    /// 해제하면 저장된 프로필로 돌아간다
    @Test func clearingOverrideRestoresSavedProfile() async {
        let (store, _) = storeHolding(saved)
        store.setSessionOverride(temporary)

        store.setSessionOverride(nil)

        #expect(await store.currentOption(userId: 49) == saved)
    }

    /// 로그아웃하면 일시 옵션도 사라진다
    @Test func clearDropsSessionOverride() async {
        let (store, userRepository) = storeHolding(saved)
        store.setSessionOverride(temporary)

        store.clear()
        userRepository.getRidingProfileError = FakeUserRepository.FakeError.notConfigured

        #expect(await store.currentOption(userId: 49) == nil)
    }

    /// 일시 옵션은 계정과 무관하다 — 세션 것이므로 사용자가 바뀌면 clear()로 지운다.
    /// 다만 같은 세션 안에서는 userId를 바꿔 물어도 그대로다.
    @Test func sessionOverrideIsNotTiedToProfileFetch() async {
        let (store, userRepository) = storeHolding(saved)
        store.setSessionOverride(temporary)

        _ = await store.currentOption(userId: 49)

        #expect(userRepository.getRidingProfileCallCount == 0, "오버라이드가 있으면 서버를 묻지 않는다")
    }

    // MARK: - 설정 화면의 두 모드

    /// **코스 편집에서 연 경우 — 서버에 저장하지 않는다**
    @Test func temporaryModeDoesNotPersistToServer() async {
        let userRepository = FakeUserRepository()
        let store = SpyProfileStore()
        let viewModel = RidingStyleSettingsViewModel(
            userRepository: userRepository,
            userSession: FakeUserSession(userId: 49),
            profileStore: store,
            isTemporary: true
        )
        viewModel.selectedBikeType = .mountain
        viewModel.selectedSkillLevel = .expert

        let done = await viewModel.saveRidingProfile()

        #expect(done == true, "화면은 정상적으로 닫혀야 한다")
        #expect(userRepository.updateRidingProfileCallCount == 0, "PUT을 보내지 않는다")
        #expect(store.updatedOptions.isEmpty, "저장된 프로필 캐시도 건드리지 않는다")
        #expect(store.sessionOverrides.last??.cyclingProfile == BikeType.mountain.apiValue)
    }

    /// **마이페이지에서 연 경우 — 기존대로 서버에 저장한다**
    @Test func persistentModeStillSavesToServer() async {
        let userRepository = FakeUserRepository()
        let store = SpyProfileStore()
        let viewModel = RidingStyleSettingsViewModel(
            userRepository: userRepository,
            userSession: FakeUserSession(userId: 49),
            profileStore: store
        )
        viewModel.selectedBikeType = .mountain
        viewModel.selectedSkillLevel = .expert

        let done = await viewModel.saveRidingProfile()

        #expect(done == true)
        #expect(userRepository.updateRidingProfileCallCount == 1)
        #expect(store.updatedOptions.count == 1)
        #expect(store.sessionOverrides.isEmpty, "프로필 저장은 일시 옵션을 만들지 않는다")
    }

    /// **편집 창에 머무는 동안에는 방금 고른 값이 유지된다.**
    ///
    /// 스팟을 추가하러 갔다 오거나 스타일 화면을 다시 열어도, 이 편집 세션에서
    /// 정한 스타일은 그대로다. 매번 초기화되면 고를 때마다 다시 골라야 한다.
    @Test func styleScreenKeepsChoiceWhileEditorIsAlive() async {
        let (store, userRepository) = storeHolding(saved)
        store.setSessionOverride(temporary)          // 이 편집 세션에서 고른 값
        let viewModel = RidingStyleSettingsViewModel(
            userRepository: userRepository,
            userSession: FakeUserSession(userId: 49),
            profileStore: store,
            isTemporary: true
        )

        await viewModel.loadRidingProfile()

        #expect(viewModel.selectedBikeType == .mountain, "방금 고른 값이 남아 있다")
        #expect(userRepository.getRidingProfileCallCount == 0)
    }

    /// **편집 창을 벗어나면 초기화된다.**
    /// `finishEditSession()`이 일시 옵션을 걷으므로 다음에 열면 서버 값이다.
    @Test func styleScreenResetsAfterLeavingEditor() async {
        let (store, userRepository) = storeHolding(saved)
        let riding = makeTestRidingViewModel(profileStore: store, userId: 49)
        store.setSessionOverride(temporary)

        riding.finishEditSession()                    // 뒤로가기 · 라이딩 종료

        let viewModel = RidingStyleSettingsViewModel(
            userRepository: userRepository,
            userSession: FakeUserSession(userId: 49),
            profileStore: store,
            isTemporary: true
        )
        await viewModel.loadRidingProfile()

        #expect(viewModel.selectedBikeType == BikeType(apiValue: saved.cyclingProfile))
    }

    // MARK: - 일시 옵션이 실제 경로에 반영되는가

    /// **일시 옵션은 저장되지 않으므로 POST로 다시 계산해야만 반영된다.**
    @Test func temporaryOptionReachesRouteRequest() async {
        let (store, _) = storeHolding(saved)
        let repository = FakeRouteRepository()
        let riding = makeTestRidingViewModel(
            repository: repository, profileStore: store, userId: 49
        )
        store.setSessionOverride(temporary)

        _ = await riding.postRidingStartAPI(locationData: route)

        #expect(repository.capturedPostRoutes.last?.routeOption == temporary)
    }

    /// 스팟 추가처럼 다른 화면이 만드는 경로에도 같은 일시 옵션이 적용된다 —
    /// 편집 세션 동안 만드는 경로는 모두 같은 스타일이어야 한다
    @Test func temporaryOptionAppliesToOtherScreensToo() async {
        let (store, _) = storeHolding(saved)
        let repository = FakeRouteRepository()
        let spotAdd = SpotAddViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49),
            profileStore: store,
            editSession: RouteEditSession()
        )
        store.setSessionOverride(temporary)

        await spotAdd.postRouteAPI(
            originalData: route,
            updatedData: Tourding_FE.SpotData(
                title: "신규", addr1: "", typeCode: "A05", contentid: "9", contenttypeid: "39",
                firstimage: "", firstimage2: "", mapx: "127.9", mapy: "37.9"
            )
        )

        #expect(repository.capturedPostRoutes.last?.routeOption == temporary)
    }

    // MARK: - 복귀 시 재계산

    /// **스타일이 바뀐 채 돌아오면 경로를 다시 계산해야 한다.**
    ///
    /// 실측 로그에서 확인한 결함이다 — 복귀 경로가 `GET /routes`만 불렀다.
    /// GET은 서버에 저장된 경로를 그대로 읽을 뿐이라 저장 전후의 거리·좌표 개수가
    /// 글자 하나까지 같았다. 일시 옵션은 서버에 저장조차 되지 않으므로
    /// POST로 다시 계산하지 않으면 영영 반영되지 않는다.
    @Test func returningWithChangedStyleRecalculatesRoute() async {
        let (store, _) = storeHolding(saved)
        let repository = FakeRouteRepository()
        let riding = makeTestRidingViewModel(
            repository: repository, profileStore: store, userId: 49
        )
        riding.routeLocation = route
        await riding.loadRidingProfile()          // 진입 시 저장된 프로필

        store.setSessionOverride(temporary)       // 스타일 화면에서 일시 변경
        riding.handleReturnFromChild(locationManager: LocationManager(), routeSource: .draft)
        await riding.pendingProfileLoad?.value

        #expect(repository.capturedPostRoutes.last?.routeOption == temporary,
                "바뀐 스타일로 POST가 나가야 한다")
    }

    /// 스타일을 바꾸지 않고 돌아오면 다시 계산하지 않는다 —
    /// 자식 화면 복귀는 잦으므로 매번 재계산하면 서버를 불필요하게 민다
    @Test func returningWithSameStyleDoesNotRecalculate() async {
        let (store, _) = storeHolding(saved)
        let repository = FakeRouteRepository()
        let riding = makeTestRidingViewModel(
            repository: repository, profileStore: store, userId: 49
        )
        riding.routeLocation = route
        await riding.loadRidingProfile()

        riding.handleReturnFromChild(locationManager: LocationManager(), routeSource: .draft)
        await riding.pendingProfileLoad?.value

        #expect(repository.capturedPostRoutes.isEmpty, "바뀐 게 없으면 POST하지 않는다")
    }

    /// 경로가 아직 없으면 재계산할 것도 없다
    @Test func doesNotRecalculateWithoutRoute() async {
        let (store, _) = storeHolding(saved)
        let repository = FakeRouteRepository()
        let riding = makeTestRidingViewModel(
            repository: repository, profileStore: store, userId: 49
        )
        await riding.loadRidingProfile()

        store.setSessionOverride(temporary)
        riding.handleReturnFromChild(locationManager: LocationManager(), routeSource: .draft)
        await riding.pendingProfileLoad?.value

        #expect(repository.capturedPostRoutes.isEmpty)
    }

    /// **라이딩을 끝내도 편집 화면에 남아 있으면 스타일은 유지된다.**
    ///
    /// `endRiding`은 화면을 pop하지 않는다 — `flag`를 false로 되돌려 편집 모드로
    /// 돌아갈 뿐이다. 여기서 세션을 끝내면 화면은 그대로인데 스타일만 초기화된다.
    /// 세션 종료는 **NavigationStack에서 코스 편집이 빠질 때** 판정한다.
    @Test func endingRideKeepsTemporaryStyleWhileEditorStaysOpen() async {
        let (store, _) = storeHolding(saved)
        let riding = makeTestRidingViewModel(profileStore: store, userId: 49)
        store.setSessionOverride(temporary)

        await riding.endRiding(isStart: false, locationManager: LocationManager())

        #expect(await store.currentOption(userId: 49) == temporary,
                "라이딩만 끝났을 뿐 편집 창은 살아 있다")
    }
}
