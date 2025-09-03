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
    private var currentPosition: BottomSheetPosition
    
    init(ridingViewModel: RidingViewModel, currentPosition: BottomSheetPosition) {
        self.ridingViewModel = ridingViewModel
        self.currentPosition = currentPosition
    }
    
    var body: some View {
        VStack(alignment: .leading,spacing: 0) {
            
            header
            
            ScrollView(showsIndicators: false) {
                ForEach(Array(ridingViewModel.guideList.enumerated()), id:\.1.sequenceNum){ index, item in
                    guideRowView(text: item.instructions,
                                 guideType: item.guideType ?? .straight,
                                 time: item.duration)
                    .background(index == 0 ? Color.gray1 : Color.white)
                }
                
                if currentPosition == .large {
                    Spacer()
                        .frame(height: 200)
                } else if currentPosition == .medium {
                    Spacer()
                        .frame(height: 400)
                }
                
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
                        modalManager.isToastMessage = true
                    }
                )
            }){
                HStack(spacing: 0) {
                    Image("icon_close")
                    
                    Text("종료")
                        .foregroundColor(.white)
                        .font(.pretendardSemiBold(size: 16))
                } // : HStack
                .padding(.vertical, 6)
                .padding(.leading, 6)
                .padding(.trailing, 12)
                .background(Color(hex: "#FF4949"))
                .cornerRadius(10)
            }
            .padding(.top, 3)
            .padding(.trailing, 16)
        } // : HStack
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 19)
    } // : header
}

//MARK: - guide View
struct guideRowView: View {
    let text: String
    let guideType: GuideModel.GuideType
    let time: Int?
    
    var body: some View {
        HStack(spacing: 0) {
            
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
            case .end:
                Image("end")
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
            case .start:
                Image("start")
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
            }
            
            Text(RidingViewModel.insertLineBreakAtMiddleWord(text))
                .foregroundColor(.gray6)
                .font(.pretendardSemiBold(size: 16))
            
            Spacer()
            
            if let t = time {
                Text(RidingViewModel.formatMillisecondsToMinutes(Double(t)))
                    .font(.pretendardRegular(size: 14))
                    .foregroundColor(.gray4)
                    .padding(.trailing, 28)
            }
            
        } // : HStack
        .frame(height: 70)
    }
}
