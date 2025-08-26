//
//  NMapView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/26/25.
//

import SwiftUI
import NMapsMap
import CoreLocation

struct NMapView: View {
    
    // MARK: - State Properties
    @State private var pathCoordinates: [NMGLatLng] = [
        NMGLatLng(lat: 37.5665, lng: 126.9780),
        NMGLatLng(lat: 35.1796, lng: 129.0756),
        NMGLatLng(lat: 35.9078, lng: 127.7669),
        NMGLatLng(lat: 37.4563, lng: 126.7052)
    ]
    
    @State private var markerCoordinates: [NMGLatLng] = [
        NMGLatLng(lat: 37.5665, lng: 126.9780),  // 첫 번째 위치
        NMGLatLng(lat: 35.9078, lng: 127.7669)   // 세 번째 위치
    ]
    
    @State private var markerIcons: [NMFOverlayImage] = [
        MarkerIcons.goalMarker,
        MarkerIcons.startMarker
    ]
    
    @State private var currentLocation: CLLocation?
    @State private var locationText: String = "위치 정보 없음"
    
    var body: some View {
            MapViewRepresentable(
                pathCoordinates: $pathCoordinates,
                markerCoordinates: $markerCoordinates,
                markerIcons: $markerIcons,
                onLocationUpdate: { location in
                    currentLocation = location
                    locationText = "위도: \(location.coordinate.latitude), 경도: \(location.coordinate.longitude)"
                },
                onMapTap: { coordinate in
                    print("지도 탭: \(coordinate.lat), \(coordinate.lng)")
                }
            )
    }
    
    // MARK: - Methods
    private func addNewPathPoint() {
        // 새로운 경로점 추가 (예시: 서울 근처 랜덤 위치)
        let newCoordinate = NMGLatLng(
            lat: 37.33,
            lng: -122.0 + Double.random(in: -0.01...0.01)
        )
        
        pathCoordinates.append(newCoordinate)
        
        let marker1 = MarkerIcons.numberMarker(1)
        
        // 마커도 추가 (선택적)
        if Bool.random() {
            markerCoordinates.append(newCoordinate)
            markerIcons.append(marker1)
        }
    }
}

#Preview {
    NMapView()
}
