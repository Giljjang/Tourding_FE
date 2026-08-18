//
//  OnboardingProgressBar.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray2)

                Capsule()
                    .fill(Color.gray5)
                    .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps))
            }
        }
        .frame(height: 6)
    }
}
