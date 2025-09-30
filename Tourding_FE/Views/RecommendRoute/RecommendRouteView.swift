//
//  RecommendRouteView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/19/25.
//

import SwiftUI
import NMapsMap

struct RecommendRouteView: View {
    
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @StateObject private var recommendRouteViewModel: RecommendRouteViewModel
    @StateObject private var locationManager = LocationManager()
    
    @State private var currentPosition: RecommendBottomSheetPosition = .medium
    
    let routeName: String
    let description: String
    
    let topSafeArea = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first?.safeAreaInsets.top ?? 0
    
    
    init(recommendRouteViewModel: RecommendRouteViewModel,
         routeName: String,
         description: String
    ) {
        self._recommendRouteViewModel = StateObject(wrappedValue: recommendRouteViewModel)
        self.routeName = routeName
        self.description = description
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                
                //네이버 맵
                RecommendNMap(
                    recommendRouteViewModel: recommendRouteViewModel,
                    userLocationManager: locationManager)
                    .ignoresSafeArea(edges: .top)
                
                if currentPosition == .large {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3), value: currentPosition)
                }
                
                backButton
                
                // 바텀시트
                RecommendBottomSheet(
                    content: SheetRecommendView(
                        recommendRouteViewModel: recommendRouteViewModel,
                        currentPosition: currentPosition),
                    screenHeight: geometry.size.height,
                    currentPosition: $currentPosition,
                    locationManager: recommendRouteViewModel.locationManager,
                    mapView: recommendRouteViewModel.mapView
                )
                
                recommendButtons
                
            } // : ZStack
        } // : GeometryReader
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .onChange(of: navigationManager.path) { newValue in
            // newValue가 변경될 때마다 currentPosition을 .medium으로 설정
            if newValue.isEmpty {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPosition = .medium
                }
            }
            
        } // : onChange
        .onAppear{
            // 1. LocationManager 인스턴스를 recommendRouteViewModel에 전달
            recommendRouteViewModel.userLocationManager = locationManager
            
            // 2. API 호출 후 초기 카메라 위치 설정
            Task { [weak recommendRouteViewModel] in
                do {
                    
                    try Task.checkCancellation()
                    await recommendRouteViewModel?.getRoutesTotalAPI()
                    
                    try Task.checkCancellation()
                    await recommendRouteViewModel?.getRouteLocationAPI()
                    
                    try Task.checkCancellation()
                    await recommendRouteViewModel?.getRoutePathAPI()
                    
                    try Task.checkCancellation()
                    await MainActor.run {
                        guard let recommendRouteViewModel = recommendRouteViewModel,
                              let firstLocation = recommendRouteViewModel.routeLocation.first,
                              let lat = Double(firstLocation.lat),
                              let lon = Double(firstLocation.lon),
                              let mapView = recommendRouteViewModel.mapView else {
                            print("❌ 초기 카메라 위치 설정 실패: mapView 또는 경로 데이터가 없습니다")
                            return
                        }
                        
                        // 출발지로 카메라 위치 설정
                        let coordinate = NMGLatLng(lat: lat, lng: lon)
                        recommendRouteViewModel.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
                    }
                } catch is CancellationError {
                    print("🚫 RidingView 초기화 Task 취소됨")
                } catch {
                    print("❌ RidingView 초기화 에러: \(error)")
                }
            } // : Task
        }
        .onDisappear {
            // 뷰가 사라질 때 메모리 정리
            recommendRouteViewModel.cleanup()
        } // : onDisappear
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
        .position(x: 36, y: SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
    } // : backButton
    
    private var recommendButtons: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action:{
                navigationManager.push(.RidingView())
            }){
                Text("코스 편집")
                    .foregroundColor(.gray5)
                    .font(.pretendardSemiBold(size: 16))
                    .frame(minHeight: 22)
            } // : Button
            .frame(width: 175, height: 54)
            .background(.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray2, lineWidth: 1)
            )
            
            Button(action:{
                navigationManager.push(.RidingView(isNotNomal: false, isStart: true))
            }){
                Text("라이딩 시작")
                    .foregroundColor(.white)
                    .font(.pretendardSemiBold(size: 16))
                    .frame(minHeight: 22)
                    
            } // : Button
            .frame(width: 175, height: 54)
            .background(Color.gray5)
            .cornerRadius(10)
            
        } // : HStack
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .padding(.bottom, 18+34)
        .background(.white)
    }
}
