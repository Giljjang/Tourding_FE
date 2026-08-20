//
//  OnboardingSelectCard.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import SwiftUI

struct OnboardingSelectCard: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.pretendardSemiBold(size: 18))
                        .foregroundColor(.gray6)

                    if let subtitle {
                        Text(subtitle)
                            .font(.pretendardMedium(size: 14))
                            .foregroundColor(.gray4)
                    }
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.mainCalm)
                        .font(.system(size: 24))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.mainLight : Color.customwhite)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.mainCalm : Color.customwhite, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
