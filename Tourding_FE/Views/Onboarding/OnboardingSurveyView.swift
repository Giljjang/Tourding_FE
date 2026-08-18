//
//  OnboardingSurveyView.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import SwiftUI

struct OnboardingSurveyView: View {
    @StateObject private var viewModel = OnboardingSurveyViewModel()
    var onComplete: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            header

            OnboardingProgressBar(
                currentStep: viewModel.currentStep,
                totalSteps: OnboardingSurveyViewModel.totalSteps
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollView {
                stepContent
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
            }

            Spacer(minLength: 0)

            footer
        }
        .background(Color.gray1.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private var header: some View {
        ZStack {
            if viewModel.currentStep > 1 {
                HStack {
                    Button(action: viewModel.goToPreviousStep) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray5)
                            .padding()
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 56)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1:
            OnboardingBikeTypeStepView(viewModel: viewModel)
        case 2:
            OnboardingSkillLevelStepView(viewModel: viewModel)
        default:
            OnboardingCourseConditionStepView(viewModel: viewModel)
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Text("선택한 옵션은 나중에 다시 수정할 수 있어요")
                .font(.pretendardMedium(size: 14))
                .foregroundColor(.gray3)

            Button(action: handlePrimaryAction) {
                Text(isLastStep ? "완료하기" : "다음으로")
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundColor(.customwhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.gray5)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var isLastStep: Bool {
        viewModel.currentStep == OnboardingSurveyViewModel.totalSteps
    }

    private func handlePrimaryAction() {
        if isLastStep {
            onComplete()
        } else {
            viewModel.goToNextStep()
        }
    }
}

#Preview {
    OnboardingSurveyView()
}
