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
    var locationManager: LocationManager?
    var userLocationManager: LocationManager?
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
    private let routeRepository: RouteRepositoryProtocol
    
    init(tourRepository: TourRepositoryProtocol,
         routeRepository: RouteRepositoryProtocol) {
        self.tourRepository = tourRepository
        self.routeRepository = routeRepository
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
        guard let userId = KeychainHelper.loadUid() else {
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
        guard let userId = KeychainHelper.loadUid() else {
            print("❌ userId가 nil입니다")
            return
        }
        
        isLoading = true
        
        // 재시도 메커니즘 (최대 3회)
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            do {
                let response = try await routeRepository.getRoutesLocationName(userId: userId, isUsed: false)
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
                
                // 성공하면 루프 종료
                break
                
            } catch {
                retryCount += 1
                print("❌ 경로 위치 API 호출 실패 (시도 \(retryCount)/\(maxRetries)): \(error)")
                
                if retryCount < maxRetries {
                    // 재시도 전 잠시 대기
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
                } else {
                    print("❌ 경로 위치 API 호출 최종 실패")
                }
            }
        }
        
        isLoading = false
    }
    
    //초기 출발지, 도착지만 입력시 POST
    @MainActor
    func getRoutePathAPI() async {
        guard let userId = KeychainHelper.loadUid() else {
            print("❌ userId가 nil입니다")
            return
        }
        
        isLoading = true
        
        // 재시도 메커니즘 (최대 3회)
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            do {
                let response = try await routeRepository.getRoutesPath(userId: userId, isUsed: false)
                routeMapPaths = response
                
                pathCoordinates = routeMapPaths.compactMap { item in
                    if let lat = Double(item.lat),
                       let lon = Double(item.lon) {
                        return NMGLatLng(lat: lat, lng: lon)
                    } else {
                        return nil // 변환 실패 시 무시
                    }
                }
                
                // 성공하면 루프 종료
                break
                
            } catch {
                retryCount += 1
                print("❌ 경로 경로선 API 호출 실패 (시도 \(retryCount)/\(maxRetries)): \(error)")
                
                if retryCount < maxRetries {
                    // 재시도 전 잠시 대기
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
                } else {
                    print("❌ 경로 경로선 API 호출 최종 실패")
                }
            }
        }
        
        isLoading = false
    }
}
