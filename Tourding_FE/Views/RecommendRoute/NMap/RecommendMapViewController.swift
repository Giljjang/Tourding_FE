//
//  RecommendMapViewController.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/20/25.
//

import SwiftUI
import UIKit
import NMapsMap
import CoreLocation
import Combine

// MARK: - RecommendMapViewController
final class RecommendMapViewController: UIViewController {
    
    // MARK: - Properties
    private var mapView: NMFNaverMapView?
    private let locationButton = UIButton(type: .custom)
    /// ViewModel을 소유하면 안 된다 — 순환이 생겨 화면을 떠나도 지도와 GPS가 살아남는다
    weak var recommendRouteViewModel: RecommendRouteViewModel?
    var userLocationManager: LocationManager?
    
    // MARK: - Data Properties
    var pathCoordinates: [NMGLatLng] = []
    var markerCoordinates: [NMGLatLng] = []
    var markerIcons: [NMFOverlayImage] = []
    
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
    }
    
    deinit {
        print("🗺️ MapViewController deinit 시작")
        cleanupResources()
    }
    
    // MARK: - Cleanup
    private func cleanupResources() {
        // 위치 업데이트 중지
        
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
        recommendRouteViewModel = nil
        
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
        
        // 콜백은 RidingView에서 설정하므로 여기서는 설정하지 않음
        print("🗺️ MapViewController: LocationManager 설정 완료 (콜백은 RidingView에서 설정)")
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
        
        // 경로선 업데이트
        if !pathCoordinates.isEmpty {
            pathManager.setCoordinates(pathCoordinates)
        }
    }
}


