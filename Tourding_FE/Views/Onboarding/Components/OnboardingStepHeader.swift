//
//  OnboardingStepHeader.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import SwiftUI

struct OnboardingStepHeader: View {
    let step: Int
    let totalSteps: Int
    let description: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            (Text("\(step)").foregroundColor(.gray6)
                + Text("/\(totalSteps)").foregroundColor(.gray3))
                .font(.pretendardMedium(size: 14))

            VStack(alignment: .leading, spacing: 1) {
                Text(description)
                    .font(.pretendardMedium(size: 14))
                    .foregroundColor(.gray4)

                Text(title)
                    .font(.pretendardSemiBold(size: 24))
                    .foregroundColor(.gray6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
