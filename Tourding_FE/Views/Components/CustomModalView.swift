//
//  CustomModalView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/3/25.
//

import SwiftUI

struct CustomModalView: View {
    @ObservedObject var modalManager: ModalManager
    
    var body: some View {
        VStack(spacing: 0){
            Text(modalManager.title)
                .foregroundColor(.black)
                .font(.pretendardSemiBold(size: 20))
                .frame(height: 28)
                .padding(.top, 38)
            
            Text(modalManager.subText)
                .foregroundColor(.gray4)
                .font(.pretendardMedium(size: 16))
                .frame(height: 26)
                .padding(.bottom, 27)
            
            HStack(alignment: .top, spacing: 8) {
                Button(action:{
                    modalManager.onCancel?()
                    modalManager.hideModal()
                }){
                    Text("취소")
                        .foregroundColor(.gray4)
                        .font(.pretendardMedium(size: 14))
                        .frame(height: 22)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 52.5)
                        .background(Color.gray2)
                        .cornerRadius(10)
                } // : Button
                
                Button(action:{
                    modalManager.onActive?()
                    modalManager.hideModal()
                }){
                    Text(modalManager.activeText)
                        .foregroundColor(.white)
                        .font(.pretendardMedium(size: 14))
                        .frame(height: 22)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 41)
                        .background(modalManager.activeText == "탈퇴하기" || modalManager.activeText == "종료하기" ? Color.warningRed : Color.gray5)
                        .cornerRadius(10)
                } // : Button
            } // : HStack
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            
        } // :VStack
        .background(.white)
        .cornerRadius(20)
    }
}
