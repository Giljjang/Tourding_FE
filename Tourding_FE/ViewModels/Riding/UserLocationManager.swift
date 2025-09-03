//
//  UserLocationManager.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/7/25.
//

import Foundation
import CoreLocation
import NMapsMap
import Combine

@MainActor
final class UserLocationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var currentLocationString: String = "위치를 가져오는 중..."
    @Published var isLocationAuthorized: Bool = false
    @Published var locationError: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10미터마다 업데이트
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
}

// MARK: - CLLocationManagerDelegate
extension UserLocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        currentLocationString = "위도: \(location.coordinate.latitude), 경도: \(location.coordinate.longitude)"
        locationError = nil
        
        // 위치 업데이트 후 중지 (필요시 계속 업데이트하려면 이 줄을 제거)
        // locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 위치 가져오기 실패: \(error.localizedDescription)")
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
