//
//  RecommendRouteView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/19/25.
//

import SwiftUI

struct RecommendRouteView: View {
    
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @StateObject private var recommendRouteViewModel: RecommendRouteViewModel
    @StateObject private var locationManager = UserLocationManager()
    
    @State private var currentPosition: RecommendBottomSheetPosition = .medium
    
    let topSafeArea = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first?.safeAreaInsets.top ?? 0
    
    
    init(recommendRouteViewModel: RecommendRouteViewModel
    ) {
        self._recommendRouteViewModel = StateObject(wrappedValue: recommendRouteViewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                
                //네이버 맵
                RecommendNMap(recommendRouteViewModel: recommendRouteViewModel, userLocationManager: locationManager)
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
                        recommendRouteViewModel: recommendRouteViewModel),
                    screenHeight: geometry.size.height,
                    currentPosition: $currentPosition,
                    locationManager: recommendRouteViewModel.locationManager,
                    mapView: recommendRouteViewModel.mapView
                )
                
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
            // 1. UserLocationManager 인스턴스를 recommendRouteViewModel에 전달
            recommendRouteViewModel.userLocationManager = locationManager
            
            // 2. API 호출 완료 후 초기 카메라 위치 설정
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
}
