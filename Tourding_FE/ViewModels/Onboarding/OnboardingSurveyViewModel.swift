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

    @Published var selectedBikeType: BikeType? = nil
    @Published var selectedSkillLevel: RidingSkillLevel? = nil

    @Published var isFastCourseEnabled: Bool = true
    @Published var isStairAvoidanceEnabled: Bool = true
    @Published var isWaterAvoidanceEnabled: Bool = true

    var isCurrentStepValid: Bool {
        switch currentStep {
        case 1: return selectedBikeType != nil
        case 2: return selectedSkillLevel != nil
        default: return true
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
