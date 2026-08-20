//
//  OnboardingBikeTypeStepView.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import SwiftUI

struct OnboardingBikeTypeStepView: View {
    @ObservedObject var viewModel: OnboardingSurveyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            OnboardingStepHeader(
                step: 1,
                totalSteps: OnboardingSurveyViewModel.totalSteps,
                description: "맞춤 코스 추천을 위해 몇 가지 여쭤볼게요",
                title: "자전거 종류를 알려주세요"
            )

            VStack(spacing: 14) {
                ForEach(BikeType.allCases) { bikeType in
                    OnboardingSelectCard(
                        title: bikeType.rawValue,
                        isSelected: viewModel.selectedBikeType == bikeType,
                        action: { viewModel.selectedBikeType = bikeType }
                    )
                }
            }
        }
    }
}
