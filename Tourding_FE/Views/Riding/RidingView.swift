//
//  RidingView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import SwiftUI
import NMapsMap
import SDWebImageSwiftUI


struct RidingView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    // @ObservedObject가 아닌 이유 -> @StateObject 사용한 이유
    // 부모 뷰가 다시 렌더링되지 않음: @ObservedObject는 부모 뷰가 다시 렌더링될 때만 업데이트됨.
    //객체 참조 문제: 모달이 열리고 닫힐 때 부모 뷰가 다시 렌더링되지 않아서 @ObservedObject가 업데이트를 감지하지 못합
    // 즉, 부모 뷰의 렌더링과 관계없이 @Published 속성 변경을 즉시 감지해야함
    @StateObject private var ridingViewModel: RidingViewModel
    @StateObject private var locationManager = LocationManager()
    
    @State private var currentPosition: BottomSheetPosition = .medium
    @State private var forceUpdate: Bool = false
    @State private var didRunInitialSetup = false
    
    let isNotNormal: Bool? // 비정상 종료일 때 true를 받음
    let isStart: Bool // 바로 라이딩 시작하면 true
    let routeSource: RidingRouteSource
    
    init(
        ridingViewModel: RidingViewModel,
        isNotNormal: Bool?,
        isStart: Bool,
        routeSource: RidingRouteSource
    ) {
        self._ridingViewModel = StateObject(wrappedValue: ridingViewModel)
        self.isNotNormal = isNotNormal
        self.isStart = isStart
        self.routeSource = routeSource
    }
    
    //라이딩 중 비정상 종료 감지
    @AppStorage("wasLastRunNormal") private var wasLastRunNormal: Bool = true
    
    let topSafeArea = {
        let safeArea = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
        
        // SafeArea가 0이면 최소값(44pt) 사용
        return safeArea > 0 ? safeArea : 44
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 배경 컨텐츠
                NMapView(ridingViewModel: ridingViewModel, userLocationManager: locationManager)
                    .ignoresSafeArea(edges: .top)
                
                // 지도 터치 감지는 MapViewController가 NMFMapViewCameraDelegate로 한다.
                // 예전에는 여기에 투명 레이어를 얹었는데, ZStack에서 NMapView의 형제라
                // 터치를 가로채 첫 드래그에 지도가 밀리지 않았다.

                if currentPosition == .large {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3), value: currentPosition)
                }
                
                backButton
                
                if ridingViewModel.flag { // 라이딩 중일 때
                    
                    toiletButton
                    
                    csButton
                    
                    AICourseEditButton
                    
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
                        locationManager: locationManager,
                        mapView: ridingViewModel.mapView
                    )
                    
                    ridingStartButton
                        .padding(.bottom, 30)
                        .background(.white)
                    
                } else {
                    CustomBottomSheet(
                        content: SheetGuideView(
                            ridingViewModel: ridingViewModel,
                            currentPosition: currentPosition),
                        screenHeight: geometry.size.height,
                        currentPosition: $currentPosition,
                        isRiding: true,
                        locationManager: locationManager,
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
                }// if 로딩 상태(일반)
                
                if ridingViewModel.isStartingRiding {
                    Color.white.opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 4){
                        Spacer()
                        
                        AnimatedImage(name: "searching-route-속도-2.gif")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                        
                        Text("길 안내를 준비하고 있어요\n잠시만 기다려 주세요")
                            .foregroundColor(.gray5)
                            .font(.pretendardSemiBold(size: 20))
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                }// if 로딩 상태(라이딩 시작하기)
                
            } // : ZStack
        } // : GeometryReader
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .onAppear {
            ridingViewModel.configureLocationManager(locationManager)
            checkAndRequestLocationPermission()

            if !didRunInitialSetup {
                didRunInitialSetup = true
                ridingViewModel.handleInitialEntry(
                    locationManager: locationManager,
                    isNotNormal: isNotNormal,
                    isStart: isStart,
                    routeSource: routeSource,
                    onStartRiding: startRidingWithLoading
                )
            } else {
                ridingViewModel.handleReturnFromChild(
                    locationManager: locationManager,
                    routeSource: routeSource
                )
            }
        }
        .onChange(of: ridingViewModel.flag) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPosition = .medium
            }

            if newValue {
                ridingViewModel.activateRidingLocationTracking(locationManager: locationManager)
            }
        }
        .onChange(of: ridingViewModel.routeLocation) { _ in
            ridingViewModel.handleRouteLocationChangedInEditMode()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("🔄 앱이 포그라운드로 돌아옴 - 지도 상태 확인")
            ridingViewModel.handleForegroundRefresh()
        }
        .onChange(of: currentPosition) { oldValue, newValue in
            guard let mapView = ridingViewModel.mapView else { return }
            
            // large로 갈 때나 large에서 medium으로 갈 때만 카메라 시점 변경하지 않음
            if newValue == .large {
                return
            }
            
            // large에서 medium으로 갈 때도 카메라 시점 변경하지 않음
            if oldValue == .large && newValue == .medium {
                return
            }
            
            // 바텀시트 위치에 따른 카메라 피봇. 매핑은 LocationManager가 갖는다.
            guard let yPivot = LocationManager.cameraPivot(for: newValue) else {
                return  // large일 때는 아무것도 하지 않음
            }

            // 편집·라이딩 **양쪽 모두** 피봇을 저장한다.
            // 편집에서 저장하지 않으면 "내 위치로 이동" 버튼이 시트 높이를 반영하지 못하고,
            // 라이딩을 했다 돌아온 경우엔 직전 라이딩의 값이 그대로 남는다.
            ridingViewModel.userLocationManager?.syncCameraPivot(for: newValue)

            // 편집 모드는 pivot만 조정 (보고 있는 화면 위치 유지).
            // 라이딩 중에는 **추적 중일 때만** 사용자 위치로 따라간다 — 판정은 LocationManager에 있다.
            if !ridingViewModel.flag {
                // 현재 카메라가 보고 있는 중심 좌표를 기준으로 pivot만 조정
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let currentCameraPosition = mapView.cameraPosition
                    let cameraUpdate = NMFCameraUpdate(scrollTo: currentCameraPosition.target)
                    cameraUpdate.pivot = CGPoint(x: 0.5, y: yPivot)
                    cameraUpdate.animation = .easeOut
                    cameraUpdate.animationDuration = 0.3
                    mapView.moveCamera(cameraUpdate)
                }
            } else {
                guard let userLocationManager = ridingViewModel.userLocationManager else { return }
                
                // 애니메이션 충돌 방지를 위해 약간의 지연 후 실행
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 추적 중이면 사용자 위치로, 아니면 보던 위치를 유지한 채 피봇만 조정
                    userLocationManager.updateCameraPivot(on: mapView, yPivot: yPivot)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // 앱이 백그라운드로 갈 때
            print("⏸️ 앱이 백그라운드로 이동")
        }
    }
    
    //MARK: - View
    private var backButton: some View {
        Button(action:{
            if !ridingViewModel.flag {
                navigationManager.pop()
            } else {
                wasLastRunNormal = true
                Task {
                    await ridingViewModel.endRiding(isStart: isStart, locationManager: locationManager)
                }
            }
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
    
    private var ridingStartButton: some View {
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
                    print("🚀 === 라이딩 시작 ===")
                    startRidingWithLoading()
                } // : onActive
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
        .shadow(color: .white.opacity(0.8), radius: 8, x: 0, y: -14)
    } // : ridingStartButton
    
    //MARK: - Riding 중
    private var toiletButton: some View {
        Button(action:{
            let position = locationManager.getCurrentLocationString()
            //            print("position: \(position)")
            ridingViewModel.toggleToilet(location: position)
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
            .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 6)
        }
        .position(x: 110, y:SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
    } // : toiletButton
    
    private var csButton: some View {
        Button(action:{
            let position = locationManager.getCurrentLocationString()
            //            print("position: \(position)")
            
            ridingViewModel.toggleConvenienceStore(location: position)
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
            .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 6)
        }
        .position(x: 208, y: SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
    } // : csButton
    
    private var AICourseEditButton: some View {
        Button(action:{
            // AI 코스수정 기능 추가 예정
        }){
            HStack(spacing: 2){
                Image("ai_course_btn")
                    .padding(.vertical, 9)
                    .padding(.leading, 12)
                
                Text("AI 코스수정")
                    .foregroundColor(.gray5)
                    .font(.pretendardMedium(size: 14))
                    .padding(.trailing, 14)
            } // : HStack
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Self.aiBorderGradient, lineWidth: 1)
            )
        }
        .position(x: 316, y: SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
    } // : AICourseEditButton

    /// AI 코스수정 버튼 테두리 — Figma GRADIENT_LINEAR (2774:17889)
    ///
    /// startPoint·endPoint가 0...1을 벗어나는 건 의도된 값이다.
    /// Figma의 gradientTransform을 역변환한 결과이고, 그래서 버튼에 실제로 보이는 건
    /// 그라데이션의 가운데 구간(약 t=0.2~0.9)이다. 0,0 → 1,1로 바꾸면 색이 달라진다.
    private static let aiBorderGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: "#00E1FF"), location: 0),
            .init(color: Color(hex: "#CEB4FF"), location: 1)
        ],
        startPoint: UnitPoint(x: 0.074, y: -0.925),
        endPoint:   UnitPoint(x: 0.829, y: 1.625)
    )
    
    //MARK: - Lifecycle helpers

    private func startRidingWithLoading() {
        ridingViewModel.startRidingWithLoading(
            isNotNormal: isNotNormal,
            locationManager: locationManager,
            onMarkAbnormalExit: { wasLastRunNormal = false }
        )
    }

    //위치 권한 체크
    private func checkAndRequestLocationPermission() {
        let authStatus = locationManager.checkLocationAuthorizationStatus()
        
        switch authStatus {
        case .denied, .restricted:
            // 권한이 거부된 경우 사용자에게 안내
            print("위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.")
            modalManager.showModal(
                title: "위치 권한이 거부되었습니다.",
                subText: "설정에서 권한을 허용해주세요.",
                activeText: "허용하기",
                showView: .ridingView,
                onCancel: {
                    print("취소됨")
                },
                onActive: {
                    // 설정 앱으로 이동
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            )
            
        case .notDetermined:
            // 권한을 아직 결정하지 않은 경우 권한 요청
            locationManager.requestLocationPermission()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // 권한이 허용된 경우 현재 위치 가져오기
            locationManager.getCurrentLocation()
            
            // 위치 업데이트 콜백은 라이딩 시작할 때 설정됨
            
        @unknown default:
            break
        }
    }
}
