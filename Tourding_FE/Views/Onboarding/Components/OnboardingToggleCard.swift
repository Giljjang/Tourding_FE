//
//  OnboardingToggleCard.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import SwiftUI

struct OnboardingToggleCard: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundColor(.gray6)

                Text(subtitle)
                    .font(.pretendardMedium(size: 14))
                    .foregroundColor(.gray4)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.mainCalm)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.customwhite)
        .cornerRadius(12)
    }
}
