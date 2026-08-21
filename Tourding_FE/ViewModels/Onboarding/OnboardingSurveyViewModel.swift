//
//  OnboardingSurveyViewModel.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import Foundation

@MainActor
final class OnboardingSurveyViewModel: ObservableObject {
    static let totalSteps = 3

    @Published var currentStep: Int = 1

    @Published var selectedBikeType: BikeType? = nil
    @Published var selectedSkillLevel: RidingSkillLevel? = nil

    @Published var isFastCourseEnabled: Bool = true
    @Published var isStairAvoidanceEnabled: Bool = true
    @Published var isWaterAvoidanceEnabled: Bool = true

    @Published var isSubmitting: Bool = false

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

    init(userRepository: UserRepositoryProtocol = UserRepository(),
         userSession: UserSessionProviding = KeychainUserSession(),
         profileStore: RidingProfileProviding? = nil) {
        self.userRepository = userRepository
        self.userSession = userSession
        self.injectedProfileStore = profileStore
    }

    var isCurrentStepValid: Bool {
        switch currentStep {
        case 1: return selectedBikeType != nil
        case 2: return selectedSkillLevel != nil
        default: return true
        }
    }

    /// 온보딩에서 선택한 라이딩 프로필을 서버에 저장. 성공 시 true.
    @discardableResult
    func submitRidingProfile() async -> Bool {
        guard let bikeType = selectedBikeType, let skillLevel = selectedSkillLevel else { return false }
        guard let uid = userSession.userId else {
            print("❌ 라이딩 프로필 저장 실패: UID 없음")
            return false
        }

        let routeOption = RouteOptionModel(
            bikeType: bikeType,
            skillLevel: skillLevel,
            fastRoute: isFastCourseEnabled,
            avoidSteps: isStairAvoidanceEnabled,
            avoidFords: isWaterAvoidanceEnabled
        )

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await userRepository.updateRidingProfile(
                userId: uid,
                request: UpdateRidingProfileRequest(routeOption: routeOption)
            )
            // 첫 경로부터 이 스타일이 적용되도록 캐시를 미리 채운다
            profileStore.update(routeOption, userId: uid)
            print("✅ 라이딩 프로필 저장 성공")
            return true
        } catch {
            print("❌ 라이딩 프로필 저장 실패: \(error)")
            return false
        }
    }

    func goToNextStep() {
        guard currentStep < Self.totalSteps else { return }
        currentStep += 1
    }

    func goToPreviousStep() {
        guard currentStep > 1 else { return }
        currentStep -= 1
    }
}
