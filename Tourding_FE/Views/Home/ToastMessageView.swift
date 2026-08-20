//
//  ToastMessageView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/29/25.
//

import SwiftUI

struct ToastMessageView: View {
    @EnvironmentObject var modalManager: ModalManager

    var body: some View {
        HStack(spacing: 8){
            Image("toast")
                .padding(.leading, 20)

            Text(modalManager.toastMessage)
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
        .environmentObject(ModalManager())
}
