//
//  DotsLoadingView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/16/25.
//

import SwiftUI

struct DotsLoadingView: View {
    var color: Color = Color.cyan
    var size: CGFloat = 10
    var spacing: CGFloat = 8
    var bounce: CGFloat = 6        // 위아래 튀는 높이
    var duration: Double = 0.4    // 한 점의 애니메이션 시간
    var delay: Double = 0.15       // 점 간 지연

    @State private var phase: Bool = false

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.main)
                    .frame(width: size, height: size)
                    // 위아래로 가볍게 점프
                    .offset(y: phase ? -bounce : 0)
                    // 살짝 깜빡이는 느낌
//                    .opacity(phase ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: duration)
                            .repeatForever()
                            .delay(Double(i) * delay),
                        value: phase
                    )
            }
        }
        .onAppear { phase = true }
    }
}

#Preview {
    DotsLoadingView()
}
