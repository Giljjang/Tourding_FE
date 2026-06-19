//
//  MapViewController.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/27/25.
//

import SwiftUI
import UIKit
import NMapsMap
import CoreLocation
import Combine

// MARK: - MapViewController
final class MapViewController: UIViewController {
    
    // MARK: - Properties
    private var mapView: NMFNaverMapView?
    let locationManager = LocationManager()
    private let locationButton = UIButton(type: .custom)
    var ridingViewModel: RidingViewModel?
    var userLocationManager: LocationManager?
    
    // MARK: - Data Properties
    var pathCoordinates: [NMGLatLng] = []
    var markerCoordinates: [NMGLatLng] = []
    var markerIcons: [NMFOverlayImage] = []
    
    var toiletMarkerCoordinates: [NMGLatLng] = []
    var toiletMarkerIcons: [NMFOverlayImage] = []
    
    var csMarkerCoordinates: [NMGLatLng] = []
    var csMarkerIcons: [NMFOverlayImage] = []
    
    // MARK: - Callbacks
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onMapTap: ((NMGLatLng) -> Void)?
    
    // MARK: - Managers
    var markerManager: MarkerManager?
    var pathManager: PathManager?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupLocationManager()
    }
    
    deinit {
        print("🗺️ MapViewController deinit 시작")
        cleanupResources()
    }
    
    // MARK: - Cleanup
    private func cleanupResources() {
        // 위치 업데이트 중지
        locationManager.stopLocationUpdates()
        
        // 콜백 해제
        onLocationUpdate = nil
        onMapTap = nil
        
        // 마커 매니저 정리
        markerManager?.clearAllMarkers()
        markerManager = nil
        
        // 경로 매니저 정리
        pathManager?.clearPath()
        pathManager = nil
        
        // 지도 뷰 정리
        mapView?.removeFromSuperview()
        mapView = nil
        
        // 사용자 위치 매니저 정리
        userLocationManager = nil
        ridingViewModel = nil
        
        print("✅ MapViewController 리소스 정리 완료")
    }
    
    // MARK: - Setup Methods
    private func setupMap() {
        mapView = NMFNaverMapView(frame: view.frame)
        mapView?.showLocationButton = false
        mapView?.showZoomControls = false
        
        if let mapView = mapView {
            view.addSubview(mapView)
            setupManagers()
        } else {
            print("❌ mapView 초기화 실패")
        }
    }
    
    private func setupManagers() {
        guard let mapView = mapView else {
            print("❌ mapView가 nil입니다")
            return
        }
        
        markerManager = MarkerManager(mapView: mapView.mapView)
        pathManager = PathManager(mapView: mapView.mapView)
    }
    
    private func setupLocationManager() {
        var isFirstLocationUpdate = true
        
        // 위치 업데이트 콜백은 RidingView에서 설정하므로 여기서는 설정하지 않음
        // 대신 onLocationUpdate 콜백이 호출될 때 MapViewController의 기능도 실행하도록 수정
        
        // 나침반 방향 업데이트 콜백 추가
        locationManager.onHeadingUpdate = { [weak self] heading in
            self?.updateUserLocationBearing(heading)
        }
        
        locationManager.startLocationUpdates()
    }
    
    // LocationManager 설정 메서드 추가
    func setupUserLocationManager(_ userLocationManager: LocationManager) {
        self.userLocationManager = userLocationManager
        
        // 헤딩 업데이트 콜백 설정 (네비게이션 모드용)
        userLocationManager.onHeadingUpdate = { [weak self] heading in
            guard let self = self,
                  let mapView = self.mapView?.mapView,
                  userLocationManager.isNavigationMode else { 
//                print("❌ MapViewController: 헤딩 콜백 조건 불만족")
                return 
            }
            
//            print("🗺️ MapViewController: 헤딩 콜백 호출됨 - \(heading.magneticHeading)도")
            
            // 사용자 마커 방향 업데이트
            userLocationManager.updateLocationOverlayHeading(on: mapView)
            
            // 네비게이션 모드에서 헤딩 업데이트 시 카메라 회전
            if let location = userLocationManager.currentLocation {
                userLocationManager.updateNavigationCamera(on: mapView, location: location)
            }
        }
        
        // 위치 업데이트 콜백 설정 (네비게이션 모드용)
        userLocationManager.onLocationUpdate = { [weak self] location in
            guard let self = self,
                  let mapView = self.mapView?.mapView,
                  userLocationManager.isNavigationMode else { 
                return 
            }
            
//            print("🗺️ MapViewController: 위치 업데이트 콜백 호출됨 - 네비게이션 모드")
            
            // 네비게이션 모드에서 위치 업데이트 시 카메라 설정
            userLocationManager.updateNavigationCamera(on: mapView, location: location)
        }
        
//        print("🗺️ MapViewController: LocationManager 설정 완료 (콜백은 RidingView에서 설정)")
    }
    
    // MARK: - Public Methods
    var nmfMapView: NMFMapView? {
        return self.mapView?.mapView
    }
    
    // MARK: - Public Methods
    func clearToiletMarkers() {
        markerManager?.clearToiletMarkers()
    }

    func clearCSMarkers() {
        markerManager?.clearCSMarkers()
    }

    func updateMap() {
        guard let markerManager = markerManager,
              let pathManager = pathManager else {
            print("❌ 매니저가 초기화되지 않았습니다")
            return
        }
        
        // 기존 마커 업데이트
        if !markerCoordinates.isEmpty && !markerIcons.isEmpty {
            markerManager.addMarkers(coordinates: markerCoordinates, icons: markerIcons)
        }
        
        // 화장실 마커 업데이트
        if !toiletMarkerCoordinates.isEmpty && !toiletMarkerIcons.isEmpty {
            markerManager.addToiletMarkers(coordinates: toiletMarkerCoordinates, icons: toiletMarkerIcons)
        } else {
            markerManager.clearToiletMarkers()
        }
        
        // 편의점 마커 업데이트
        if !csMarkerCoordinates.isEmpty && !csMarkerIcons.isEmpty {
            markerManager.addCSMarkers(coordinates: csMarkerCoordinates, icons: csMarkerIcons)
        } else {
            markerManager.clearCSMarkers()
        }
        
        // 경로선 업데이트
        if !pathCoordinates.isEmpty {
            pathManager.setCoordinates(pathCoordinates)
        }
    }
    
    // MARK: - Location Methods
    private func setupInitialCameraPosition(location: CLLocation) {
        // ridingViewModel.flag가 true일 때만 사용자 위치로 카메라 이동
        guard let ridingViewModel = ridingViewModel, ridingViewModel.flag,
              let mapView = mapView else {
            return
        }
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        // 초기 카메라 위치를 사용자 현재 위치로 설정
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: lat, lng: lng))
        let pivotY = userLocationManager?.cameraPivotY ?? 0.5
        cameraUpdate.pivot = CGPoint(x: 0.5, y: pivotY)
        cameraUpdate.animation = .easeIn
        mapView.mapView.moveCamera(cameraUpdate)
    }
    
    func updateUserLocation(_ location: CLLocation) {
        guard let mapView = mapView else {
            print("❌ mapView가 nil입니다")
            return
        }
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        let locationOverlay = mapView.mapView.locationOverlay
        locationOverlay.hidden = false
        locationOverlay.location = NMGLatLng(lat: lat, lng: lng)
        
        // 사용자 위치 마커를 항상 userMarker으로 설정
        locationOverlay.icon = MarkerIcons.userMarker
        
        print("📍 MapViewController: 사용자 위치 마커 업데이트 완료 - \(lat), \(lng)")
        
        // ridingViewModel.flag가 true일 때만 카메라 이동
        guard let ridingViewModel = ridingViewModel, ridingViewModel.flag else {
            return
        }
        
        // 바텀시트 높이에 따른 동적 피봇 조정
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: lat, lng: lng))
        let pivotY = userLocationManager?.cameraPivotY ?? 0.5
        cameraUpdate.pivot = CGPoint(x: 0.5, y: pivotY)
        cameraUpdate.animation = .easeIn
        
        mapView.mapView.moveCamera(cameraUpdate)
        
        print("📷 MapViewController: 카메라 업데이트 완료 (피봇: \(pivotY))")
    }
    
    // 라이딩 중 LocationManager에서 호출되는 메서드
    private func updateUserLocationForRiding(_ location: CLLocation) {
        guard let mapView = mapView else {
            print("❌ mapView가 nil입니다")
            return
        }
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        let locationOverlay = mapView.mapView.locationOverlay
        locationOverlay.hidden = false
        locationOverlay.location = NMGLatLng(lat: lat, lng: lng)
        
        // 사용자 위치 마커를 항상 userMarker으로 설정
        locationOverlay.icon = MarkerIcons.userMarker
        
        // 카메라 이동은 RidingViewModel에서 제어하므로 여기서는 제거
        // ridingViewModel.updateUserLocationAndCheckMarkers에서 카메라 업데이트를 처리
    }
    
    // 나침반 방향 업데이트 메서드 추가
    private func updateUserLocationBearing(_ heading: CLHeading) {
        // 나침반 데이터가 부정확한 경우 무시
        if heading.headingAccuracy < 0 {
            return
        }
        
        guard let mapView = mapView else {
            print("❌ mapView가 nil입니다")
            return
        }
        
        let locationOverlay = mapView.mapView.locationOverlay
        
        // 이미지가 오른쪽 하단을 가리키므로 -45도 오프셋 적용
        // magneticHeading: 자북 기준 (0-359도)
        // trueHeading: 진북 기준 (더 정확하지만 GPS가 필요)
        let bearing = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        let adjustedHeading = bearing - 45.0
        
        // NMFLocationOverlay의 heading 속성 사용
        locationOverlay.heading = CGFloat(adjustedHeading)
    }
}

