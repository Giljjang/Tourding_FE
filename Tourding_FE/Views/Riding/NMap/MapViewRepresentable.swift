//
//  MapViewRepresentable.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/26/25.
//

import SwiftUI
import UIKit
import NMapsMap
import CoreLocation
import Combine

struct MapViewRepresentable: UIViewRepresentable {
    
    // MARK: - Properties
    @Binding var pathCoordinates: [NMGLatLng]
    
    @Binding var markerCoordinates: [NMGLatLng]
    @Binding var markerIcons: [NMFOverlayImage]
    
    @Binding var toiletMarkerCoordinates: [NMGLatLng]
    @Binding var toiletMarkerIcons: [NMFOverlayImage]
    
    @Binding var csMarkerCoordinates: [NMGLatLng]
    @Binding var csMarkerIcons: [NMFOverlayImage]
    
    var ridingViewModel: RidingViewModel?
    var userLocationManager: UserLocationManager?
    
    // MARK: - Callbacks
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onMapTap: ((NMGLatLng) -> Void)?
    
    // MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        // ViewController 생성 및 설정
        let mapViewController = MapViewController()
        mapViewController.pathCoordinates = pathCoordinates
        mapViewController.markerCoordinates = markerCoordinates
        mapViewController.markerIcons = markerIcons
        
        mapViewController.toiletMarkerCoordinates = toiletMarkerCoordinates
        mapViewController.toiletMarkerIcons = toiletMarkerIcons
        
        mapViewController.csMarkerCoordinates = csMarkerCoordinates
        mapViewController.csMarkerIcons = csMarkerIcons
        
        mapViewController.onLocationUpdate = onLocationUpdate
        mapViewController.onMapTap = onMapTap
        
        // ridingViewModel 전달
        mapViewController.ridingViewModel = ridingViewModel
        
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
        mapViewController.toiletMarkerCoordinates = toiletMarkerCoordinates
        mapViewController.toiletMarkerIcons = toiletMarkerIcons
        mapViewController.csMarkerCoordinates = csMarkerCoordinates
        mapViewController.csMarkerIcons = csMarkerIcons
        mapViewController.onLocationUpdate = onLocationUpdate
        mapViewController.onMapTap = onMapTap
        
        // RidingViewModel에 LocationManager와 NMFMapView 설정 (viewDidLoad 완료 후)
        if let ridingViewModel = ridingViewModel {
            ridingViewModel.locationManager = mapViewController.locationManager
            if let nmfMapView = mapViewController.nmfMapView {
                ridingViewModel.mapView = nmfMapView
            }
        }
        
        // ridingViewModel 업데이트
        mapViewController.ridingViewModel = ridingViewModel
        
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
        var mapViewController: MapViewController?
        
        func addChild(_ child: UIViewController, to parent: UIViewController) {
            parent.addChild(child)
            child.didMove(toParent: parent)
        }
        
        func removeChild(_ child: UIViewController) {
            child.willMove(toParent: nil)
            child.removeFromParent()
        }
    }
}
