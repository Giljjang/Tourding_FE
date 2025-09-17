//
//  RidingView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import SwiftUI
import NMapsMap

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
    
    let isNotNomal: Bool? // 비정상 종료일 때 true를 받음
    
    init(ridingViewModel: RidingViewModel, isNotNomal: Bool?) {
        self._ridingViewModel = StateObject(wrappedValue: ridingViewModel)
        self.isNotNomal = isNotNomal
    }
    
    //라이딩 중 비정상 종료 감지
    @AppStorage("wasLastRunNormal") private var wasLastRunNormal: Bool = true
    
    let topSafeArea = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first?.safeAreaInsets.top ?? 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 배경 컨텐츠
                NMapView(ridingViewModel: ridingViewModel, userLocationManager: locationManager)
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
                        .background(.white)
                    
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
                }// if 로딩 상태(일반)
                
                if ridingViewModel.isStartingRiding {
                    Color.white.opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 4){
                        Spacer()
                        
                        GIFView(name: "searching-route-속도-2")
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
        .onAppear{
            // UserLocationManager 인스턴스를 RidingViewModel에 전달
            ridingViewModel.userLocationManager = locationManager
            
            // 위치 권한 확인 및 요청
            checkAndRequestLocationPermission()
            
            if let isNotNomal = isNotNomal { // 비정상 종료일 때 바로 라이딩 중으로 이동
                ridingViewModel.flag = isNotNomal
                
                startRidingWithLoading()
            }
            
            // flag가 true일 때 카메라를 사용자 위치로 이동하고 위치 추적 시작
            if ridingViewModel.flag {
                print("🎯 onAppear - 라이딩 중, startRidingProcess 로직 실행")
                // startRidingProcess와 동일한 로직 실행
                if let coordinate = locationManager.getCurrentLocationAsNMGLatLng(),
                   let mapView = ridingViewModel.mapView {
                    ridingViewModel.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
                    print("🎯 onAppear - 카메라를 사용자 위치로 이동: \(coordinate.lat), \(coordinate.lng)")
                } else {
                    print("❌ onAppear - 사용자 위치 또는 mapView를 가져올 수 없어 카메라 이동 실패")
                }
                
                // userLocationManager 사용 (startRidingProcess와 동일)
                if let userLocationManager = ridingViewModel.userLocationManager {
                    // 새로운 콜백 생성
                    let newCallback: (NMGLatLng) -> Void = { newLocation in
                        if let mapViewController = ridingViewModel.mapViewController {
                            let clLocation = CLLocation(latitude: newLocation.lat, longitude: newLocation.lng)
                            mapViewController.updateUserLocation(clLocation)
                        }
                        ridingViewModel.updateUserLocationAndCheckMarkers(newLocation)
                    }
                    
                    // 콜백 설정
                    userLocationManager.onLocationUpdate = newCallback
                    userLocationManager.startLocationUpdates()
                    print("📍 onAppear - 사용자 위치 추적 시작 - 마커 표시")
                } else {
                    print("❌ onAppear - userLocationManager가 nil")
                }
            }
            
            Task { [weak ridingViewModel] in
                do {
                    try Task.checkCancellation()
                    await ridingViewModel?.getRouteLocationAPI()
                    
                    try Task.checkCancellation()
                    await ridingViewModel?.getRoutePathAPI()
                    
                    // API 호출 완료 후 초기 카메라 위치 설정 (flag가 false일 때만)
                    try Task.checkCancellation()
                    await MainActor.run {
                        guard let ridingViewModel = ridingViewModel,
                              let firstLocation = ridingViewModel.routeLocation.first,
                              let lat = Double(firstLocation.lat),
                              let lon = Double(firstLocation.lon),
                              let mapView = ridingViewModel.mapView else {
                            print("❌ 초기 카메라 위치 설정 실패: mapView 또는 경로 데이터가 없습니다")
                            return
                        }
                        
                        // flag가 false일 때만 경로 첫 번째 좌표로 카메라 설정
                        if !ridingViewModel.flag {
                            let coordinate = NMGLatLng(lat: lat, lng: lon)
                            ridingViewModel.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
                            print("초기 카메라 위치를 경로 첫 번째 좌표로 설정: \(lat), \(lon)")
                        }
                    }
                } catch is CancellationError {
                    print("🚫 RidingView 초기화 Task 취소됨")
                } catch {
                    print("❌ RidingView 초기화 에러: \(error)")
                }
            } // : Task
        }// : onAppear
        .onChange(of: ridingViewModel.flag) { newValue in
            // flag가 변경될 때마다 currentPosition을 .medium으로 설정
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPosition = .medium
            }
            
        } // : onChange
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 앱이 포그라운드로 돌아왔을 때
            print("🔄 앱이 포그라운드로 돌아옴 - 지도 상태 확인")
            checkAndRefreshMapData()
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
            } else { //라이딩 시작 후 뒤로가기
                
                wasLastRunNormal = true
                
                // 위치 추적 중지
                locationManager.stopLocationUpdates()
                
                if let firstLocation = ridingViewModel.routeLocation.first,
                   let lat = Double(firstLocation.lat),
                   let lon = Double(firstLocation.lon),
                   let mapView = ridingViewModel.mapView {
                    
                    let coordinate = NMGLatLng(lat: lat, lng: lon)
                    ridingViewModel.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
                    print("초기 카메라 위치를 경로 첫 번째 좌표로 설정: \(lat), \(lon)")
                    
                } else {
                    print("❌ 초기 카메라 위치 설정 실패: mapView 또는 경로 데이터가 없습니다")
                }
                
                Task { [weak ridingViewModel] in
                    do {
                        try Task.checkCancellation()
                        await ridingViewModel?.getRouteLocationAPI()
                        
                        try Task.checkCancellation()
                        await MainActor.run {
                            guard let ridingViewModel = ridingViewModel else { return }
                            
                            //화장실 마커 전부 제거
                            ridingViewModel.toiletMarkerCoordinates.removeAll()
                            ridingViewModel.toiletMarkerIcons.removeAll()
                            
                            //편의점 마커 전부 제거
                            ridingViewModel.csMarkerCoordinates.removeAll()
                            ridingViewModel.csMarkerIcons.removeAll()
                            
                            ridingViewModel.showConvenienceStore = false
                            ridingViewModel.showToilet = false
                            
                            // 라이딩 종료 시 원본 데이터로 복원
                            ridingViewModel.restoreOriginalData()
                        }
                        ridingViewModel?.flag = false
                    } catch is CancellationError {
                        print("🚫 라이딩 종료 Task 취소됨")
                    } catch {
                        print("❌ 라이딩 종료 에러: \(error)")
                    }
                }
            } //: if-else
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
        .position(x: 110, y:SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
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
        .position(x: 208, y: SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
    } // : csButton
    
    //MARK: - function
    
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
    
    // 앱이 포그라운드로 돌아왔을 때 지도 데이터 확인 및 새로고침
    private func checkAndRefreshMapData() {
        // 라이딩 중이 아닐 때만 데이터 새로고침 (라이딩 중에는 중단하지 않음)
        guard !ridingViewModel.flag else {
            print("🚫 라이딩 중이므로 데이터 새로고침 건너뜀")
            return
        }
        
        // 경로 데이터가 비어있거나 지도가 제대로 초기화되지 않은 경우
        if ridingViewModel.routeLocation.isEmpty || ridingViewModel.pathCoordinates.isEmpty {
            print("🔄 경로 데이터가 비어있음 - API 재호출 시작")
            refreshRouteData()
        } else {
//            print("✅ 경로 데이터가 정상적으로 로드됨")
            // 지도 마커와 경로선 다시 그리기
            ridingViewModel.refreshMapDisplay()
        }
    }
    
    // 경로 데이터 새로고침
    private func refreshRouteData() {
        Task { [weak ridingViewModel] in
            do {
                try Task.checkCancellation()
                await ridingViewModel?.getRouteLocationAPI()
                
                try Task.checkCancellation()
                await ridingViewModel?.getRoutePathAPI()
                
                // API 호출 완료 후 초기 카메라 위치 설정
                try Task.checkCancellation()
                await MainActor.run {
                    guard let ridingViewModel = ridingViewModel,
                          let firstLocation = ridingViewModel.routeLocation.first,
                          let lat = Double(firstLocation.lat),
                          let lon = Double(firstLocation.lon),
                          let mapView = ridingViewModel.mapView else {
                        print("❌ 새로고침 후 초기 카메라 위치 설정 실패")
                        return
                    }
                    
                    let coordinate = NMGLatLng(lat: lat, lng: lon)
                    ridingViewModel.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
                    print("✅ 새로고침 후 초기 카메라 위치 설정 완료: \(lat), \(lon)")
                }
            } catch is CancellationError {
                print("🚫 경로 데이터 새로고침 Task 취소됨")
            } catch {
                print("❌ 경로 데이터 새로고침 에러: \(error)")
            }
        }
    }
    
    // 라이딩 시작하기 버튼 클릭 시 3초 로딩과 함께 시작
    func startRidingWithLoading() {
        
        wasLastRunNormal = false // 비정상 종료 감지 on
        
        // 라이딩 시작 로딩 상태 활성화
        ridingViewModel.isStartingRiding = true
        
        self.startRidingAPIProcess()
        
        // 3초 후 라이딩 시작
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.ridingViewModel.isStartingRiding = false
        }
    }
    
    // 라이딩 중 API 호출 로직
    func startRidingAPIProcess() {
        // flag 설정
        ridingViewModel.flag = true
        
        // 카메라를 사용자 위치로 이동
        if let coordinate = locationManager.getCurrentLocationAsNMGLatLng(),
           let mapView = ridingViewModel.mapView {
            ridingViewModel.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
            print("🎯 startRidingProcess - 카메라를 사용자 위치로 이동: \(coordinate.lat), \(coordinate.lng)")
        } else {
            print("❌ startRidingProcess - 사용자 위치 또는 mapView를 가져올 수 없어 카메라 이동 실패")
        }
        
        // locationManager의 콜백만 업데이트 (이미 startLocationUpdates가 호출된 상태)
        let newCallback: (NMGLatLng) -> Void = { newLocation in
            if let mapViewController = ridingViewModel.mapViewController {
                let clLocation = CLLocation(latitude: newLocation.lat, longitude: newLocation.lng)
                mapViewController.updateUserLocation(clLocation)
            }
            ridingViewModel.updateUserLocationAndCheckMarkers(newLocation)
        }
        
        // 기존 locationManager의 콜백 업데이트
        locationManager.onLocationUpdate = newCallback
        print("📍 startRidingProcess - locationManager 콜백 업데이트 완료")
        
        // 라이딩 가이드 API 호출
        Task { [weak ridingViewModel] in
            do {
                try Task.checkCancellation()
                await ridingViewModel?.getRouteGuideAPI()
            } catch is CancellationError {
                print("🚫 라이딩 가이드 API Task 취소됨")
            } catch {
                print("❌ 라이딩 가이드 API 에러: \(error)")
            }
        }
    }

}
