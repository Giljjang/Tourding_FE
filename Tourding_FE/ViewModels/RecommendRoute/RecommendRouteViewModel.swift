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
    @Published var isLoading: Bool = false
    
    @Published var routeLocation: [LocationNameModel] = []
    @Published var routeMapPaths: [RoutePathModel] = []
    @Published var routeTotal: RoutesModel? = nil
    
    // 추천코스에서 받는 데이터
    @Published var routeName: String = ""
    @Published var description: String = ""
    
    // MARK: - 지도 관련 프로퍼티
    //
    // 전부 weak이다. 소유자는 화면이다 — Coordinator가 RecommendMapViewController를
    // 보유하고, updateUIView가 갱신마다 이 여섯 개를 다시 연결한다.
    // strong으로 잡으면 VC와 양방향 순환이 생겨 화면을 pop해도 둘 다 해제되지 않고,
    // VC가 소유한 LocationManager까지 살아남아 GPS가 계속 돈다.
    // 화면에 들어갈 때마다 한 세트씩 쌓인다.
    //
    // 회귀 방지: RecommendMapBindingLifetimeTests
    /// 지도용·위치용 참조를 같은 인스턴스로 맞춘다.
    /// 갈라지면 LocationManager가 두 벌 살아 GPS가 두 개 돈다.
    @MainActor
    func configureLocationManager(_ locationManager: LocationManager) {
        userLocationManager = locationManager
        self.locationManager = locationManager
    }

    weak var locationManager: LocationManager?
    weak var userLocationManager: LocationManager?
    weak var mapView: NMFMapView?
    weak var markerManager: MarkerManager?
    weak var pathManager: PathManager?
    weak var mapViewController: RecommendMapViewController?
    
    
    // MARK: - 지도 관련 프로퍼티
    @Published var pathCoordinates: [NMGLatLng] = []
    
    // 기존 마커 (경로 관련)
    @Published var markerCoordinates: [NMGLatLng] = []
    @Published var markerIcons: [NMFOverlayImage] = []
    
    private let tourRepository: TourRepositoryProtocol
    private let routeRepository: RouteRepositoryProtocol
    
    private let userSession: UserSessionProviding

    init(tourRepository: TourRepositoryProtocol,
         routeRepository: RouteRepositoryProtocol,
         userSession: UserSessionProviding) {
        self.tourRepository = tourRepository
        self.routeRepository = routeRepository
        self.userSession = userSession
    }
    
    // MARK: - 메모리 정리
    func cleanup() {
        // 지도 관련 리소스 정리
        mapView = nil
        locationManager = nil
        userLocationManager = nil
        markerManager = nil
        pathManager = nil
        mapViewController = nil
        
        // 배열 데이터 정리
        routeLocation.removeAll()
        routeMapPaths.removeAll()
        pathCoordinates.removeAll()
        markerCoordinates.removeAll()
        markerIcons.removeAll()
        
        // 사용자 ID 초기화
        userId = nil
    }
    
    deinit {
        cleanup()
    }
    
    //MARK: - API 호출
    @MainActor
    func getRoutesTotalAPI() async {
        guard let userId = userSession.userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
        isLoading = true
        
        do {
            let response = try await routeRepository.getRoutes(userId: userId, isUsed: false)
            routeTotal = response
            
        } catch {
            print("ERRO: GET - \(error)")
        }
        
        isLoading = false
        
    }
    
    @MainActor
    func getRouteLocationAPI() async {
        guard let userId = userSession.userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
        isLoading = true
        
        let response = await RetryPolicy.run(label: "경로 위치 API") {
            try await self.routeRepository.getRoutesLocationName(userId: userId, isUsed: false)
        }

        if let response {
            routeLocation = response

            markerCoordinates = routeLocation.compactMap { item in
                if let lat = Double(item.lat), let lon = Double(item.lon) {
                    return NMGLatLng(lat: lat, lng: lon)
                } else {
                    return nil
                }
            }

            markerIcons = routeLocation.enumerated().map { (index, item) in
                switch item.type {
                case "Start":
                    return MarkerIcons.startMarker
                case "Goal":
                    return MarkerIcons.goalMarker
                case "WayPoint":
                    return MarkerIcons.numberMarker(index) // index 사용
                default:
                    return MarkerIcons.numberMarker(0)
                }
            }
        }

        isLoading = false
    }
    
    //초기 출발지, 도착지만 입력시 POST
    @MainActor
    func getRoutePathAPI() async {
        guard let userId = userSession.userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
        isLoading = true
        
        let response = await RetryPolicy.run(label: "경로 경로선 API") {
            try await self.routeRepository.getRoutesPath(userId: userId, isUsed: false)
        }

        if let response {
            routeMapPaths = response

            pathCoordinates = routeMapPaths.compactMap { item in
                if let lat = Double(item.lat),
                   let lon = Double(item.lon) {
                    return NMGLatLng(lat: lat, lng: lon)
                } else {
                    return nil // 변환 실패 시 무시
                }
            }
        }

        isLoading = false
    }
}
