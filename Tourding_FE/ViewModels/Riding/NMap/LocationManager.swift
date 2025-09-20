//
//  LocationManager.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/26/25.
//

import UIKit
import CoreLocation
import NMapsMap
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties (UserLocationManager 기능)
    @Published var currentLocation: CLLocation?
    @Published var currentLocationString: String = "위치를 가져오는 중..."
    @Published var isLocationAuthorized: Bool = false
    @Published var locationError: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var currentHeading: CLLocationDirection = 0
    
    // MARK: - Callbacks (LocationManager 기능)
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onHeadingUpdate: ((CLHeading) -> Void)?
    var onLocationUpdateNMGLatLng: ((NMGLatLng) -> Void)?
    
    // MARK: - Navigation Properties
    @Published var isNavigationMode: Bool = false
    private var lastHeadingUpdate: Date = Date()
    private let headingUpdateThreshold: TimeInterval = 0.5 // 0.5초마다 업데이트
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    deinit {
        print("📍 LocationManager deinit 시작")
        // deinit에서는 MainActor 메서드를 직접 호출할 수 없으므로
        // 필요한 정리 작업만 수행
        locationManager.delegate = nil
        onLocationUpdate = nil
        onHeadingUpdate = nil
        onLocationUpdateNMGLatLng = nil
        print("✅ LocationManager 리소스 정리 완료")
    }
    
    // MARK: - Cleanup
    func cleanupResources() {
        // 위치 업데이트 중지
        stopLocationUpdates()
        
        // 델리게이트 해제
        locationManager.delegate = nil
        
        // 콜백 해제
        onLocationUpdate = nil
        onHeadingUpdate = nil
        onLocationUpdateNMGLatLng = nil
        
        print("✅ LocationManager 리소스 정리 완료")
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 3 // 3미터마다 업데이트 (사용자 움직임에 더 민감하게)
        locationManager.headingFilter = 1 // 1도 이상 변경시에만 업데이트 (더 민감하게)
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Public Methods
    
    // 위치 업데이트 시작
    func startLocationUpdates() {
        print("🌍 LocationManager: startLocationUpdates 호출됨")
        print("🌍 isLocationAuthorized: \(isLocationAuthorized)")
        
        guard isLocationAuthorized else {
            print("❌ 위치 권한이 없음 - 권한 요청")
            getCurrentLocation() // 권한이 없으면 먼저 권한 요청
            return
        }
        
        print("✅ 위치 권한 있음 - 위치 업데이트 시작")
        locationManager.startUpdatingLocation()
        
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    // 위치 업데이트 중지
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        
        if CLLocationManager.headingAvailable() {
            locationManager.stopUpdatingHeading()
        }
    }
    
    // 현재 위치 가져오기 시작 (UserLocationManager 기능)
    func getCurrentLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            currentLocationString = "위치 권한이 거부되었습니다"
            isLocationAuthorized = false
            locationError = "위치 권한이 필요합니다. 설정에서 권한을 허용해주세요."
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            isLocationAuthorized = true
            locationError = nil
        @unknown default:
            currentLocationString = "알 수 없는 위치 권한 상태"
            isLocationAuthorized = false
            locationError = "알 수 없는 권한 상태입니다."
        }
    }
    
    // 현재 위치를 CLLocation으로 반환
    func getCurrentLocationAsCLLocation() -> CLLocation? {
        return locationManager.location
    }
    
    // 현재 위치를 NMGLatLng로 반환 (UserLocationManager 기능)
    func getCurrentLocationAsNMGLatLng() -> NMGLatLng? {
        guard let location = currentLocation else { return nil }
        return NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
    }
    
    // 현재 위치를 문자열로 반환 (위도,경도) (UserLocationManager 기능)
    func getCurrentLocationString() -> String {
        guard let location = currentLocation else { return "위치를 가져올 수 없습니다" }
        return "\(location.coordinate.latitude),\(location.coordinate.longitude)"
    }
    
    // 두 위치 간의 거리 계산 (미터) (UserLocationManager 기능)
    func calculateDistance(from location1: CLLocation, to location2: CLLocation) -> CLLocationDistance {
        return location1.distance(from: location2)
    }
    
    // 현재 위치에서 특정 좌표까지의 거리 계산 (UserLocationManager 기능)
    func calculateDistanceFromCurrentLocation(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }
    
    // 현재 위치에서 특정 좌표까지의 거리를 포맷된 문자열로 반환 (UserLocationManager 기능)
    func getFormattedDistanceFromCurrentLocation(to coordinate: CLLocationCoordinate2D) -> String {
        guard let distance = calculateDistanceFromCurrentLocation(to: coordinate) else {
            return "거리 계산 불가"
        }
        
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let km = distance / 1000
            return String(format: "%.1fkm", km)
        }
    }
    
    // 위치 권한 상태 확인
    func checkLocationAuthorizationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    // 위치 권한 요청
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // 위치 서비스 활성화 여부 확인 (UserLocationManager 기능)
    func isLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    // MARK: - NMFMapView 관련 메서드 (LocationManager 기능)
    
    // 초기 카메라 위치를 특정 좌표로 설정하는 메서드
    func setInitialCameraPosition(to coordinate: NMGLatLng, on mapView: NMFMapView) {
        let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
        cameraUpdate.pivot = CGPoint(x: 0.5, y: 0.3) // x: 0.5(가로 중앙), y: 0.3(세로 위쪽)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }
    
    // 현재 위치로 카메라 이동
    func moveToCurrentLocation(on mapView: NMFMapView) {
        guard let location = locationManager.location else { return }
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        let locationOverlay = mapView.locationOverlay
        locationOverlay.hidden = false
        locationOverlay.location = NMGLatLng(lat: lat, lng: lng)
        
        // 사용자 위치 마커 설정
        locationOverlay.icon = MarkerIcons.userMarker
        
        // 방향 설정
        updateLocationOverlayHeading(on: mapView)
        
        // 카메라 중심점을 위쪽으로 조정
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: lat, lng: lng))
        cameraUpdate.pivot = CGPoint(x: 0.5, y: 0.3) // x: 0.5(가로 중앙), y: 0.3(세로 위쪽)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }
    
    // 위치 오버레이 방향 업데이트
    func updateLocationOverlayHeading(on mapView: NMFMapView) {
        let locationOverlay = mapView.locationOverlay
        
        // 이미지가 오른쪽 하단을 가리키므로 -45도 오프셋 적용
        let adjustedHeading = currentHeading - 45.0
        locationOverlay.heading = CGFloat(adjustedHeading)
    }
    
    // MARK: - Navigation Methods
    
    // 네비게이션 모드 시작
    func startNavigationMode(on mapView: NMFMapView) {
        isNavigationMode = true
        print("🧭 네비게이션 모드 시작")
        
        // 나침반 업데이트 강제 시작
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
            print("🧭 나침반 업데이트 시작")
        } else {
            print("❌ 나침반을 사용할 수 없습니다")
        }
        
        // 현재 위치로 카메라 이동하고 헤딩 적용 (네비게이션 모드에서는 중앙에 위치)
        if let location = currentLocation {
            let coordinate = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
            cameraUpdate.pivot = CGPoint(x: 0.5, y: 0.3) // 네비게이션 모드에서는 화면 중앙
            cameraUpdate.animation = .easeIn
            mapView.moveCamera(cameraUpdate)
            
            // 헤딩 적용
            updateCameraWithHeading(on: mapView, location: location)
        }
    }
    
    // 네비게이션 모드 종료
    func stopNavigationMode() {
        isNavigationMode = false
        print("🧭 네비게이션 모드 종료")
    }
    
    // 헤딩을 포함한 카메라 업데이트
    func updateCameraWithHeading(on mapView: NMFMapView, location: CLLocation) {
        guard isNavigationMode else { 
            print("❌ 네비게이션 모드가 아님 - 카메라 업데이트 건너뜀")
            return 
        }
        
        let now = Date()
        // 너무 빈번한 업데이트 방지
        guard now.timeIntervalSince(lastHeadingUpdate) >= headingUpdateThreshold else { 
            print("⏰ 헤딩 업데이트 간격이 너무 짧음 - 건너뜀")
            return 
        }
        
        lastHeadingUpdate = now
        
        let coordinate = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        
        // 현재 카메라 위치 가져오기
        let currentCamera = mapView.cameraPosition
        
        print("🧭 카메라 업데이트 시작 - 현재 헤딩: \(currentHeading)도, 줌: \(currentCamera.zoom)")
        
        // 새로운 카메라 위치 생성 (헤딩 포함)
        let newCameraPosition = NMFCameraPosition(
            coordinate,
            zoom: currentCamera.zoom,
            tilt: currentCamera.tilt,
            heading: currentHeading
        )
        
        // 카메라 업데이트 - 네비게이션 모드에서는 화면 중앙에 위치
        let cameraUpdate = NMFCameraUpdate(position: newCameraPosition)
        cameraUpdate.pivot = CGPoint(x: 0.5, y: 0.3) // 네비게이션 모드에서는 화면 중앙
        cameraUpdate.animation = .easeOut
        cameraUpdate.animationDuration = 0.3 // 부드러운 애니메이션
        
        mapView.moveCamera(cameraUpdate)
        
        print("🧭 카메라 헤딩 업데이트 완료: \(currentHeading)도")
    }
    
    // 위치 업데이트 시 네비게이션 모드에서 카메라 업데이트
    func updateNavigationCamera(on mapView: NMFMapView, location: CLLocation) {
        guard isNavigationMode else { return }
        updateCameraWithHeading(on: mapView, location: location)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("🌍 LocationManager: didUpdateLocations 호출됨")
        print("🌍 받은 위치 개수: \(locations.count)")
        
        guard let location = locations.last else { 
            print("❌ 위치 데이터가 없음")
            return 
        }
        
        print("🌍 최신 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("🌍 정확도: \(location.horizontalAccuracy)m")
        
        // Published 프로퍼티 업데이트 (UserLocationManager 기능)
        currentLocation = location
        currentLocationString = "위도: \(location.coordinate.latitude), 경도: \(location.coordinate.longitude)"
        locationError = nil
        
        // CLLocation 콜백 호출 (LocationManager 기능)
        onLocationUpdate?(location)
        
        // NMGLatLng 콜백 호출 (UserLocationManager 기능)
        if let onLocationUpdateNMGLatLng = onLocationUpdateNMGLatLng {
            let nmgLocation = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            onLocationUpdateNMGLatLng(nmgLocation)
            print("🌍 onLocationUpdateNMGLatLng 콜백 호출 완료")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("🧭 didUpdateHeading 호출됨 - 정확도: \(newHeading.headingAccuracy)")
        
        // 나침반 데이터가 부정확한 경우 무시
        if newHeading.headingAccuracy < 0 {
            print("❌ 나침반 데이터가 부정확함 - 무시")
            return
        }
        
        // 자북(magnetic north) 기준 방향 사용
        let oldHeading = currentHeading
        currentHeading = newHeading.magneticHeading
        
        print("🧭 헤딩 변경: \(oldHeading)도 → \(currentHeading)도")
        
        // 콜백 호출
        onHeadingUpdate?(newHeading)
        
        // 네비게이션 모드에서 헤딩 업데이트 시 카메라 회전
        if isNavigationMode {
            print("🧭 네비게이션 모드에서 헤딩 업데이트: \(currentHeading)도")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ LocationManager: 위치 가져오기 실패: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .locationUnknown:
                print("❌ 위치를 찾을 수 없음 - GPS 신호가 약하거나 위치 서비스가 비활성화됨")
            case .denied:
                print("❌ 위치 서비스 권한이 거부됨 - 설정에서 권한을 허용해주세요")
            case .network:
                print("❌ 네트워크 에러 - 인터넷 연결을 확인해주세요")
            case .headingFailure:
                print("❌ 나침반 에러 - 나침반을 사용할 수 없음")
            default:
                print("❌ 알 수 없는 CoreLocation 에러: \(clError.code.rawValue)")
            }
        }
        
        // Published 프로퍼티 업데이트
        currentLocationString = "위치를 가져올 수 없습니다"
        currentLocation = nil
        locationError = error.localizedDescription
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isLocationAuthorized = true
                self.currentLocationString = "위치 권한이 허용되었습니다"
                self.locationError = nil
                // 권한이 허용되면 자동으로 위치 가져오기 시작
                self.getCurrentLocation()
            case .denied, .restricted:
                self.isLocationAuthorized = false
                self.currentLocationString = "위치 권한이 거부되었습니다"
                self.currentLocation = nil
                self.locationError = "위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요."
            case .notDetermined:
                self.isLocationAuthorized = false
                self.currentLocationString = "위치 권한을 확인하는 중..."
                self.locationError = nil
            @unknown default:
                self.isLocationAuthorized = false
                self.currentLocationString = "알 수 없는 권한 상태"
                self.locationError = "알 수 없는 권한 상태입니다."
            }
        }
    }
}
