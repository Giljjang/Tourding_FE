//
//  OnboardingSkillLevelStepView.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import SwiftUI

struct OnboardingSkillLevelStepView: View {
    @ObservedObject var viewModel: OnboardingSurveyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            OnboardingStepHeader(
                step: 2,
                totalSteps: OnboardingSurveyViewModel.totalSteps,
                description: "맞춤 코스 추천을 위해 몇 가지 여쭤볼게요",
                title: "라이딩 숙련도를 알려주세요"
            )

            VStack(spacing: 14) {
                ForEach(RidingSkillLevel.allCases) { skillLevel in
                    OnboardingSelectCard(
                        title: skillLevel.rawValue,
                        subtitle: skillLevel.subtitle,
                        isSelected: viewModel.selectedSkillLevel == skillLevel,
                        action: { viewModel.selectedSkillLevel = skillLevel }
                    )
                }
            }
        }
    }
}
