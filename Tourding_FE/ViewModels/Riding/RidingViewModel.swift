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
    
    @Published var spotList: [RidingSpotModel]  = []
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
        
        showMockSpotList()
        showMockGuideList()
        
        // spotList 변경 감지 후 nthLineHeight 계산
        $spotList
            .sink { [weak self] _ in
                self?.calculateNthLineHeight()
            }
            .store(in: &cancellables)
        
        // flag 변경 감지
        $flag
            .sink { [weak self] newValue in
                print("flag 변경됨: \(newValue)")
            }
            .store(in: &cancellables)
    }
    
    //MARK: - mock
    private func showMockSpotList(){
        let mock1 = RidingSpotModel(name: "태화강공원", themeType: .humanities)
        let mock2 = RidingSpotModel(name: "어딘가.. 맛있는 곳", themeType: .food)
        
        spotList.insert(contentsOf: [mock1, mock2], at: 0)
        
    } // : func showMockSpotList
    
    private func showMockGuideList(){
        let mock1 = GuideModel(
            sequenceNum: 0,
            distance: 17,
            duration: 6119,
            instructions: "'희망대로659번길' 방면으로 우회전",
            pointIndex: 1,
            type: 3)
        let mock2 = GuideModel(
            sequenceNum: 1,
            distance: 475,
            duration: 157222,
            instructions: "'희망대로' 방면으로 우회전",
            pointIndex: 22,
            type: 3
        )
        
        guideList.append(contentsOf: [mock1, mock2])
    }
    
    //MARK: - util
    private func calculateNthLineHeight() {
        nthLineHeight = Double((spotList.count * 66) + (spotList.count + 1) * 8)
    } // : func calculateNthLineHeight
    
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
        updateToiletMarkers()
    }
    
    func toggleConvenienceStore(){
        showConvenienceStore.toggle()
        updateConvenienceStoreMarkers()
    }
    
    // 화장실 마커 업데이트
    private func updateToiletMarkers() {
        if showToilet {
            // 화장실 마커 추가 (예시 좌표)
            let toiletCoordinates = [
                NMGLatLng(lat: 37.5665, lng: 126.9780),
                NMGLatLng(lat: 37.5668, lng: 126.9785)
            ]
            let toiletIcons = Array(repeating: MarkerIcons.toiletMarker, count: toiletCoordinates.count)
            
            additionalMarkerCoordinates = toiletCoordinates
            additionalMarkerIcons = toiletIcons
        } else {
            // 화장실 마커 제거
            additionalMarkerCoordinates.removeAll()
            additionalMarkerIcons.removeAll()
        }
    }
    
    // 편의점 마커 업데이트
    private func updateConvenienceStoreMarkers() {
        if showConvenienceStore {
            // 편의점 마커 추가 (예시 좌표)
            let csCoordinates = [
                NMGLatLng(lat: 37.5670, lng: 126.9790),
                NMGLatLng(lat: 37.5675, lng: 126.9795)
            ]
            let csIcons = Array(repeating: MarkerIcons.csMarker, count: csCoordinates.count)
            
            // 기존 마커에 추가
            additionalMarkerCoordinates.append(contentsOf: csCoordinates)
            additionalMarkerIcons.append(contentsOf: csIcons)
        } else {
            // 편의점 마커만 제거 (화장실 마커는 유지)
            if showToilet {
                // 화장실 마커만 유지
                let toiletCoordinates = [
                    NMGLatLng(lat: 37.5665, lng: 126.9780),
                    NMGLatLng(lat: 37.5668, lng: 126.9785)
                ]
                let toiletIcons = Array(repeating: MarkerIcons.toiletMarker, count: toiletCoordinates.count)
                
                additionalMarkerCoordinates = toiletCoordinates
                additionalMarkerIcons = toiletIcons
            } else {
                // 모든 추가 마커 제거
                additionalMarkerCoordinates.removeAll()
                additionalMarkerIcons.removeAll()
            }
        }
    }
}

