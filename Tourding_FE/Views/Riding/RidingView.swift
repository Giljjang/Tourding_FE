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
    @EnvironmentObject var routeSharedManager: RouteSharedManager
    
    // @ObservedObject가 아닌 이유 -> @StateObject 사용한 이유
    // 부모 뷰가 다시 렌더링되지 않음: @ObservedObject는 부모 뷰가 다시 렌더링될 때만 업데이트됨.
    //객체 참조 문제: 모달이 열리고 닫힐 때 부모 뷰가 다시 렌더링되지 않아서 @ObservedObject가 업데이트를 감지하지 못합
    // 즉, 부모 뷰의 렌더링과 관계없이 @Published 속성 변경을 즉시 감지해야함
    @StateObject private var ridingViewModel: RidingViewModel
    @StateObject private var locationManager = UserLocationManager()
    
    @State private var currentPosition: BottomSheetPosition = .medium
    @State private var forceUpdate: Bool = false
    
    init(ridingViewModel: RidingViewModel) {
        self._ridingViewModel = StateObject(wrappedValue: ridingViewModel)
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
                
                if ridingViewModel.flag {
                    
                    toiletButton
                    
                    csButton
                    
                } // : if
                
                // 바텀 시트
                if !ridingViewModel.flag {
                    CustomBottomSheet(
                        content: SheetContentView(
                            ridingViewModel: ridingViewModel,
                            currentPosition: currentPosition),
                        screenHeight: geometry.size.height,
                        currentPosition: $currentPosition,
                        isRiding: false,
                        locationManager: ridingViewModel.locationManager,
                        mapView: ridingViewModel.mapView
                    )
                    
                    ridingStartButtom
                        .padding(.bottom, 30)
                    
                } else {
                    CustomBottomSheet(
                        content: SheetGuideView(
                            ridingViewModel: ridingViewModel,
                            currentPosition: currentPosition),
                        screenHeight: geometry.size.height,
                        currentPosition: $currentPosition,
                        isRiding: true,
                        locationManager: ridingViewModel.locationManager,
                        mapView: ridingViewModel.mapView
                    )
                } // : if-else
                
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
                } else if modalManager.isPresented && modalManager.showView == .ridingNextView {
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
                } // : if - else if
                
                if ridingViewModel.isLoading {
                    Color.white.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack{
                        Spacer()
                        
                        DotsLoadingView()
                        
                        Spacer()
                    }
                }// if 로딩 상태
                
            } // : ZStack
        } // : GeometryReader
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .onAppear{
            // 위치 권한 요청 및 현재 위치 가져오기
            locationManager.getCurrentLocation()
            
            Task{
                await ridingViewModel.getRouteLocationAPI()
                await ridingViewModel.getRoutePathAPI()
            }
        }// : onAppear
    }
    
    //MARK: - View
    private var backButton: some View {
        Button(action:{
            if !ridingViewModel.flag {
                navigationManager.pop()
            } else { //라이딩 시작 후 뒤로가기
                Task{
                    await ridingViewModel.getRouteLocationAPI()
                    
                    //화장실 마커 전부 제거
                    ridingViewModel.additionalMarkerIcons.removeAll()
                    ridingViewModel.additionalMarkerCoordinates.removeAll()
                    
                    ridingViewModel.showConvenienceStore = false
                    ridingViewModel.showToilet = false
                }
                ridingViewModel.flag = false
            } //: if-else
        }){
            Image("riding_back")
                .padding(.vertical, 8)
                .padding(.leading, 6)
                .padding(.trailing,10)
                .background(Color.white)
                .cornerRadius(30)
        }
        .position(x: 36, y: 93)
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
                    ridingViewModel.flag = true
                    
                    Task{
                        await ridingViewModel.getRouteGuideAPI()
                    }
                }
            )
        }){
            
            HStack(spacing: 0){
                
                Spacer()
                
                Text("라이딩 시작하기")
                    .foregroundColor(.white)
                    .font(.pretendardSemiBold(size: 16))
                    .frame(height: 22)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .background(Color.gray5)
            .cornerRadius(10)
            .padding(.horizontal, 16)
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
    
    //MARK: - Riding 중
    private var toiletButton: some View {
        Button(action:{
            let position = locationManager.getCurrentLocationString()
//            print("position: \(position)")
            ridingViewModel.toggleToilet(locaion: position)
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
        .position(x: 110, y: 93)
    } // : toiletButton
    
    private var csButton: some View {
        Button(action:{
            let position = locationManager.getCurrentLocationString()
//            print("position: \(position)")
            
            ridingViewModel.toggleConvenienceStore(locaion: position)
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
        .position(x: 208, y: 93)
    } // : csButton
}

#Preview {
    RidingView(ridingViewModel: RidingViewModel(routeRepository: RouteRepository(),
                        kakaoRepository: KakaoRepository()))
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
