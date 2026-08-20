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
    private let locationButton = UIButton(type: .custom)
    // ViewModel은 앱 수명, 이 컨트롤러는 화면 수명이다. strong으로 잡으면 순환이 생겨
    // deinit이 실행되지 않고 CLLocationManager가 화면을 떠난 뒤에도 계속 돈다.
    weak var ridingViewModel: RidingViewModel?
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
    
    // MARK: - Managers
    var markerManager: MarkerManager?
    var pathManager: PathManager?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
    }
    
    deinit {
        print("🗺️ MapViewController deinit 시작")
        cleanupResources()
    }
    
    // MARK: - Cleanup
    private func cleanupResources() {
        // 콜백 해제
        onLocationUpdate = nil
        
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
    
    // LocationManager 설정 메서드 추가
    func setupUserLocationManager(_ userLocationManager: LocationManager) {
        self.userLocationManager = userLocationManager
        
        // 헤딩 업데이트 콜백 설정 (네비게이션 모드용)
        // userLocationManager를 강하게 캡처하면 자기 콜백이 자기 자신을 붙잡아 절대 해제되지 않는다
        userLocationManager.onHeadingUpdate = { [weak self, weak userLocationManager] heading in
            guard let self = self,
                  let userLocationManager,
                  let mapView = self.mapView?.mapView else { return }

            // 마커 방향은 추적 여부와 무관하게 갱신한다.
            // 예전에는 MapViewController의 자체 LocationManager가 이 일을 했고 그쪽에는
            // 추적 가드가 없었다 — 인스턴스를 없애면서 그 동작을 여기로 옮긴다.
            self.updateUserLocationBearing(heading)

            // 카메라 회전만 추적 판정을 따른다
            guard userLocationManager.shouldFollowUser,
                  let location = userLocationManager.currentLocation else { return }

            userLocationManager.updateNavigationCamera(on: mapView, location: location)
        }
        
        // 위치 업데이트 콜백 설정 (네비게이션 모드용)
        userLocationManager.onLocationUpdate = { [weak self, weak userLocationManager] location in
            guard let self = self,
                  let userLocationManager,
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
    
    
    func updateUserLocation(_ location: CLLocation) {
        guard let mapView = mapView else {
            print("❌ mapView가 nil입니다")
            return
        }
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        // 오버레이 표시는 LocationManager 한 곳에서 한다 — 여기서 복제하지 말 것
        userLocationManager?.showUserLocationOverlay(
            on: mapView.mapView,
            at: NMGLatLng(lat: lat, lng: lng)
        )

        print("📍 MapViewController: 사용자 위치 마커 업데이트 완료 - \(lat), \(lng)")
        
        // 추적 중일 때만 카메라가 따라간다.
        // 판정은 LocationManager.shouldFollowUser 한 곳에 있다 — 여기서 복제하지 말 것.
        let didFollow = userLocationManager?.followUser(
            on: mapView.mapView,
            to: NMGLatLng(lat: lat, lng: lng)
        ) ?? false

        if didFollow {
            print("📷 MapViewController: 카메라 업데이트 완료")
        }
    }
    
    
    // 나침반 방향 업데이트 메서드 추가
    private func updateUserLocationBearing(_ heading: CLHeading) {
        // 판정은 HeadingResolver 한 곳에 있다.
        // 예전에는 여기(진북 우선)와 LocationManager(자북)가 같은 오버레이에
        // 서로 다른 기준의 값을 써서, 어느 쪽이 마지막에 이겼는지에 따라 마커가 달라졌다.
        guard let adjustedHeading = HeadingResolver.markerHeading(from: heading) else {
            return
        }

        guard let mapView = mapView else {
            print("❌ mapView가 nil입니다")
            return
        }

        mapView.mapView.locationOverlay.heading = CGFloat(adjustedHeading)
    }
}

