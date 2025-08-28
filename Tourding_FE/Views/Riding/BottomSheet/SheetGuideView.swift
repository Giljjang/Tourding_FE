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
            
            ScrollView(showsIndicators: false) {
                guideRowView()
            } // :ScrollView
            
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

//MARK: - guide View
struct guideRowView: View {
    let text: String = "도착지"
    let guideType: GuideModel.GuideType = .rightTurn
    let time: Int? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            
            switch guideType {
            case .rightTurn:
                Image("right")
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
            case .leftTurn:
                Image("left")
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
            case .straight:
                Image("straight")
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
            case .stopOver:
                Image("icon_stopover")
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(text)
                    .foregroundColor(.gray6)
                    .font(.pretendardSemiBold(size: 16))
                    .padding(.top, time == nil ? 24 : 13)
                    .padding(.bottom, time == nil ? 24 : 4)
                
                if let t = time {
                    let minutes = Int(t / 1000 / 60)   // 밀리초 → 분 변환
                        Text("\(minutes)분")
                        .font(.pretendardRegular(size: 14))
                        .foregroundColor(.gray4)
                }
                
            } // : VStack
            
            Spacer()
            
        } // : HStack
        .frame(height: 70)
        .background(Color.white)
    }
}

#Preview {
    SheetGuideView(ridingViewModel: RidingViewModel())
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
