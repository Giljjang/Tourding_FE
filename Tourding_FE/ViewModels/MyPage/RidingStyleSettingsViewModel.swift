//
//  RidingStyleSettingsViewModel.swift
//  Tourding_FE
//
//  Created by Claude on 8/20/26.
//

import Foundation

@MainActor
final class RidingStyleSettingsViewModel: ObservableObject {
    @Published var selectedBikeType: BikeType? = nil
    @Published var selectedSkillLevel: RidingSkillLevel? = nil

    @Published var isFastCourseEnabled: Bool = false
    @Published var isStairAvoidanceEnabled: Bool = false
    @Published var isWaterAvoidanceEnabled: Bool = false

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false

    private let userRepository: UserRepositoryProtocol

    /// 저장 성공 후 캐시를 갱신할 공용 저장소.
    ///
    /// 기본 인자로 두면 `nonisolated` 컨텍스트에서 `@MainActor` 팩토리를 부르게 되어
    /// 컴파일되지 않는다 — 이 화면은 `@StateObject`로 인자 없이 생성된다.
    /// 그래서 획득을 **쓰는 시점**(@MainActor 메서드 안)으로 미룬다.
    private var profileStore: RidingProfileProviding {
        injectedProfileStore ?? DependencyProvider.makeRidingProfileStore()
    }
    private let injectedProfileStore: RidingProfileProviding?

    /// `userId` 공급자. ViewModel이 `KeychainHelper`를 직접 부르면 전역 상태에 묶여
    /// 테스트가 시뮬레이터 Keychain 상태에 좌우된다 — 실제로 병렬 실행에서 깨졌다.
    private let userSession: UserSessionProviding

    /// 코스 편집에서 열렸는가.
    ///
    /// `true`면 **서버에 저장하지 않고** 이번 경로에만 적용한다(세션 오버라이드).
    /// 마이페이지에서 열면 `false` — 프로필 자체를 바꾼다.
    private let isTemporary: Bool

    /// 편집 중인 경로 정보. 일시 모드에서 이 경로에 적용된 스타일을 우선 보여준다.
    private let injectedEditSession: RouteEditSessionProviding?
    private var editSession: RouteEditSessionProviding {
        injectedEditSession ?? DependencyProvider.makeRouteEditSession()
    }

    init(userRepository: UserRepositoryProtocol = UserRepository(),
         userSession: UserSessionProviding = KeychainUserSession(),
         profileStore: RidingProfileProviding? = nil,
         editSession: RouteEditSessionProviding? = nil,
         isTemporary: Bool = false) {
        self.injectedEditSession = editSession
        self.userRepository = userRepository
        self.userSession = userSession
        self.injectedProfileStore = profileStore
        self.isTemporary = isTemporary
    }

    /// GET /user/{id}/riding-profile 로 저장된 라이딩 스타일을 불러와 화면에 채운다.
    func loadRidingProfile() async {
        guard let uid = userSession.userId else {
            print("❌ 라이딩 프로필 조회 실패: UID 없음")
            return
        }

        isLoading = true
        defer { isLoading = false }

        // **이어서 가는 경로일 때만** 그 경로에 적용된 스타일을 보여준다.
        //
        //   최근 경로 이어서 가기 · 비정상 종료 복구 → 경로의 `appliedOption`
        //   홈 코스 만들기 · 추천 코스(draft)        → 마이페이지 프로필
        //
        // draft는 아직 "이어서 가는 경로"가 아니다. 직전에 다른 경로를 보며 남은
        // `appliedOption`이 있어도 그건 이 경로의 값이 아니다.
        //
        // 걸어둔 일시 옵션 자체를 다시 보여주지는 않는다 —
        // 그러면 "일시"가 아니라 누적 설정이 된다. 재계산까지 끝났다면
        // 그 값이 곧 경로의 `appliedOption`이라 여기서 자연스럽게 반영된다.
        if isTemporary, editSession.isUsed, let applied = editSession.appliedOption {
            apply(applied)
            return
        }

        do {
            let response = try await userRepository.getRidingProfile(userId: uid)
            apply(response.routeOption)

            // 이 화면은 편집기라 서버를 직접 읽는다(캐시를 보면 낡은 값 위에 저장하게 된다).
            // 대신 읽은 값을 공용 저장소에도 반영해야 한다 —
            // 안 그러면 화면에 보이는 스타일과 경로 요청에 실리는 스타일이 갈린다.
            profileStore.update(response.routeOption, userId: uid)
        } catch {
            print("❌ 라이딩 프로필 조회 실패: \(error)")
        }
    }

    private func apply(_ option: RouteOptionModel) {
        selectedBikeType = BikeType(apiValue: option.cyclingProfile)
        selectedSkillLevel = RidingSkillLevel(apiValue: option.skillLevel)
        isFastCourseEnabled = option.fastRoute
        isStairAvoidanceEnabled = option.avoidSteps
        isWaterAvoidanceEnabled = option.avoidFords
    }

    /// PUT /user/{id}/riding-profile 로 변경된 라이딩 스타일을 저장. 성공 시 true.
    /// 코스 편집에서 열렸다면(`isTemporary`) 저장 없이 세션 오버라이드만 건다.
    @discardableResult
    func saveRidingProfile() async -> Bool {
        guard let bikeType = selectedBikeType, let skillLevel = selectedSkillLevel else { return false }
        guard let uid = userSession.userId else {
            print("❌ 라이딩 스타일 저장 실패: UID 없음")
            return false
        }

        let routeOption = RouteOptionModel(
            bikeType: bikeType,
            skillLevel: skillLevel,
            fastRoute: isFastCourseEnabled,
            avoidSteps: isStairAvoidanceEnabled,
            avoidFords: isWaterAvoidanceEnabled
        )

        // 코스 편집에서 왔으면 서버에 저장하지 않는다 — 이번 경로에만 적용한다
        guard !isTemporary else {
            profileStore.setSessionOverride(routeOption)
            print("✅ 라이딩 스타일 일시 적용 (저장 안 함) — \(routeOption.logDescription)")
            return true
        }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await userRepository.updateRidingProfile(
                userId: uid,
                request: UpdateRidingProfileRequest(routeOption: routeOption)
            )
            // 서버에 저장된 값을 앱도 알고 있으므로 다시 읽지 않는다.
            // 이걸 빠뜨리면 코스 편집으로 돌아가도 옛 스타일로 경로가 나온다.
            profileStore.update(routeOption, userId: uid)
            print("✅ 라이딩 스타일 저장 성공")
            return true
        } catch {
            print("❌ 라이딩 스타일 저장 실패: \(error)")
            return false
        }
    }
}
