//
//  RecommendRouteViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/19/25.
//

import Foundation
import NMapsMap

final class RecommendRouteViewModel: ObservableObject {
    @Published var userId: Int?
    
    @Published var routeLocation: [LocationNameModel] = []
    @Published var routeMapPaths: [RoutePathModel] = []
    
    // MARK: - 지도 관련 프로퍼티
    var locationManager: LocationManager?
    var userLocationManager: UserLocationManager?
    var mapView: NMFMapView?
    var markerManager: MarkerManager?
    var pathManager: PathManager?
    var mapViewController: RecommendMapViewController?
    
    
    // MARK: - 지도 관련 프로퍼티
    @Published var pathCoordinates: [NMGLatLng] = []
    
    // 기존 마커 (경로 관련)
    @Published var markerCoordinates: [NMGLatLng] = []
    @Published var markerIcons: [NMFOverlayImage] = []
    
    private let tourRepository: TourRepositoryProtocol
    
    init(
        tourRepository: TourRepositoryProtocol) {
            self.tourRepository = tourRepository
    }
    
}
