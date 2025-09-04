//
//  SheetDetailView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import SwiftUI

struct SheetDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("바텀 시트")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview {
    SheetDetailView()
}
