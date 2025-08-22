//
//  SheetGuideView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/23/25.
//

import SwiftUI

struct SheetGuideView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @ObservedObject private var ridingViewModel: RidingViewModel

    init(ridingViewModel: RidingViewModel) {
        self.ridingViewModel = ridingViewModel
    }
    
    var body: some View {
        VStack(alignment: .leading,spacing: 0) {
            
            header
            
            Spacer()
            
        } // : VStack
        .background(.white)
    }
    
    //MARK: - View
    
    private var header: some View {
        HStack(spacing: 0) {
            Text("라이딩 중")
                .foregroundColor(.gray6)
                .font(.pretendardSemiBold(size: 20))
                .padding(.leading, 17)
            
            Spacer()
            
            Button(action:{
                modalManager.showModal(
                    title: "라이딩을 종료할까요?",
                    subText: "라이딩 종료시 홈 화면으로 이동돼요",
                    activeText: "종료하기",
                    showView: .ridingNextView,
                    onCancel: {
                        print("취소됨")
                    },
                    onActive: {
                        print("종료됨")
                        navigationManager.popToRoot()
                    }
                )
            }){
                Image("icon_close")
                    .padding(.vertical, 6)
                    .padding(.leading, 6)
                
                Text("종료")
                    .foregroundColor(.white)
                    .font(.pretendardSemiBold(size: 16))
                    .padding(.trailing, 12)
            }
            .background(Color(hex: "#FF4949"))
            .cornerRadius(10)
            .padding(.top, 3)
            .padding(.trailing, 16)
        } // : HStack
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 19)
    } // : header
}

#Preview {
    SheetGuideView(ridingViewModel: RidingViewModel())
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
