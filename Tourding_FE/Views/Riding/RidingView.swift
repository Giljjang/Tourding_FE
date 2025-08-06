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
    
    @ObservedObject private var viewModel: RidingViewModel
    
    @State private var currentPosition: BottomSheetPosition = .medium
    
    init(viewModel: RidingViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 배경 컨텐츠
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if currentPosition == .large {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3), value: currentPosition)
                }
                
                // 바텀 시트
                CustomBottomSheet(
                    content: sheetContent,
                    screenHeight: geometry.size.height,
                    currentPosition: $currentPosition
                )
                
                backButton
                
                ridingStartButtom
                
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
                onCancel: {
                    print("취소됨")
                },
                onActive: {
                    print("시작됨")
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
    
    private var sheetContent: some View {
        VStack(alignment: .leading,spacing: 0) {
            // 헤더
            HStack(alignment: .top , spacing: 0) {
                Text("라이딩 코스")
                    .foregroundColor(.gray6)
                    .font(.pretendardSemiBold(size: 20))
                    .padding(.leading, 17)
                
                Spacer()
                
                Button(action:{}){
                    Image("icon_plus")
                    Text("스팟 추가")
                        .foregroundColor(.gray6)
                        .font(.pretendardSemiBold(size: 16))
                }
                .padding(.top, 1)
                .padding(.trailing, 16)
            } // : HStack
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 19)
            
            Divider()
                .frame(maxWidth:.infinity)
                .frame(height:1)
                .foregroundColor(.gray1)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            
            // 컨텐츠
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // 출발
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 1.72) {
                            Image("icon_point")
                                .padding(.horizontal, 2.9)
                                .padding(.top, 3.5)
                            
                            Text("출발")
                                .foregroundColor(Color.main)
                                .font(.pretendardRegular(size: 12))
                        } // : VStack
                        .padding(.horizontal, 4)
                        .padding(.trailing, 6)
                        
                        Text(viewModel.start)
                            .foregroundColor(.gray6)
                            .font(.pretendardSemiBold(size: 16))
                            .padding(.vertical, 11)
                            .padding(.horizontal, 14)
                    } // : HStack
                    .padding(.horizontal, 16)
                    
                    // 도착
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 2.96) {
                            Image("icon_destination")
                                .padding(.horizontal, 3)
                                .padding(.top, 3.5)
                            
                            Text("도착")
                                .foregroundColor(Color.main)
                                .font(.pretendardRegular(size: 12))
                        } // : VStack
                        .padding(.horizontal, 4)
                        .padding(.trailing, 6)
                        
                        Text(viewModel.end)
                            .foregroundColor(.gray6)
                            .font(.pretendardSemiBold(size: 16))
                            .padding(.vertical, 11)
                            .padding(.horizontal, 14)
                    } // : HStack
                    .padding(.horizontal, 16)
                    
                } // : VStack
            } // : ScrollView
            
            Spacer()
        } // : VStack
        .padding(.top, 8)
    } // : sheetContent
}

#Preview {
    RidingView(viewModel: RidingViewModel())
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
