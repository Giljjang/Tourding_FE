//
//  SheetLoadingView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/23/25.
//

import SwiftUI

struct SheetLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .gray5))
            
            Text("경로를 불러오는 중...")
                .font(.pretendardMedium(size: 16))
                .foregroundColor(.gray4)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    SheetLoadingView()
}
