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
                }// if 로딩 상태
                
            } // : ZStack
        } // : GeometryReader
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .onAppear{
            // 위치 권한 확인 및 요청
            checkAndRequestLocationPermission()
            
            Task{
                await ridingViewModel.getRouteLocationAPI()
                await ridingViewModel.getRoutePathAPI()
                
                // API 호출 완료 후 초기 카메라 위치 설정
                await MainActor.run {
                    if let firstLocation = ridingViewModel.routeLocation.first,
                       let lat = Double(firstLocation.lat),
                       let lon = Double(firstLocation.lon) {
                        
                        let coordinate = NMGLatLng(lat: lat, lng: lon)
                        ridingViewModel.locationManager?.setInitialCameraPosition(to: coordinate, on: ridingViewModel.mapView!)
                        print("초기 카메라 위치를 경로 첫 번째 좌표로 설정: \(lat), \(lon)")
                        
                    }
                }
            } // : Task
        }// : onAppear
        .onChange(of: ridingViewModel.flag) { newValue in
            // flag가 변경될 때마다 currentPosition을 .medium으로 설정
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPosition = .medium
            }
        } // : onChange
    }
    
    //MARK: - View
    private var backButton: some View {
        Button(action:{
            if !ridingViewModel.flag {
                navigationManager.pop()
            } else { //라이딩 시작 후 뒤로가기
                // 위치 추적 중지
                locationManager.stopLocationUpdates()
                
                if let firstLocation = ridingViewModel.routeLocation.first,
                   let lat = Double(firstLocation.lat),
                   let lon = Double(firstLocation.lon) {
                    
                    let coordinate = NMGLatLng(lat: lat, lng: lon)
                    ridingViewModel.locationManager?.setInitialCameraPosition(to: coordinate, on: ridingViewModel.mapView!)
                    print("초기 카메라 위치를 경로 첫 번째 좌표로 설정: \(lat), \(lon)")
                    
                }
                
                Task{
                    await ridingViewModel.getRouteLocationAPI()
                    
                    //화장실 마커 전부 제거
                    ridingViewModel.toiletMarkerCoordinates.removeAll()
                    ridingViewModel.toiletMarkerIcons.removeAll()
                    
                    //편의점 마커 전부 제거
                    ridingViewModel.csMarkerCoordinates.removeAll()
                    ridingViewModel.csMarkerIcons.removeAll()
                    
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
        .position(x: 36, y: 73)
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
                    
                    // 위치 추적 시작
                    locationManager.startLocationUpdates()
                    
                    Task{
                        // 기존 마커 제거
                        ridingViewModel.markerCoordinates.removeAll()
                        ridingViewModel.markerIcons.removeAll()
                        
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
        .position(x: 110, y: 73)
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
        .position(x: 208, y: 73)
    } // : csButton
    
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
            
            if ridingViewModel.flag {
                // 위치 업데이트 콜백 설정
                locationManager.onLocationUpdate = { newLocation in
                    ridingViewModel.updateUserLocationAndCheckMarkers(newLocation)
                }
            }
            
        @unknown default:
            break
        }
    }
}

#Preview {
    RidingView(ridingViewModel: RidingViewModel(
        routeRepository: RouteRepository(),
        kakaoRepository: KakaoRepository()))
    .environmentObject(NavigationManager())
    .environmentObject(ModalManager())
}
