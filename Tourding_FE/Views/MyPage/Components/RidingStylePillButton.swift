//
//  RidingStylePillButton.swift
//  Tourding_FE
//
//  Created by Claude on 8/20/26.
//

import SwiftUI

struct RidingStylePillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendardMedium(size: 14))
                .foregroundColor(isSelected ? .mainDark : .gray4)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? Color.mainLight : Color.gray1)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.mainCalm : Color.clear, lineWidth: 1)
                )
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
