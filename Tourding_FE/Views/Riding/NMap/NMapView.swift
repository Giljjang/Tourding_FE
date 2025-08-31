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
    
    @State private var currentLocation: CLLocation?
    @State private var locationText: String = "위치 정보 없음"
    
    init(ridingViewModel: RidingViewModel) {
        self.ridingViewModel = ridingViewModel
    }
    
    var body: some View {
            MapViewRepresentable(
                pathCoordinates: $ridingViewModel.pathCoordinates,
                markerCoordinates: $ridingViewModel.markerCoordinates,
                markerIcons: $ridingViewModel.markerIcons,
                ridingViewModel: ridingViewModel,
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
        
        ridingViewModel.pathCoordinates.append(newCoordinate)
        
        let marker1 = MarkerIcons.numberMarker(1)
        
        // 마커도 추가 (선택적)
        if Bool.random() {
            ridingViewModel.markerCoordinates.append(newCoordinate)
            ridingViewModel.markerIcons.append(marker1)
        }
    }
}

#Preview {
    NMapView(ridingViewModel: RidingViewModel(routeRepository: RouteRepository()))
}
