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
        mapViewController.onLocationUpdate = onLocationUpdate
        mapViewController.onMapTap = onMapTap
        
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

// MARK: - MapViewController
class MapViewController: UIViewController {
    
    // MARK: - Properties
    private var mapView: NMFNaverMapView!
    private let locationManager = LocationManager()
    private let locationButton = UIButton(type: .custom)
    private let cancelBag = CancelBag()
    
    // MARK: - Data Properties
    var pathCoordinates: [NMGLatLng] = []
    var markerCoordinates: [NMGLatLng] = []
    var markerIcons: [NMFOverlayImage] = []
    
    // MARK: - Callbacks
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onMapTap: ((NMGLatLng) -> Void)?
    
    // MARK: - Managers
    private var markerManager: MarkerManager!
    private var pathManager: PathManager!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupLocationButton()
        setupLocationManager()
    }
    
    // MARK: - Setup Methods
    private func setupMap() {
        mapView = NMFNaverMapView(frame: view.frame)
        mapView.showLocationButton = false
        mapView.showZoomControls = false
        view.addSubview(mapView)
        
        setupManagers()
    }
    
    private func setupManagers() {
        markerManager = MarkerManager(mapView: mapView.mapView)
        pathManager = PathManager(mapView: mapView.mapView)
    }
    
    private func setupLocationButton() {
        locationButton.setImage(UIImage(named: "myPosition"), for: .normal)
        locationButton.backgroundColor = .white
        locationButton.layer.cornerRadius = 20
//        locationButton.tintColor = .systemBlue
        
        view.addSubview(locationButton)
        
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 60),
            locationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 21),
            locationButton.widthAnchor.constraint(equalToConstant: 40),
            locationButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        locationButton.tapPublisher.sink { [weak self] _ in
            self?.locationManager.moveToCurrentLocation(on: self?.mapView.mapView ?? NMFMapView())
        }.store(in: cancelBag)
    }
    
    private func setupLocationManager() {
        // 위치 업데이트 콜백
        locationManager.onLocationUpdate = { [weak self] location in
            self?.updateUserLocation(location)
            self?.onLocationUpdate?(location)
        }
        
        // 나침반 방향 업데이트 콜백 추가
        locationManager.onHeadingUpdate = { [weak self] heading in
            self?.updateUserLocationBearing(heading)
        }
        
        locationManager.startLocationUpdates()
    }
    
    // MARK: - Public Methods
    func updateMap() {
        // 마커 업데이트
        if !markerCoordinates.isEmpty && !markerIcons.isEmpty {
            markerManager.addMarkers(coordinates: markerCoordinates, icons: markerIcons)
        }
        
        // 경로선 업데이트
        if !pathCoordinates.isEmpty {
            pathManager.setCoordinates(pathCoordinates)
        }
    }
    
    // MARK: - Location Methods
    private func updateUserLocation(_ location: CLLocation) {
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        let locationOverlay = mapView.mapView.locationOverlay
        locationOverlay.hidden = false
        locationOverlay.location = NMGLatLng(lat: lat, lng: lng)
        
        // 사용자 위치 마커를 항상 userMarker으로 설정
        locationOverlay.icon = MarkerIcons.userMarker
        
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: lat, lng: lng))
        cameraUpdate.animation = .easeIn
        
        mapView.mapView.moveCamera(cameraUpdate)
    }
    
    // 나침반 방향 업데이트 메서드 추가
    private func updateUserLocationBearing(_ heading: CLHeading) {
        // 나침반 데이터가 부정확한 경우 무시
        if heading.headingAccuracy < 0 {
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

