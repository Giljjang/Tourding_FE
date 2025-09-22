//
//  RidingViewModel+View.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/22/25.
//

import NMapsMap
import SwiftUI
import CoreLocation

extension RidingViewModel {
    // MARK: - 앱 생명주기 관리
    func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidBecomeActive()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillResignActive()
        }
    }
    
    @MainActor private func handleAppDidBecomeActive() {
        print("🔄 앱이 포그라운드로 돌아옴 - 지도 상태 확인")
        checkAndRefreshMapData()
    }
    
    private func handleAppWillResignActive() {
        print("⏸️ 앱이 백그라운드로 이동")
    }
    
    // MARK: - 위치 권한 관리
    @MainActor func checkAndRequestLocationPermission(locationManager: LocationManager, modalManager: ModalManager) {
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
            
        @unknown default:
            break
        }
    }
    
    // MARK: - 지도 데이터 새로고침
    @MainActor private func checkAndRefreshMapData() {
        // 라이딩 중이 아닐 때만 데이터 새로고침 (라이딩 중에는 중단하지 않음)
        guard !flag else {
            print("🚫 라이딩 중이므로 데이터 새로고침 건너뜀")
            return
        }
        
        // 경로 데이터가 비어있거나 지도가 제대로 초기화되지 않은 경우
        if routeLocation.isEmpty || pathCoordinates.isEmpty {
            print("🔄 경로 데이터가 비어있음 - API 재호출 시작")
            refreshRouteData()
        } else {
            // 지도 마커와 경로선 다시 그리기
            refreshMapDisplay()
        }
    }
    
    // 경로 데이터 새로고침
    private func refreshRouteData() {
        Task { [weak self] in
            do {
                try Task.checkCancellation()
                await self?.getRouteLocationAPI()
                
                try Task.checkCancellation()
                await self?.getRoutePathAPI()
                
                // API 호출 완료 후 초기 카메라 위치 설정
                try Task.checkCancellation()
                await MainActor.run {
                    guard let self = self,
                          let firstLocation = self.routeLocation.first,
                          let lat = Double(firstLocation.lat),
                          let lon = Double(firstLocation.lon),
                          let mapView = self.mapView else {
                        print("❌ 새로고침 후 초기 카메라 위치 설정 실패")
                        return
                    }
                    
                    let coordinate = NMGLatLng(lat: lat, lng: lon)
                    self.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
                    print("✅ 새로고침 후 초기 카메라 위치 설정 완료: \(lat), \(lon)")
                }
            } catch is CancellationError {
                print("🚫 경로 데이터 새로고침 Task 취소됨")
            } catch {
                print("❌ 경로 데이터 새로고침 에러: \(error)")
            }
        }
    }
    
    // MARK: - 라이딩 시작/종료 관리
    @MainActor func startRidingWithLoading(locationManager: LocationManager, isNotNomal: Bool?) {
        wasLastRunNormal = false // 비정상 종료 감지 on
        
        // 라이딩 시작 로딩 상태 활성화
        isStartingRiding = true
        
        startRidingAPIProcess(locationManager: locationManager, isNotNomal: isNotNomal)
        
        // 3초 후 라이딩 시작
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isStartingRiding = false
        }
    }
    
    // 라이딩 중 API 호출 로직
    @MainActor func startRidingAPIProcess(locationManager: LocationManager, isNotNomal: Bool?) {
        // flag 설정
        flag = true
        
        print("🚀 라이딩 API 프로세스 시작 - isNotNomal: \(isNotNomal != nil)")
        
        // 비정상 종료 시 네비게이션 모드 강제 시작
        if let mapView = mapView {
            print("🧭 네비게이션 모드 시작")
            locationManager.startNavigationMode(on: mapView)
            
            // 카메라를 사용자 위치로 이동
            if let coordinate = locationManager.getCurrentLocationAsNMGLatLng() {
                locationManager.setInitialCameraPosition(to: coordinate, on: mapView)
                print("🎯 카메라를 사용자 위치로 이동: \(coordinate.lat), \(coordinate.lng)")
            } else if let firstLocation = routeLocation.first,
                      let lat = Double(firstLocation.lat),
                      let lon = Double(firstLocation.lon) {
                let coordinate = NMGLatLng(lat: lat, lng: lon)
                locationManager.setInitialCameraPosition(to: coordinate, on: mapView)
                print("🎯 카메라를 경로 첫 번째 좌표로 이동: \(lat), \(lon)")
            } else {
                print("⚠️ 사용자 위치와 경로 데이터 모두 없음 - 기본 카메라 위치 유지")
            }
        } else {
            print("❌ mapView가 nil - 네비게이션 모드 시작 불가")
        }
        
        // 위치 추적 콜백 설정 (비정상 종료 시 강화)
        setupLocationTrackingCallback(locationManager: locationManager)
        
        // 라이딩 가이드 API 호출
        Task { [weak self] in
            do {
                try Task.checkCancellation()
                await self?.getRouteGuideAPI(isNotNomal: isNotNomal)
                
                // 가이드 데이터 로드 완료 후 추가 안정화
                await MainActor.run {
                    if let self = self {
                        print("✅ 가이드 데이터 로드 완료 - 네비게이션 준비됨")
                        print("  - 가이드 개수: \(self.guideList.count)")
                        print("  - 마커 개수: \(self.markerCoordinates.count)")
                        print("  - 경로선 개수: \(self.pathCoordinates.count)")
                    }
                }
            } catch is CancellationError {
                print("🚫 라이딩 가이드 API Task 취소됨")
            } catch {
                print("❌ 라이딩 가이드 API 에러: \(error)")
            }
        }
    }
    
    // 라이딩 종료 처리
    @MainActor func endRiding(locationManager: LocationManager) {
        wasLastRunNormal = true
        
        // 위치 추적 중지 및 네비게이션 모드 종료
        locationManager.stopLocationUpdates()
        locationManager.stopNavigationMode()
        
        if let firstLocation = routeLocation.first,
           let lat = Double(firstLocation.lat),
           let lon = Double(firstLocation.lon),
           let mapView = mapView {
            
            let coordinate = NMGLatLng(lat: lat, lng: lon)
            locationManager.setInitialCameraPosition(to: coordinate, on: mapView)
            print("초기 카메라 위치를 경로 첫 번째 좌표로 설정: \(lat), \(lon)")
            
        } else {
            print("❌ 초기 카메라 위치 설정 실패: mapView 또는 경로 데이터가 없습니다")
        }
        
        Task { [weak self] in
            do {
                try Task.checkCancellation()
                await self?.getRouteLocationAPI()
                
                try Task.checkCancellation()
                await MainActor.run {
                    guard let self = self else { return }
                    
                    //화장실 마커 전부 제거
                    self.toiletMarkerCoordinates.removeAll()
                    self.toiletMarkerIcons.removeAll()
                    
                    //편의점 마커 전부 제거
                    self.csMarkerCoordinates.removeAll()
                    self.csMarkerIcons.removeAll()
                    
                    self.showConvenienceStore = false
                    self.showToilet = false
                    
                    // 라이딩 종료 시 원본 데이터로 복원
                    self.restoreOriginalData()
                }
                self?.flag = false
            } catch is CancellationError {
                print("🚫 라이딩 종료 Task 취소됨")
            } catch {
                print("❌ 라이딩 종료 에러: \(error)")
            }
        }
    }
    
    // MARK: - 라이딩 초기화 처리
    @MainActor func handleRidingInitialization(locationManager: LocationManager, isNotNomal: Bool?, isStart: Bool) {
        // LocationManager 인스턴스를 RidingViewModel에 전달
        userLocationManager = locationManager
        
        // 비정상 종료 시 디버깅 정보 출력
        if let isNotNomal = isNotNomal {
            print("🔍 === 비정상 종료 복구 상태 확인 ===")
            print("  - isNotNomal: \(isNotNomal)")
            print("  - userLocationManager: \(userLocationManager != nil)")
            print("  - mapView: \(mapView != nil)")
            print("  - locationManager: \(locationManager)")
            print("  - 현재 flag 상태: \(flag)")
        }
        
        if let isNotNomal = isNotNomal { // 비정상 종료일 때 바로 라이딩 중으로 이동
            flag = isNotNomal
            print("🔄 비정상 종료 감지 - 라이딩 모드로 복구")
            
            // 비정상 종료 시 위치 추적 강제 재시작
            locationManager.stopLocationUpdates()
            locationManager.startLocationUpdates()
            print("📍 비정상 종료 - 위치 추적 강제 재시작")
            
            startRidingWithLoading(locationManager: locationManager, isNotNomal: isNotNomal)
        }
        
        if isStart {
            startRidingWithLoading(locationManager: locationManager, isNotNomal: isNotNomal)
        }
        
        // flag가 true일 때 카메라를 사용자 위치로 이동하고 위치 추적 시작
        if flag {
            print("🎯 onAppear - 라이딩 중, startRidingProcess 로직 실행")
            
            // 비정상 종료 시 네비게이션 모드 강제 시작
            if let mapView = mapView {
                print("🧭 네비게이션 모드 강제 시작")
                locationManager.startNavigationMode(on: mapView)
                
                // 위치가 있으면 사용자 위치로, 없으면 경로 첫 번째 좌표로 카메라 설정
                if let coordinate = locationManager.getCurrentLocationAsNMGLatLng() {
                    locationManager.setInitialCameraPosition(to: coordinate, on: mapView)
                    print("🎯 카메라를 사용자 위치로 이동: \(coordinate.lat), \(coordinate.lng)")
                } else if let firstLocation = routeLocation.first,
                          let lat = Double(firstLocation.lat),
                          let lon = Double(firstLocation.lon) {
                    let coordinate = NMGLatLng(lat: lat, lng: lon)
                    locationManager.setInitialCameraPosition(to: coordinate, on: mapView)
                    print("🎯 카메라를 경로 첫 번째 좌표로 이동: \(lat), \(lon)")
                } else {
                    print("⚠️ 사용자 위치와 경로 데이터 모두 없음 - 기본 카메라 위치 유지")
                }
            } else {
                print("❌ mapView가 nil - 네비게이션 모드 시작 불가")
            }
            
            // 위치 추적 콜백 설정 (비정상 종료 시 강화)
            setupLocationTrackingCallback(locationManager: locationManager)
        }
        
        Task { [weak self] in
            do {
                try Task.checkCancellation()
                await self?.getRouteLocationAPI()
                
                try Task.checkCancellation()
                await self?.getRoutePathAPI()
                
                // API 호출 완료 후 초기 카메라 위치 설정 (flag가 false일 때만)
                try Task.checkCancellation()
                await MainActor.run {
                    guard let self = self,
                          let firstLocation = self.routeLocation.first,
                          let lat = Double(firstLocation.lat),
                          let lon = Double(firstLocation.lon),
                          let mapView = self.mapView else {
                        print("❌ 초기 카메라 위치 설정 실패: mapView 또는 경로 데이터가 없습니다")
                        return
                    }
                    
                    // flag가 false일 때만 경로 첫 번째 좌표로 카메라 설정
                    if !self.flag {
                        let coordinate = NMGLatLng(lat: lat, lng: lon)
                        self.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
                        print("초기 카메라 위치를 경로 첫 번째 좌표로 설정: \(lat), \(lon)")
                    }
                }
            } catch is CancellationError {
                print("🚫 RidingView 초기화 Task 취소됨")
            } catch {
                print("❌ RidingView 초기화 에러: \(error)")
            }
        } // : Task
    }
    
    // MARK: - 위치 추적 콜백 설정 (비정상 종료 시 강화)
    @MainActor private func setupLocationTrackingCallback(locationManager: LocationManager) {
        print("📍 위치 추적 콜백 설정 시작")
        
        // 새로운 콜백 생성
        let newCallback: (NMGLatLng) -> Void = { newLocation in
            print("📍 위치 업데이트 수신: \(newLocation.lat), \(newLocation.lng)")
            
            // mapViewController 업데이트
            if let mapViewController = self.mapViewController {
                let clLocation = CLLocation(latitude: newLocation.lat, longitude: newLocation.lng)
                mapViewController.updateUserLocation(clLocation)
                print("📍 mapViewController 위치 업데이트 완료")
            }
            
            // 마커 추적 및 카메라 업데이트
            self.updateUserLocationAndCheckMarkers(newLocation)
        }
        
        // 콜백 설정
        locationManager.onLocationUpdateNMGLatLng = newCallback
        
        // 위치 추적 시작
        locationManager.startLocationUpdates()
        print("📍 위치 추적 시작 완료 - 콜백 설정됨")
        
        // 비정상 종료 시 추가 안정화 로직
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if locationManager.onLocationUpdateNMGLatLng == nil {
                print("⚠️ 위치 추적 콜백이 nil - 재설정 시도")
                locationManager.onLocationUpdateNMGLatLng = newCallback
            }
        }
    }
    
}
