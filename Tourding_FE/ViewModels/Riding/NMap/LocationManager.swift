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
    @Published var isLocationTrackingEnabled: Bool = true // 위치추적 상태 (라이딩 중)
    private var lastHeadingUpdate: Date = Date()
    private let headingUpdateThreshold: TimeInterval = 0.5 // 0.5초마다 업데이트
    // 바텀시트 높이에 따라 동적으로 조정할 카메라 pivot Y 값
    @Published var cameraPivotY: CGFloat = 0.3
    
    // MARK: - Auto Tracking Properties
    private var touchTimer: Timer?
    private let autoTrackingDelay: TimeInterval = 20.0 // 20초 후 자동 위치추적
    
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
        cameraUpdate.pivot = CGPoint(x: 0.5, y: cameraPivotY)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }
    
    // 현재 위치로 카메라 이동
    /// 사용자 위치 오버레이를 **보이게** 하고 위치·아이콘·방향을 맞춘다.
    ///
    /// `NMFLocationOverlay`는 기본이 숨김이라 이걸 부르기 전에는 마커가 그려지지 않는다.
    /// 예전에는 이 코드가 `moveToCurrentLocation`(= "내 위치로 이동" 버튼) 안에만 있어서,
    /// 버튼을 누르지 않고 라이딩을 시작하면 라이딩 중 위치 콜백이 올 때까지 마커가 없었다.
    /// `distanceFilter`가 3m라 정지 상태에서는 그 콜백이 오지 않아 계속 안 보였다.
    func showUserLocationOverlay(on mapView: NMFMapView, at coordinate: NMGLatLng) {
        let locationOverlay = mapView.locationOverlay
        locationOverlay.hidden = false
        locationOverlay.location = coordinate
        locationOverlay.icon = MarkerIcons.userMarker

        updateLocationOverlayHeading(on: mapView)
    }

    func moveToCurrentLocation(on mapView: NMFMapView) {
        guard let location = locationManager.location else { return }
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude

        showUserLocationOverlay(on: mapView, at: NMGLatLng(lat: lat, lng: lng))
        
        // 카메라 중심점을 위쪽으로 조정
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: lat, lng: lng))
        cameraUpdate.pivot = CGPoint(x: 0.5, y: cameraPivotY)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }
    
    // 위치 오버레이 방향 업데이트
    func updateLocationOverlayHeading(on mapView: NMFMapView) {
        let locationOverlay = mapView.locationOverlay
        
        // currentHeading은 이미 HeadingResolver가 고른 진북 기준 값이다.
        // 여기서는 아이콘 보정만 더한다 — 오프셋 상수를 복제하지 말 것.
        let adjustedHeading = HeadingResolver.normalized(
            currentHeading + HeadingResolver.markerIconOffset
        )
        locationOverlay.heading = CGFloat(adjustedHeading)
    }
    
    // MARK: - Navigation Methods
    
    // 네비게이션 모드 시작
    func startNavigationMode(on mapView: NMFMapView) {
        isNavigationMode = true
        isLocationTrackingEnabled = true
        // print("🧭 네비게이션 모드 시작 - 위치추적 on")
        
        // 나침반 업데이트 강제 시작
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
            // print("🧭 나침반 업데이트 시작")
        } else {
            print("❌ 나침반을 사용할 수 없습니다")
        }
        
        // 현재 위치로 카메라 이동하고 헤딩 적용 (네비게이션 모드에서는 중앙에 위치)
        if let location = currentLocation {
            let coordinate = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)

            // 마커를 여기서 켠다. 안 켜면 "내 위치로 이동"을 누르지 않고 라이딩을 시작했을 때
            // 3m를 움직이기 전까지 마커가 보이지 않는다.
            showUserLocationOverlay(on: mapView, at: coordinate)

            let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
            cameraUpdate.pivot = CGPoint(x: 0.5, y: cameraPivotY)
            cameraUpdate.animation = .easeIn
            mapView.moveCamera(cameraUpdate)
            
            // 헤딩 적용
            updateCameraWithHeading(on: mapView, location: location)
        }
    }
    
    // MARK: - Camera Pivot

    /// 바텀시트 위치별 카메라 피봇 Y. `nil`이면 카메라를 건드리지 않는다.
    ///
    /// 피봇은 `(0,0)`이 좌상단이라 값이 클수록 사용자가 화면 **아래쪽**에 놓인다.
    /// 시트가 작을수록 지도가 넓게 보이므로 시점을 더 위로(값을 크게) 둔다.
    static func cameraPivot(for position: BottomSheetPosition) -> CGFloat? {
        switch position {
        case .small:  return 0.6
        case .medium: return 0.4
        case .large:  return nil   // 지도가 거의 가려지므로 카메라를 건드리지 않는다
        }
    }

    /// 시트 위치를 피봇에 반영한다.
    ///
    /// 편집 모드에서도 반드시 불러야 한다 — 안 부르면 "내 위치로 이동" 버튼이
    /// 기본값 0.3을 쓰고, 라이딩을 했다 돌아온 경우엔 직전 라이딩의 값이 남는다.
    func syncCameraPivot(for position: BottomSheetPosition) {
        guard let pivot = Self.cameraPivot(for: position) else { return }
        cameraPivotY = pivot
    }

    // MARK: - Camera Follow

    /// 카메라가 사용자를 따라가야 하는가.
    ///
    /// 기준은 "라이딩 중인가"(`RidingViewModel.flag`)가 아니라 **"추적 중인가"**다.
    /// 사용자가 지도를 밀면 `handleScreenTouch`가 추적을 끄는데, `flag`로 판정하면
    /// 다음 GPS 갱신(`distanceFilter` 3m)에 카메라가 도로 사용자 위치로 스냅된다.
    ///
    /// `isLocationTrackingEnabled`가 아니라 `isNavigationMode`를 쓴다 —
    /// 전자는 초기값이 `true`라 추적을 시작하기도 전에 따라가게 된다.
    var shouldFollowUser: Bool { isNavigationMode }

    /// 추적 중일 때만 카메라를 사용자 위치로 옮긴다.
    ///
    /// **카메라를 사용자에게 따라붙게 하는 코드는 전부 이 함수를 거칠 것.**
    /// 호출부에서 `moveCamera`를 직접 부르면 판정이 복제되고, 그 복제본이 이 버그였다
    /// (세 곳이 각자 판정하다 세 곳 모두 `flag`로 잘못 판정했다).
    ///
    /// - Returns: 실제로 카메라를 옮겼는지 여부
    @discardableResult
    func followUser(on mapView: NMFMapView, to coordinate: NMGLatLng) -> Bool {
        guard shouldFollowUser else { return false }

        let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
        cameraUpdate.pivot = CGPoint(x: 0.5, y: cameraPivotY)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
        return true
    }

    // 네비게이션 모드 종료
    func stopNavigationMode() {
        isNavigationMode = false
        isLocationTrackingEnabled = false
        cancelAutoTrackingTimer() // 타이머 정리
        // print("🧭 네비게이션 모드 종료")
    }
    
    /// 위치추적 토글 (라이딩 중 "경로 안내 재개" 버튼)
    ///
    /// 상태 전이를 `mapView` 유무와 분리한다.
    /// `currentMapView`는 `configureLocationManager`가 `onAppear`에서 **1회만**, 그것도
    /// `if let mapView` 가드 뒤에서 설정하므로 nil로 남을 수 있다. 여기서 그 참조에 의존하면
    /// 재개 버튼을 눌러도 추적이 켜지지 않는다. 카메라는 다음 위치 콜백이 `followUser`로 처리한다.
    @MainActor
    func toggleLocationTracking() {
        if shouldFollowUser {
            stopNavigationMode()
        } else {
            beginTracking()
        }
        print("📍 위치추적 상태 변경: \(isLocationTrackingEnabled)")
    }

    /// 지도를 밀어 추적이 꺼진 상태에서 사용자가 **실제로 움직였을 때** 추적을 되켠다.
    ///
    /// "얼마나 움직여야 하는가"는 호출부(`RidingViewModel.updateUserLocationAndCheckMarkers`)가
    /// 판정한다. 여기는 "꺼져 있으면 켠다"만 책임진다.
    ///
    /// - Returns: 이번 호출로 재개됐는지
    @discardableResult
    func resumeTrackingIfStopped() -> Bool {
        guard !shouldFollowUser else { return false }
        beginTracking()
        return true
    }

    /// 추적 상태를 켠다.
    ///
    /// `mapView` 참조가 아직 없어도 상태는 켠다 — `currentMapView`는 nil로 남을 수 있고,
    /// 카메라는 다음 위치 콜백이 `followUser`로 처리한다.
    private func beginTracking() {
        isNavigationMode = true
        isLocationTrackingEnabled = true

        if let mapView = getCurrentMapView() {
            startNavigationMode(on: mapView)
        }
    }
    
    // 화면 터치 감지 시 위치추적 off
    @MainActor
    func handleScreenTouch() {
        guard isNavigationMode else { return }
        
        print("👆 화면 터치 감지 - 위치추적 off")
        isLocationTrackingEnabled = false
        print("📍 위치추적 상태 변경: \(isLocationTrackingEnabled)")
        stopNavigationMode()
        
        // 20초 후 자동 위치추적 on 타이머 시작
//        startAutoTrackingTimer()
    }
    
    // 20초 후 자동 위치추적 on 타이머 시작
    private func startAutoTrackingTimer() {
        // 기존 타이머 취소
        touchTimer?.invalidate()
        
        touchTimer = Timer.scheduledTimer(withTimeInterval: autoTrackingDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                print("⏰ 20초 경과 - 자동 위치추적 on")
                self.toggleLocationTracking()
            }
        }
    }
    
    // 타이머 취소
    func cancelAutoTrackingTimer() {
        touchTimer?.invalidate()
        touchTimer = nil
    }
    
    // 현재 맵뷰 가져오기 (헬퍼 메서드)
    private func getCurrentMapView() -> NMFMapView? {
        return currentMapView
    }
    
    // 맵뷰 참조 설정 (RidingViewModel에서 호출)
    func setMapView(_ mapView: NMFMapView?) {
        self.currentMapView = mapView
    }
    
    private var currentMapView: NMFMapView?
    
    // 헤딩을 포함한 카메라 업데이트
    func updateCameraWithHeading(on mapView: NMFMapView, location: CLLocation) {
        guard isNavigationMode else { 
            print("❌ 네비게이션 모드가 아님 - 카메라 업데이트 건너뜀")
            return 
        }
        
        let now = Date()
        // 너무 빈번한 업데이트 방지
        guard now.timeIntervalSince(lastHeadingUpdate) >= headingUpdateThreshold else { 
//            print("⏰ 헤딩 업데이트 간격이 너무 짧음 - 건너뜀")
            return 
        }
        
        lastHeadingUpdate = now
        
        let coordinate = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        
        // 현재 카메라 위치 가져오기
        let currentCamera = mapView.cameraPosition
        
        // print("🧭 카메라 업데이트 시작 - 현재 헤딩: \(currentHeading)도, 줌: \(currentCamera.zoom)")
        
        // 새로운 카메라 위치 생성 (헤딩 포함)
        // 카메라 보정은 마커 보정과 별개다 — HeadingResolver 참조
        let newCameraPosition = NMFCameraPosition(
            coordinate,
            zoom: currentCamera.zoom,
            tilt: currentCamera.tilt,
            heading: HeadingResolver.cameraHeading(from: currentHeading)
        )
        
        // 카메라 업데이트 - 네비게이션 모드에서는 화면 중앙에 위치
        let cameraUpdate = NMFCameraUpdate(position: newCameraPosition)
        cameraUpdate.pivot = CGPoint(x: 0.5, y: cameraPivotY)
        cameraUpdate.animation = .easeOut
        cameraUpdate.animationDuration = 0.3 // 부드러운 애니메이션
        
        mapView.moveCamera(cameraUpdate)
        
        // print("🧭 카메라 헤딩 업데이트 완료: \(currentHeading)도 (피봇: \(cameraPivotY))")
    }
    
    // 위치 업데이트 시 네비게이션 모드에서 카메라 업데이트
    func updateNavigationCamera(on mapView: NMFMapView, location: CLLocation) {
        guard isNavigationMode else { return }
        updateCameraWithHeading(on: mapView, location: location)
    }
}

extension LocationManager {
    // 바텀시트 위치 변화에 따라 카메라 pivot만 재조정
    func updateCameraPivot(on mapView: NMFMapView, yPivot: CGFloat) {
        // 기존 애니메이션 취소
        mapView.cancelTransitions()
        
        // 네비게이션 모드에서는 현재 위치 기반으로 카메라 업데이트
        if shouldFollowUser, let location = currentLocation {
            let coordinate = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
            cameraUpdate.pivot = CGPoint(x: 0.5, y: yPivot)
            cameraUpdate.animation = .easeIn
            cameraUpdate.animationDuration = 0.2
            mapView.moveCamera(cameraUpdate)
        } else {
            // 일반 모드에서는 현재 카메라 위치 유지하면서 pivot만 변경
            let currentCamera = mapView.cameraPosition
            let cameraUpdate = NMFCameraUpdate(position: currentCamera)
            cameraUpdate.pivot = CGPoint(x: 0.5, y: yPivot)
            cameraUpdate.animation = .easeIn
            cameraUpdate.animationDuration = 0.2
            mapView.moveCamera(cameraUpdate)
        }
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
        
        // 라이딩 중일 때는 통합된 콜백만 호출 (중복 방지)
        print("🌍 위치 콜백 호출 - 네비게이션 모드: \(isNavigationMode), 콜백 존재: \(onLocationUpdateNMGLatLng != nil)")
        
        // 메인 스레드에서 콜백 실행하여 스레드 안전성 확보
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 네비게이션 모드와 관계없이 항상 콜백 호출 (정밀도 향상)
            if let onLocationUpdateNMGLatLng = self.onLocationUpdateNMGLatLng {
                let nmgLocation = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
                onLocationUpdateNMGLatLng(nmgLocation)
                print("🌍 통합된 위치 콜백 호출 완료 (네비게이션 모드: \(self.isNavigationMode))")
            } else {
                print("❌ onLocationUpdateNMGLatLng 콜백이 nil입니다")
            }
            
            // 기존 콜백도 호출 (호환성 유지)
            self.onLocationUpdate?(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // print("🧭 didUpdateHeading 호출됨 - 정확도: \(newHeading.headingAccuracy)")
        
        // 방위 판정은 HeadingResolver 한 곳에 있다 — 여기서 원본을 직접 고르지 말 것.
        // 자북을 그대로 쓰면 진북 기준인 지도가 편각만큼(서울 약 9도) 틀어져 회전한다.
        guard let resolved = HeadingResolver.mapHeading(from: newHeading) else {
            // print("❌ 나침반 데이터가 부정확함 - 무시")
            return
        }

        let oldHeading = currentHeading
        currentHeading = resolved
        
        // print("🧭 헤딩 변경: \(oldHeading)도 → \(currentHeading)도")
        
        // 콜백 호출
        onHeadingUpdate?(newHeading)
        
        // 네비게이션 모드에서 헤딩 업데이트 시 카메라 회전
        if isNavigationMode {
            // print("🧭 네비게이션 모드에서 헤딩 업데이트: \(currentHeading)도")
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
