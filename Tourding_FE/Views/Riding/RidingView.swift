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
    
    let isNotNormal: Bool? // 비정상 종료일 때 true를 받음
    let isStart: Bool // 바로 라이딩 시작하면 true
    
    init(ridingViewModel: RidingViewModel, isNotNormal: Bool?, isStart: Bool) {
        self._ridingViewModel = StateObject(wrappedValue: ridingViewModel)
        self.isNotNormal = isNotNormal
        self.isStart = isStart
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
                
                // 라이딩 중일 때 터치 감지 레이어
                if ridingViewModel.flag && locationManager.isLocationTrackingEnabled {
                    Color.clear
                        .ignoresSafeArea(edges: .top)
                        .contentShape(Rectangle())
                        .gesture(
                            SimultaneousGesture(
                                TapGesture()
                                    .onEnded { _ in
                                        print("지도 탭 감지 (SwiftUI)")
                                        locationManager.handleScreenTouch()
                                    },
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        print("지도 드래그 감지 (SwiftUI)")
                                        locationManager.handleScreenTouch()
                                    }
                            )
                        )
                }
                
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
            ridingViewModel.handleOnAppear(
                locationManager: locationManager,
                isNotNormal: isNotNormal,
                isStart: isStart,
                onStartRiding: startRidingWithLoading
            )
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
            
            // 바텀시트 위치에 따른 카메라 피봇 조정
            let yPivot: CGFloat
            switch newValue {
            case .small:
                yPivot = 0.6  // 바텀시트가 작을 때 카메라 시점을 더 위로
            case .medium:
                yPivot = 0.4  // 중간 크기일 때 적당한 위치
            case .large:
                return  // large일 때는 아무것도 하지 않음
            }
            
            // flag가 false일 때는 pivot만 조정 (현재 보고 있는 화면 위치 유지)
            // flag가 true일 때는 사용자 위치로 카메라 이동
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
                // 라이딩 중일 때는 사용자 위치로 카메라 이동
                guard let userLocationManager = ridingViewModel.userLocationManager else { return }
                
                // pivot 상태 저장 (userLocationManager에 저장)
                userLocationManager.cameraPivotY = yPivot
                print("📷 바텀시트 높이 변경: 피봇을 \(yPivot)으로 설정")
                
                // 애니메이션 충돌 방지를 위해 약간의 지연 후 실행
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // moveToCurrentLocation 호출하여 현재 위치로 카메라 이동
                    userLocationManager.moveToCurrentLocation(on: mapView)
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
        }
        .position(x: 208, y: SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
    } // : csButton
    
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
