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
            )
    }
    
}

