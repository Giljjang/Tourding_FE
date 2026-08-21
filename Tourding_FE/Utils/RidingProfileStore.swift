//
//  RidingProfileStore.swift
//  Tourding_FE
//
//  라이딩 스타일 단일 공급원.
//
//  **서버는 `routeOption`을 안 보내면 디폴트로 계산한다** — 저장된 프로필을 꺼내 쓰지 않는다.
//  그래서 경로를 만드는 호출부가 전부 스타일을 직접 실어야 한다.
//  지금 그런 곳이 일곱이다 (라이딩 시작·DnD·삭제 / 스팟추가 / 상세 / 홈 routes·by-name).
//
//  일곱 곳이 각자 GET을 때리면 화면을 옮길 때마다 같은 값을 다시 받는다.
//  여기 모아 캐시하고, 스타일을 저장(PUT)할 때 `update(_:)`로 갱신한다.
//
//  회귀 방지 테스트: `RidingProfileStoreTests`
//

import Foundation

/// 구현이 `@MainActor`이므로 프로토콜도 같은 격리에 둔다.
/// 안 그러면 준수가 격리 경계를 넘어 Swift 6에서 에러가 된다.
@MainActor
protocol RidingProfileProviding: AnyObject {
    /// 지금 적용할 스타일. 캐시가 신선하면 네트워크를 타지 않는다.
    ///
    /// 조회에 실패하면 **마지막 성공값**을 돌려준다 — nil로 떨어뜨리면
    /// 사용자가 설정한 스타일이 조용히 무시된 경로가 나온다.
    /// 한 번도 못 읽었다면 그때만 nil이다.
    func currentOption(userId: Int) async -> RouteOptionModel?

    /// 스타일을 저장(PUT)한 직후 캐시를 그 값으로 맞춘다. 서버에 다시 묻지 않는다.
    ///
    /// **누가 저장했는지도 함께 기록한다** — 온보딩은 저장만 하고 조회는 하지 않아서,
    /// 귀속이 없으면 그 값이 다음 로그인 계정에게 그대로 넘어간다.
    func update(_ option: RouteOptionModel, userId: Int)

    /// 캐시를 낡은 것으로 표시한다. 값은 남겨 둔다 — 재조회가 실패하면 폴백에 쓴다.
    func invalidate()

    /// 세션 정리. 다음 사용자가 이어받지 않도록 값까지 버린다.
    func clear()

    /// **이번 세션에만 적용할 옵션.** 서버에 저장하지 않는다.
    ///
    /// 코스 편집에서 연 라이딩 스타일 화면이 여기에 값을 건다 —
    /// 마이페이지에서 여는 것과 달리 프로필을 바꾸지 않고 이번 경로에만 적용한다.
    /// 걸려 있는 동안에는 `currentOption`이 저장된 프로필 대신 이 값을 준다.
    /// nil을 넣으면 해제되고 저장된 프로필로 돌아간다.
    func setSessionOverride(_ option: RouteOptionModel?)

    /// 지금 걸려 있는 일시 옵션. 우선순위 판정(`RideStyleResolver`)에 쓴다.
    var sessionOverride: RouteOptionModel? { get }
}

@MainActor
final class RidingProfileStore: RidingProfileProviding {

    private let userRepository: UserRepositoryProtocol

    /// 마지막으로 성공한 값. `invalidate()`로도 지우지 않는다 — 폴백에 쓴다.
    private var cached: RouteOptionModel?

    /// 캐시가 누구 것인지. 계정이 바뀌면 다시 읽는다.
    /// 저장(`update`)으로 들어온 값도 반드시 귀속된다 — 안 하면 다음 계정에게 샌다.
    private var cachedUserId: Int?

    /// 다시 읽어야 하는지. **성공했을 때만** true가 된다.
    private var isFresh = false

    /// 이번 세션에만 적용할 옵션. 서버에 저장하지 않으므로 캐시와 분리해 둔다 —
    /// 섞으면 일시 옵션이 저장된 프로필인 양 `update`로 새어 나간다.
    private(set) var sessionOverride: RouteOptionModel?

    /// 진행 중인 조회. 여럿이 동시에 물어도 요청은 하나다.
    private var inFlight: Task<RouteOptionModel?, Never>?
    private var inFlightUserId: Int?

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func currentOption(userId: Int) async -> RouteOptionModel? {
        // 일시 옵션이 걸려 있으면 서버를 묻지 않는다
        if let sessionOverride { return sessionOverride }

        if isFresh, let cached, cachedUserId == userId {
            return cached
        }

        if let inFlight, inFlightUserId == userId {
            return await inFlight.value ?? fallback(for: userId)
        }

        let task = Task { [userRepository] () -> RouteOptionModel? in
            do {
                return try await userRepository.getRidingProfile(userId: userId).routeOption
            } catch {
                print("⚠️ 라이딩 스타일 조회 실패 — 마지막 값으로 진행: \(error)")
                return nil
            }
        }
        inFlight = task
        inFlightUserId = userId

        let loaded = await task.value

        // 사이에 clear()·다른 사용자 조회가 끼어들었으면 이 결과는 버린다
        guard inFlightUserId == userId else { return loaded ?? fallback(for: userId) }
        inFlight = nil
        inFlightUserId = nil

        if let loaded {
            cached = loaded
            cachedUserId = userId
            isFresh = true
            return loaded
        }

        return fallback(for: userId)
    }

    func update(_ option: RouteOptionModel, userId: Int) {
        // 진행 중이던 조회를 먼저 버린다.
        //
        // 안 버리면 그 GET이 뒤늦게 끝나면서 **서버의 옛 값으로 되돌리고**
        // `isFresh`까지 세워 재조회마저 막는다. 완료 경로의 가드는
        // `inFlightUserId`가 바뀐 경우만 걸러내므로 여기서 그 형태를 만들어 준다.
        // 프로덕션에 `invalidate()` 호출부가 없어 한 번 오염되면 로그아웃 전까지 남는다.
        inFlight?.cancel()
        inFlight = nil
        inFlightUserId = nil

        cached = option
        cachedUserId = userId
        isFresh = true
    }

    func invalidate() {
        isFresh = false
    }

    func setSessionOverride(_ option: RouteOptionModel?) {
        sessionOverride = option
    }

    func clear() {
        sessionOverride = nil
        inFlight?.cancel()
        inFlight = nil
        inFlightUserId = nil
        cached = nil
        cachedUserId = nil
        isFresh = false
    }

    /// 실패했을 때 쓸 마지막 성공값. 남의 계정 값이면 주지 않는다.
    private func fallback(for userId: Int) -> RouteOptionModel? {
        guard cachedUserId == userId else { return nil }
        return cached
    }
}

extension RidingProfileProviding {
    /// 이번 요청에 실을 스타일. 우선순위 판정은 `RideStyleResolver` 한 곳이다.
    ///
    /// 경로를 만드는 모든 호출부가 이걸 쓴다 — 저장소만 보면
    /// "이 경로에 적용된 스타일"(`appliedOption`)을 놓쳐, 스타일 화면이 보여주는 값과
    /// 요청에 실리는 값이 갈린다. 실측 로그에서 경로는 `cycling-road`인데
    /// 앱이 든 값은 `cycling-regular`였다.
    @MainActor
    func effectiveOption(
        userId: Int,
        editSession: RouteEditSessionProviding
    ) async -> RouteOptionModel? {
        RideStyleResolver.effectiveOption(
            sessionOverride: sessionOverride,
            appliedToRoute: editSession.appliedOption,
            isContinuingRoute: editSession.isUsed,
            savedProfile: await currentOption(userId: userId)
        )
    }
}
