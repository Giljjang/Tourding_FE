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

    init(userRepository: UserRepositoryProtocol = UserRepository.shared) {
        self.userRepository = userRepository
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
        guard let uid = KeychainHelper.loadUid() else {
            print("❌ 라이딩 프로필 저장 실패: UID 없음")
            return false
        }

        let routeOption = RouteOptionDto(
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
