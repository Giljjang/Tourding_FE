//
//  OnboardingCourseConditionStepView.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import SwiftUI

struct OnboardingCourseConditionStepView: View {
    @ObservedObject var viewModel: OnboardingSurveyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            OnboardingStepHeader(
                step: 3,
                totalSteps: OnboardingSurveyViewModel.totalSteps,
                description: "맞춤 코스 추천을 위해 몇 가지 여쭤볼게요",
                title: "코스 조건을 선택해주세요"
            )

            VStack(spacing: 14) {
                OnboardingToggleCard(
                    title: "빠른 코스",
                    subtitle: "효율적인 라이딩 코스를 원해요",
                    isOn: $viewModel.isFastCourseEnabled
                )
                OnboardingToggleCard(
                    title: "계단 회피",
                    subtitle: "계단이 있는 구간은 피할래요",
                    isOn: $viewModel.isStairAvoidanceEnabled
                )
                OnboardingToggleCard(
                    title: "물길 회피",
                    subtitle: "하천 등 물을 건너야 하는 구간은 피할래요",
                    isOn: $viewModel.isWaterAvoidanceEnabled
                )
            }
        }
    }
}
