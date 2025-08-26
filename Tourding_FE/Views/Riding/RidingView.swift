//
//  RidingView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import SwiftUI

struct RidingView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @ObservedObject private var ridingViewModel: RidingViewModel
    
    @State private var currentPosition: BottomSheetPosition = .medium
    
    init(ridingViewModel: RidingViewModel) {
        self.ridingViewModel = ridingViewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 배경 컨텐츠
                NMapView(ridingViewModel: ridingViewModel)
                    .ignoresSafeArea(edges: .top)
                 
                if currentPosition == .large {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3), value: currentPosition)
                }
                
                backButton
                
                // 바텀 시트
                CustomBottomSheet(
                    content: SheetContentView(ridingViewModel: ridingViewModel),
                    screenHeight: geometry.size.height,
                    currentPosition: $currentPosition
                )
                
                ridingStartButtom
                
                // 커스텀 모달 뷰
                if modalManager.isPresented && modalManager.showView == .ridingView {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            modalManager.hideModal()
                        }
                    
                    CustomModalView(modalManager: modalManager)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                } // : if
                
            } // : ZStack
        } // : GeometryReader
        .navigationBarBackButtonHidden()
    }
    
    //MARK: - View
    private var backButton: some View {
        Button(action:{
            navigationManager.pop()
        }){
            Image("riding_back")
                .padding(.vertical, 8)
                .padding(.leading, 6)
                .padding(.trailing,10)
                .background(Color.white)
                .cornerRadius(30)
        }
        .position(x: 36, y: 53)
    } // : backButton
    
    private var ridingStartButtom: some View {
        Button(action:{
            modalManager.showModal(
                title: "라이딩을 시작할까요?",
                subText: "현재 제작된 코스로 라이딩을 진행해요",
                activeText: "시작하기",
                showView: .ridingView,
                onCancel: {
                    print("취소됨")
                },
                onActive: {
                    print("시작됨")
                    navigationManager.push(.RidingNextView)
                }
            )
        }){
            Text("라이딩 시작하기")
                .foregroundColor(.white)
                .font(.pretendardSemiBold(size: 16))
                .frame(height: 22)
                .padding(.vertical, 16)
                .padding(.horizontal, 130.5)
                .background(Color.gray5)
                .cornerRadius(10)
        }
        .padding(.bottom, 18)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .white.opacity(0), location: 0.00),
                    Gradient.Stop(color: .white, location: 0.15),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        ) // : background
    } // : ridingStartButtom
}

#Preview {
    RidingView(ridingViewModel: RidingViewModel())
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
