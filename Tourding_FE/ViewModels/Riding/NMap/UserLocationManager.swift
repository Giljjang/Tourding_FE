//
//  UserLocationManager.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/7/25.
//

import Foundation
import CoreLocation
import NMapsMap

@MainActor
final class UserLocationManager: NSObject, ObservableObject {
    
    var onLocationUpdate: ((NMGLatLng) -> Void)?
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var currentLocationString: String = "위치를 가져오는 중..."
    @Published var isLocationAuthorized: Bool = false
    @Published var locationError: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 3 // 3미터마다 업데이트 (사용자 움직임에 더 민감하게)
    }
    
    // MARK: - Public Methods
    
    // 현재 위치 가져오기 시작
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
    
    // 위치 권한 요청
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // 위치 업데이트 중지
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // 현재 위치를 NMGLatLng로 반환
    func getCurrentLocationAsNMGLatLng() -> NMGLatLng? {
        guard let location = currentLocation else { return nil }
        return NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
    }
    
    // 현재 위치를 문자열로 반환 (위도,경도)
    func getCurrentLocationString() -> String {
        guard let location = currentLocation else { return "위치를 가져올 수 없습니다" }
        return "\(location.coordinate.latitude),\(location.coordinate.longitude)"
    }
    
    // 두 위치 간의 거리 계산 (미터)
    func calculateDistance(from location1: CLLocation, to location2: CLLocation) -> CLLocationDistance {
        return location1.distance(from: location2)
    }
    
    // 현재 위치에서 특정 좌표까지의 거리 계산
    func calculateDistanceFromCurrentLocation(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }
    
    // 현재 위치에서 특정 좌표까지의 거리를 포맷된 문자열로 반환
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
    
    // 위치 서비스 활성화 여부 확인
    func isLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    // 위치 업데이트 시작
    func startLocationUpdates() {
        print("🌍 UserLocationManager: startLocationUpdates 호출됨")
        print("🌍 isLocationAuthorized: \(isLocationAuthorized)")
        
        guard isLocationAuthorized else {
            print("❌ 위치 권한이 없음 - 권한 요청")
            getCurrentLocation() // 권한이 없으면 먼저 권한 요청
            return
        }
        
        print("✅ 위치 권한 있음 - 위치 업데이트 시작")
        locationManager.startUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension UserLocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("🌍 UserLocationManager: didUpdateLocations 호출됨")
        print("🌍 받은 위치 개수: \(locations.count)")
        
        guard let location = locations.last else { 
            print("❌ 위치 데이터가 없음")
            return 
        }
        
        print("🌍 최신 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("🌍 정확도: \(location.horizontalAccuracy)m")
        
        currentLocation = location
        currentLocationString = "위도: \(location.coordinate.latitude), 경도: \(location.coordinate.longitude)"
        locationError = nil
        
        // 위치 업데이트 후 중지 (필요시 계속 업데이트하려면 이 줄을 제거)
        // locationManager.stopUpdatingLocation()
        
        // 이 부분이 핵심 - 콜백이 설정되어 있는지 확인
        print("🌍 onLocationUpdate 콜백 존재: \(onLocationUpdate != nil)")
        
        if let onLocationUpdate = onLocationUpdate {
            let nmgLocation = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            
            onLocationUpdate(nmgLocation)
            
            print("🌍 onLocationUpdate 콜백 호출 완료")
        } else {
            print("❌ onLocationUpdate 콜백이 nil입니다!")
            print("❌ 콜백이 설정되지 않았습니다")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ UserLocationManager: 위치 가져오기 실패: \(error.localizedDescription)")
        
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
