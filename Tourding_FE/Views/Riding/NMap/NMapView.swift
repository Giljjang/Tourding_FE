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
    
    // MARK: - Properties
    @ObservedObject private var ridingViewModel: RidingViewModel
    @ObservedObject private var userLocationManager: LocationManager
    
    @State private var currentLocation: CLLocation?
    @State private var locationText: String = "위치 정보 없음"
    
    init(ridingViewModel: RidingViewModel, userLocationManager: LocationManager) {
        self.ridingViewModel = ridingViewModel
        self.userLocationManager = userLocationManager
    }
    
    var body: some View {
            MapViewRepresentable(
                pathCoordinates: $ridingViewModel.pathCoordinates,
                markerCoordinates: $ridingViewModel.markerCoordinates,
                markerIcons: $ridingViewModel.markerIcons,
                toiletMarkerCoordinates: $ridingViewModel.toiletMarkerCoordinates,
                toiletMarkerIcons: $ridingViewModel.toiletMarkerIcons,
                csMarkerCoordinates: $ridingViewModel.csMarkerCoordinates,
                csMarkerIcons: $ridingViewModel.csMarkerIcons,
                ridingViewModel: ridingViewModel,
                userLocationManager: userLocationManager,
                onLocationUpdate: { location in
                    currentLocation = location
                    locationText = "위도: \(location.coordinate.latitude), 경도: \(location.coordinate.longitude)"
                },
            )
    }
    
}
