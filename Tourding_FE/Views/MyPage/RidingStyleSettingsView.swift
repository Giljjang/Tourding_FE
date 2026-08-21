//
//  RidingStyleSettingsView.swift
//  Tourding_FE
//
//  Created by Claude on 8/20/26.
//

import SwiftUI

struct RidingStyleSettingsView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    @StateObject private var viewModel = RidingStyleSettingsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    section(title: "자전거 종류") {
                        RidingStylePillRow(
                            options: BikeType.allCases,
                            label: { $0.rawValue },
                            selection: $viewModel.selectedBikeType
                        )
                    }

                    Divider()
                        .frame(height: 1)
                        .overlay(Color.gray1)

                    section(title: "라이딩 숙련도") {
                        RidingStylePillRow(
                            options: RidingSkillLevel.allCases,
                            label: { $0.shortLabel },
                            selection: $viewModel.selectedSkillLevel
                        )
                    }

                    Divider()
                        .overlay(Color.gray1)

                    RidingStyleToggleRow(
                        title: "빠른 코스",
                        subtitle: "효율적인 라이딩 코스를 원해요",
                        isOn: $viewModel.isFastCourseEnabled
                    )

                    Divider()
                        .frame(height: 1)
                        .overlay(Color.gray1)

                    RidingStyleToggleRow(
                        title: "계단 회피",
                        subtitle: "계단이 있는 구간은 피할래요",
                        isOn: $viewModel.isStairAvoidanceEnabled
                    )

                    Divider()
                        .frame(height: 1)
                        .overlay(Color.gray1)

                    RidingStyleToggleRow(
                        title: "물길 회피",
                        subtitle: "하천 등 물을 건너야 하는 구간은 피할래요",
                        isOn: $viewModel.isWaterAvoidanceEnabled
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 22)
            }

            Spacer(minLength: 0)

            footer
        }
        .background(Color.customwhite.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await viewModel.loadRidingProfile()
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.pretendardSemiBold(size: 16))
                .foregroundColor(.gray5)

            content()
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(action: { navigationManager.pop() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray5)
                        .padding()
                }
                Spacer()
            }

            Text("라이딩 스타일 설정")
                .font(.pretendardMedium(size: 18))
                .foregroundColor(.gray5)
        }
        .frame(height: 56)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Text("선택한 옵션은 AI 코스 추천에 반영돼요")
                .font(.pretendardMedium(size: 14))
                .foregroundColor(.gray3)

            Button(action: handleSave) {
                Text("저장하기")
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundColor(.customwhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.gray5)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func handleSave() {
        Task {
            if await viewModel.saveRidingProfile() {
                navigationManager.pop()
                modalManager.showToast(message: "라이딩 스타일이 변경되었어요")
            }
        }
    }
}

#Preview {
    RidingStyleSettingsView()
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
