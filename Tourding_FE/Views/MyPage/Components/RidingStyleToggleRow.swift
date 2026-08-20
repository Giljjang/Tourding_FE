//
//  RidingStyleToggleRow.swift
//  Tourding_FE
//
//  Created by Claude on 8/20/26.
//

import SwiftUI

struct RidingStyleToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundColor(.gray5)

                Text(subtitle)
                    .font(.pretendardMedium(size: 14))
                    .foregroundColor(.gray4)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.mainCalm)
        }
    }
}
