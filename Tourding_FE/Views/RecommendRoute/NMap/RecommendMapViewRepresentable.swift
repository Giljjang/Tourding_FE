//
//  RecommendMapViewRepresentable.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/20/25.
//

import SwiftUI
import UIKit
import NMapsMap
import CoreLocation
import Combine

struct RecommendMapViewRepresentable: UIViewRepresentable {
    
    // MARK: - Properties
    @Binding var pathCoordinates: [NMGLatLng]
    
    @Binding var markerCoordinates: [NMGLatLng]
    @Binding var markerIcons: [NMFOverlayImage]
    
    var recommendRouteViewModel: RecommendRouteViewModel?
    var userLocationManager: LocationManager?
    
    // MARK: - Callbacks
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onMapTap: ((NMGLatLng) -> Void)?
    
    // MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        // ViewController 생성 및 설정
        let mapViewController = RecommendMapViewController()
        mapViewController.pathCoordinates = pathCoordinates
        mapViewController.markerCoordinates = markerCoordinates
        mapViewController.markerIcons = markerIcons
 
        mapViewController.onMapTap = onMapTap
        
        // ridingViewModel 전달
        mapViewController.recommendRouteViewModel = recommendRouteViewModel
        
        // userLocationManager 설정
        if let userLocationManager = userLocationManager {
            mapViewController.setupUserLocationManager(userLocationManager)
        }
        
        
        // ViewController를 containerView에 추가
        context.coordinator.mapViewController = mapViewController
        
        // containerView를 UIViewController로 변환하여 addChild 사용
        let containerViewController = UIViewController()
        containerViewController.view = containerView
        
        context.coordinator.addChild(mapViewController, to: containerViewController)
        containerView.addSubview(mapViewController.view)
        
        // ViewController의 view를 containerView에 맞춤
        mapViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            mapViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mapViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mapViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let mapViewController = context.coordinator.mapViewController else { return }
        
        // 데이터 업데이트
        mapViewController.pathCoordinates = pathCoordinates
        mapViewController.markerCoordinates = markerCoordinates
        mapViewController.markerIcons = markerIcons

        mapViewController.onLocationUpdate = onLocationUpdate
        mapViewController.onMapTap = onMapTap
        
        // RidingViewModel에 LocationManager, NMFMapView, MarkerManager 설정 (viewDidLoad 완료 후)
        if let recommendRouteViewModel = recommendRouteViewModel {
            recommendRouteViewModel.locationManager = mapViewController.locationManager
            if let nmfMapView = mapViewController.nmfMapView {
                recommendRouteViewModel.mapView = nmfMapView
            }
            // MarkerManager 연결
            recommendRouteViewModel.markerManager = mapViewController.markerManager
            // MapViewController 연결
            recommendRouteViewModel.mapViewController = mapViewController
        }
        
        // ridingViewModel 업데이트
        mapViewController.recommendRouteViewModel = recommendRouteViewModel
        
        // userLocationManager 업데이트
        if let userLocationManager = userLocationManager {
            mapViewController.setupUserLocationManager(userLocationManager)
        }
        
        // UI 업데이트
        mapViewController.updateMap()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject {
        var mapViewController: RecommendMapViewController?
        private var parentViewController: UIViewController?
        
        deinit {

            cleanupResources()
        }
        
        private func cleanupResources() {
            // MapViewController 정리
            if let mapViewController = mapViewController {
                removeChild(mapViewController)
            }
            mapViewController = nil
            parentViewController = nil

        }
        
        func addChild(_ child: UIViewController, to parent: UIViewController) {
            parent.addChild(child)
            child.didMove(toParent: parent)
            self.parentViewController = parent
        }
        
        func removeChild(_ child: UIViewController) {
            child.willMove(toParent: nil)
            child.removeFromParent()
        }
    }
}
