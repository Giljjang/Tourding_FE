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

final class LocationManager: NSObject {
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let cancelBag = CancelBag()
    private var currentHeading: CLLocationDirection = 0
    
    // MARK: - Callbacks
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onHeadingUpdate: ((CLHeading) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 5 // 5도 이상 변경시에만 업데이트
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Public Methods
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        
        if CLLocationManager.headingAvailable() {
            locationManager.stopUpdatingHeading()
        }
    }
    
    func getCurrentLocation() -> CLLocation? {
        return locationManager.location
    }
    
    func moveToCurrentLocation(on mapView: NMFMapView) {
        guard let location = locationManager.location else { return }
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        let locationOverlay = mapView.locationOverlay
        locationOverlay.hidden = false
        locationOverlay.location = NMGLatLng(lat: lat, lng: lng)
        
        // 사용자 위치 마커 설정
        locationOverlay.icon = MarkerIcons.userMarker
        
        // 방향 설정 (NMFLocationOverlay는 bearing 대신 다른 방식 사용)
        updateLocationOverlayHeading(on: mapView)
        
        // 카메라 중심점을 위쪽으로 조정 (pivot: 0.5, 0.5가 중앙, 0.5, 0.3은 위쪽)
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: lat, lng: lng))
        cameraUpdate.pivot = CGPoint(x: 0.5, y: 0.3) // x: 0.5(가로 중앙), y: 0.3(세로 위쪽)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }
    
    // MARK: - Private Methods
    func updateLocationOverlayHeading(on mapView: NMFMapView) {
        // NMFLocationOverlay에서 방향을 설정하는 방법
        // heading 속성을 사용 (도 단위, 북쪽이 0도)
        let locationOverlay = mapView.locationOverlay
        
        // 이미지가 오른쪽 하단을 가리키므로 -45도 오프셋 적용
        let adjustedHeading = currentHeading - 45.0
        locationOverlay.heading = CGFloat(adjustedHeading)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // 나침반 방향 업데이트
        if newHeading.headingAccuracy < 0 {
            // 나침반 데이터가 부정확한 경우 무시
            return
        }
        
        // 자북(magnetic north) 기준 방향 사용
        currentHeading = newHeading.magneticHeading
        
        // 콜백 호출
        onHeadingUpdate?(newHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
