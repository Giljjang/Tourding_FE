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

    init(userRepository: UserRepositoryProtocol = UserRepository.shared) {
        self.userRepository = userRepository
    }

    /// GET /user/{id}/riding-profile 로 저장된 라이딩 스타일을 불러와 화면에 채운다.
    func loadRidingProfile() async {
        guard let uid = KeychainHelper.loadUid() else {
            print("❌ 라이딩 프로필 조회 실패: UID 없음")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await userRepository.getRidingProfile(userId: uid)
            selectedBikeType = BikeType(apiValue: response.routeOption.cyclingProfile)
            selectedSkillLevel = RidingSkillLevel(apiValue: response.routeOption.skillLevel)
            isFastCourseEnabled = response.routeOption.fastRoute
            isStairAvoidanceEnabled = response.routeOption.avoidSteps
            isWaterAvoidanceEnabled = response.routeOption.avoidFords
        } catch {
            print("❌ 라이딩 프로필 조회 실패: \(error)")
        }
    }

    /// PUT /user/{id}/riding-profile 로 변경된 라이딩 스타일을 저장. 성공 시 true.
    @discardableResult
    func saveRidingProfile() async -> Bool {
        guard let bikeType = selectedBikeType, let skillLevel = selectedSkillLevel else { return false }
        guard let uid = KeychainHelper.loadUid() else {
            print("❌ 라이딩 스타일 저장 실패: UID 없음")
            return false
        }

        let routeOption = RouteOptionDto(
            bikeType: bikeType,
            skillLevel: skillLevel,
            fastRoute: isFastCourseEnabled,
            avoidSteps: isStairAvoidanceEnabled,
            avoidFords: isWaterAvoidanceEnabled
        )

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await userRepository.updateRidingProfile(
                userId: uid,
                request: UpdateRidingProfileRequest(routeOption: routeOption)
            )
            print("✅ 라이딩 스타일 저장 성공")
            return true
        } catch {
            print("❌ 라이딩 스타일 저장 실패: \(error)")
            return false
        }
    }
}
