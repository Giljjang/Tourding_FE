//
//  MarkerManager.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/26/25.
//

import UIKit
import NMapsMap

final class MarkerManager {
    
    // MARK: - Properties
    private var markers: [NMFMarker] = []
    private weak var mapView: NMFMapView?
    
    // MARK: - Initialization
    init(mapView: NMFMapView) {
        self.mapView = mapView
    }
    
    // MARK: - Public Methods
    func addMarkers(coordinates: [NMGLatLng], icons: [NMFOverlayImage]) {
        clearMarkers()
        
        for (index, coordinate) in coordinates.enumerated() {
            let marker = NMFMarker(position: coordinate)
            let icon = icons[index % icons.count]
            marker.iconImage = icon
            
            // 마커 타입에 따라 크기 설정
            let size = getMarkerSize(for: icon)
            marker.width = size.width
            marker.height = size.height
            marker.anchor = CGPoint(x: 0.5, y: 0.5) // 중앙 기준
            marker.mapView = mapView
            markers.append(marker)
        }
    }
    
    func addMarker(at coordinate: NMGLatLng, icon: NMFOverlayImage) {
        let marker = NMFMarker(position: coordinate)
        marker.iconImage = icon
        
        // 마커 타입에 따라 크기 설정
        let size = getMarkerSize(for: icon)
        marker.width = size.width
        marker.height = size.height
        marker.anchor = CGPoint(x: 0.5, y: 0.5) // 중앙 기준
        marker.mapView = mapView
        markers.append(marker)
    }
    
    func clearMarkers() {
        markers.forEach { $0.mapView = nil }
        markers.removeAll()
    }
    
    func getMarkerCoordinates() -> [NMGLatLng] {
        return markers.map { $0.position }
    }
    
    func getMarkers() -> [NMFMarker] {
        return markers
    }
    
    // MARK: - Helper Methods
    private func getMarkerSize(for icon: NMFOverlayImage) -> CGSize {
        // 마커 타입에 따라 크기 설정
        let markerType = MarkerIcons.getMarkerType(for: icon)
        
        switch markerType {
        case .goalMarker:
            return CGSize(width: 60, height: 60)
        case .startMarker:
            return CGSize(width: 60, height: 60)
            
        case .leftMarker:
            return CGSize(width: 60, height: 60)
        case .rightMarker:
            return CGSize(width: 60, height: 60)
        case .straightMarker:
            return CGSize(width: 60, height: 60)
            
        case .csMarker:
            return CGSize(width: 38, height: 38)
        case .toiletMarker:
            return CGSize(width: 38, height: 38)
            
        case .userMarker:
            return CGSize(width: 60, height: 60) // 사용자 마커
        case .unknown:
            return CGSize(width: 60, height: 60) // 기본 크기
        case .numberMarker:
            return CGSize(width: 21, height: 21)
        }
    }
}

