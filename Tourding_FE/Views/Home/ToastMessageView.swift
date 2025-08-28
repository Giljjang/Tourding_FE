//
//  ToastMessageView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/29/25.
//

import SwiftUI

struct ToastMessageView: View {
    var body: some View {
        HStack(spacing: 8){
            Image("toast")
                .padding(.leading, 20)
            
            Text("라이딩이 종료되었어요")
                .foregroundColor(.white)
                .font(.pretendardMedium(size: 16))
            
            Spacer()
        } // : HStack
        .frame(height: 50)
        .background(Color.mainCalm)
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

#Preview {
    ToastMessageView()
}
