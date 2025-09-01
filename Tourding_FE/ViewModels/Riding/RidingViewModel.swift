//
//  RidingViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import Foundation
import Combine
import NMapsMap

final class RidingViewModel: ObservableObject {
    @Published var userId: Int = 2
    @Published var isLoading: Bool = false
    @Published var flag: Bool = false // 라이딩 전 <-> 라이딩 후 화면 변경
    
    //라이딩 시작 전
    @Published var routeLocation: [LocationNameModel] = []
    @Published var routeMapPaths: [RoutePathModel] = []
    
    @Published var nthLineHeight: Double = 0 // spotRow 왼쪽 라인 길이
    
    // 라이딩 시작 후
    @Published var showToilet: Bool = false
    @Published var showConvenienceStore: Bool = false
    @Published var guideList: [GuideModel] = []
    
    // MARK: - 지도 관련 프로퍼티
    var locationManager: LocationManager?
    var mapView: NMFMapView?
    
    
    // MARK: - 지도 관련 프로퍼티
    @Published var pathCoordinates: [NMGLatLng] = []
    
    // 기존 마커 (경로 관련)
    @Published var markerCoordinates: [NMGLatLng] = []
    
    @Published var markerIcons: [NMFOverlayImage] = []
    
    // 추가 마커 (편의시설)
    @Published var additionalMarkerCoordinates: [NMGLatLng] = []
    @Published var additionalMarkerIcons: [NMFOverlayImage] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let routeRepository: RouteRepositoryProtocol
    
    init(routeRepository: RouteRepositoryProtocol) {
        self.routeRepository = routeRepository
        
    }
    
    //MARK: - util
    private func calculateNthLineHeight() {
        nthLineHeight = Double((routeLocation.count * 66) + (routeLocation.count + 1) * 8)
    } // : func calculateNthLineHeight
    
    func matchTitle(_ typeCode: String) -> String {
        switch typeCode {
        case "A01":
            return "자연"
        case "A02":
            return "인문(문화/예술/역사)"
        case "A03":
            return "레포츠"
        case "A04":
            return "쇼핑"
        case "A05":
            return "음식"
        case "B02":
            return "숙박"
        case "C01":
            return "추천코스"
        default:
            return "자연"
        }
    }

    
    //MARK: - API 호출
    @MainActor
    func getRouteLocationAPI() async {
        isLoading = true
        do {
            let response = try await routeRepository.getRoutesLocationName(userId: userId)
            routeLocation = response
            //            print("response : \(routeLocation)")
            
            markerCoordinates = routeLocation.compactMap { item in
                if let lat = Double(item.lat), let lon = Double(item.lon) {
                    return NMGLatLng(lat: lat, lng: lon)
                } else {
                    return nil
                }
            }
            
            markerIcons = routeLocation.map { item in
                switch item.type {
                case "Start":
                    return MarkerIcons.startMarker
                case "Goal":
                    return MarkerIcons.goalMarker
                case "WayPoint":
                    return MarkerIcons.numberMarker(item.sequenceNum)
                default:
                    return MarkerIcons.numberMarker(0)
                }
            }
        } catch {
            print("GET ERROR: /routes/location-name \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func getRoutePathAPI() async {
        isLoading = true
        do {
            let response = try await routeRepository.getRoutesPath(userId: userId)
            routeMapPaths = response
            
            pathCoordinates = routeMapPaths.compactMap { item in
                if let lat = Double(item.lat),
                   let lon = Double(item.lon) {
                    return NMGLatLng(lat: lat, lng: lon)
                } else {
                    return nil // 변환 실패 시 무시
                }
            }
            
        } catch {
            print("GET ERROR: /routes/path \(error)")
        }
        isLoading = false
    }
}

//MARK: -  Riding 시작하기 이후 라이딩 뷰 함수
extension RidingViewModel {
    
    func toggleToilet(){
        showToilet.toggle()
    }
    
    func toggleConvenienceStore(){
        showConvenienceStore.toggle()
    }
}

