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

    /// 요약·장소·경로선을 **한 번에** 받는다 (GET /routes).
    ///
    /// 예전엔 `getRoutesTotalAPI` → `getRouteLocationAPI` → `getRoutePathAPI`를 순서대로 불러
    /// 서버가 같은 경로를 세 번 계산했다. 셋 다 같은 응답에 담겨 온다.
    ///
    /// 추천 화면은 아직 라이딩 전이므로 draft(`isUsed: false`)를 읽는다.
    /// 실패하면 아무것도 반영하지 않는다 — 옛 코스가 추천 코스 자리에 뜨면 안 된다.
    @MainActor
    func loadRouteBundleAPI() async {
        guard let userId = userSession.userId else {
            print("❌ userId가 nil입니다")
            return
        }

        isLoading = true
        defer { isLoading = false }

        let bundle = await RetryPolicy.run(label: "추천 코스 경로 번들") {
            try await self.routeRepository.getRouteBundle(userId: userId, isUsed: false)
        }

        guard let bundle else {
            print("❌ 추천 코스 경로를 불러오지 못했습니다")
            return
        }

        routeTotal = RoutesModel(
            isUsed: bundle.isUsed,
            duration: bundle.duration,
            distance: bundle.distance,
            routeSummaryId: bundle.routeSummaryId
        )

        routeLocation = bundle.locations
        markerCoordinates = bundle.locations.compactMap { item in
            guard let lat = Double(item.lat), let lon = Double(item.lon) else { return nil }
            return NMGLatLng(lat: lat, lng: lon)
        }
        markerIcons = bundle.locations.enumerated().map { index, item in
            switch item.type {
            case "Start": return MarkerIcons.startMarker
            case "Goal":  return MarkerIcons.goalMarker
            default:      return MarkerIcons.numberMarker(index)
            }
        }

        routeMapPaths = bundle.paths
        pathCoordinates = bundle.paths.compactMap { item in
            guard let lat = Double(item.lat), let lon = Double(item.lon) else { return nil }
            return NMGLatLng(lat: lat, lng: lon)
        }

        print("✅ 추천 코스 번들 반영 - 스팟 \(routeLocation.count)개, 경로선 \(pathCoordinates.count)개")
    }

}
