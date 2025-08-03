//
//  RouteContinueModal.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/3/25.
//

import SwiftUI

struct RouteContinueModal: View {
    var onCancel: () -> Void
    var onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 0){
            Text("라이딩이 비정상 종료됐어요")
                .foregroundColor(.black)
                .font(.pretendardSemiBold(size: 20))
                .frame(height: 28)
                .padding(.top, 38)
            
            Text("안내했던 경로로 다시 시작할까요?")
                .foregroundColor(.gray4)
                .font(.pretendardMedium(size: 16))
                .frame(height: 26)
                .padding(.bottom, 27)
            
            HStack(alignment: .top, spacing: 8) {
                Button(action:{
                    onCancel()
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
                
                Button(action:{}){
                    Text("시작하기")
                        .foregroundColor(.white)
                        .font(.pretendardMedium(size: 14))
                        .frame(height: 22)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 41)
                        .background(Color.gray5)
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

#Preview {
    RouteContinueModal(
        onCancel: {
            print("취소 눌림")
        },
        onStart: {
            print("시작하기 눌림")
        }
    )
}
