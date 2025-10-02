//
//  RecommendNMap.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/20/25.
//

//
//  NMapView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/26/25.
//

import SwiftUI
import NMapsMap
import CoreLocation

struct RecommendNMap: View {
    
    // MARK: - Properties
    @ObservedObject private var recommendRouteViewModel: RecommendRouteViewModel
    @ObservedObject private var userLocationManager: LocationManager
    
    @State private var currentLocation: CLLocation?
    @State private var locationText: String = "위치 정보 없음"
    
    init(recommendRouteViewModel: RecommendRouteViewModel, userLocationManager: LocationManager) {
        self.recommendRouteViewModel = recommendRouteViewModel
        self.userLocationManager = userLocationManager
    }
    
    var body: some View {
            RecommendMapViewRepresentable(
                pathCoordinates: $recommendRouteViewModel.pathCoordinates,
                markerCoordinates: $recommendRouteViewModel.markerCoordinates,
                markerIcons: $recommendRouteViewModel.markerIcons,
                recommendRouteViewModel: recommendRouteViewModel,
                userLocationManager: userLocationManager,
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
        
        recommendRouteViewModel.pathCoordinates.append(newCoordinate)
        
        let marker1 = MarkerIcons.numberMarker(1)
        
        // 마커도 추가 (선택적)
        if Bool.random() {
            recommendRouteViewModel.markerCoordinates.append(newCoordinate)
            recommendRouteViewModel.markerIcons.append(marker1)
        }
    }
}

