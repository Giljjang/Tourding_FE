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
    
    @State private var currentPosition: BottomSheetPosition = .loading
    
    init(ridingViewModel: RidingViewModel) {
        self.ridingViewModel = ridingViewModel
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
                
                backButton
                    .zIndex(1)
                
                if ridingViewModel.ridingMode == .afterStart {
                    toiletButton
                        .zIndex(1)
                    
                    csButton
                        .zIndex(1)
                    
                } // : if
                
                // 바텀 시트
                CustomBottomSheet(
                    content: sheetContent,
                    screenHeight: geometry.size.height,
                    currentPosition: $currentPosition,
                    ridingMode: ridingViewModel.ridingMode,
                    isLoading: ridingViewModel.isLoading
                )
                
                if !ridingViewModel.isLoading && ridingViewModel.ridingMode == .beforeStart {
                    ridingStartButtom
                }
                
                // 커스텀 모달 뷰
                if modalManager.isPresented && (modalManager.showView == .ridingView || modalManager.showView == .ridingNextView) {
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
        .onAppear {
            // 시뮬레이션: 2초 후 로딩 완료
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                ridingViewModel.isLoading = false
            }
        } // : onAppear
        .onChange(of: ridingViewModel.ridingMode) { newMode in
            // ridingMode가 변경될 때마다 로딩 시작
            ridingViewModel.isLoading = true
            
            // 2초 후 로딩 완료
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                ridingViewModel.isLoading = false
            }
        } // : onChange
    }
    
    // MARK: - Sheet Content
    @ViewBuilder
    private var sheetContent: some View {
        if ridingViewModel.isLoading {
            SheetLoadingView()
        } else {
            switch ridingViewModel.ridingMode {
            case .beforeStart:
                SheetContentView(ridingViewModel: ridingViewModel)
            case .afterStart:
                SheetGuideView(ridingViewModel: ridingViewModel)
            }
        }
    }
    
    //MARK: - View Riding
    private var backButton: some View {
        Button(action:{
            if ridingViewModel.ridingMode == .beforeStart {
                navigationManager.pop()
            } else {
                ridingViewModel.isLoading = true
                currentPosition = .loading
                ridingViewModel.ridingMode = .beforeStart
            } // : if-else
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
                    ridingViewModel.isLoading = true
                    currentPosition = .loading
                    ridingViewModel.ridingMode = .afterStart
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
    
    //MARK: - View Riding Next
    private var toiletButton: some View {
        Button(action:{
            ridingViewModel.toggleToilet()
        }){
            HStack(spacing: 2){
                Image(ridingViewModel.showToilet ? "toilet_on": "toilet_off")
                    .padding(.vertical, 8)
                    .padding(.leading, 12)
                
                Text("화장실")
                    .foregroundColor(ridingViewModel.showToilet ? .white : .gray5)
                    .font(.pretendardMedium(size: 14))
                    .padding(.trailing, 14)
            } // : HStack
            .background(ridingViewModel.showToilet ? Color.gray5 : Color.white)
            .cornerRadius(12)
        }
        .position(x: 110, y: 53)
    } // : toiletButton
    
    private var csButton: some View {
        Button(action:{
            ridingViewModel.toggleConvenienceStore()
        }){
            HStack(spacing: 2){
                Image(ridingViewModel.showConvenienceStore ? "cs_on": "cs_off")
                    .padding(.vertical, 8)
                    .padding(.leading, 12)
                
                Text("편의점")
                    .foregroundColor(ridingViewModel.showConvenienceStore ? .white : .gray5)
                    .font(.pretendardMedium(size: 14))
                    .padding(.trailing, 14)
            } // : HStack
            .background(ridingViewModel.showConvenienceStore ? Color.gray5 : Color.white)
            .cornerRadius(12)
        }
        .position(x: 208, y: 53)
    } // : csButton
}

#Preview {
    RidingView(ridingViewModel: RidingViewModel())
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
