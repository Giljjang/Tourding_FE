//
//  OnboardingSurveyViewModel.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import Foundation

final class OnboardingSurveyViewModel: ObservableObject {
    static let totalSteps = 3

    @Published var currentStep: Int = 1

    @Published var selectedBikeType: BikeType = .normal
    @Published var selectedSkillLevel: RidingSkillLevel = .novice

    @Published var isFastCourseEnabled: Bool = true
    @Published var isStairAvoidanceEnabled: Bool = true
    @Published var isWaterAvoidanceEnabled: Bool = true

    func goToNextStep() {
        guard currentStep < Self.totalSteps else { return }
        currentStep += 1
    }

    func goToPreviousStep() {
        guard currentStep > 1 else { return }
        currentStep -= 1
    }
}
