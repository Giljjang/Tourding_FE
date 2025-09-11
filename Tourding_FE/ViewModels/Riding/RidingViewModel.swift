//
//  RidingViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import Foundation
import NMapsMap

final class RidingViewModel: ObservableObject {
    @Published var userId: Int?
    @Published var isLoading: Bool = false
    @Published var flag: Bool = false // 라이딩 전 <-> 라이딩 후 화면 변경
    
    //라이딩 시작 전
    @Published var routeLocation: [LocationNameModel] = []
    @Published var routeMapPaths: [RoutePathModel] = []
    
    @Published var nthLineHeight: Double = 0 // spotRow 왼쪽 라인 길이
    
    // 라이딩 시작 중
    @Published var showToilet: Bool = false
    @Published var showConvenienceStore: Bool = false
    @Published var guideList: [GuideModel] = []
    
    @Published var toiletList: [FacilityInfoModel] = []
    @Published var csList: [FacilityInfoModel] = []
    
    // MARK: - 지도 관련 프로퍼티
    var locationManager: LocationManager?
    var mapView: NMFMapView?
    var markerManager: MarkerManager?
    var pathManager: PathManager?
    
    
    // MARK: - 지도 관련 프로퍼티
    @Published var pathCoordinates: [NMGLatLng] = []
    
    // 기존 마커 (경로 관련)
    @Published var markerCoordinates: [NMGLatLng] = []
    @Published var markerIcons: [NMFOverlayImage] = []
    
    // 화장실 마커
    @Published var toiletMarkerCoordinates: [NMGLatLng] = []
    @Published var toiletMarkerIcons: [NMFOverlayImage] = []
    
    // 편의점 마커
    @Published var csMarkerCoordinates: [NMGLatLng] = []
    @Published var csMarkerIcons: [NMFOverlayImage] = []
    
    // MARK: - 사용자 위치 추적 관련
    @Published var currentUserLocation: NMGLatLng?
    let markerPassThreshold: Double = 100.0 // 마커를 지나간 것으로 판단하는 거리 (미터)
    
    let routeRepository: RouteRepositoryProtocol
    let kakaoRepository: KakaoRepositoryProtocol
    
    init(routeRepository: RouteRepositoryProtocol,
         kakaoRepository: KakaoRepositoryProtocol
    ) {
        self.routeRepository = routeRepository
        self.kakaoRepository = kakaoRepository
        self.userId = KeychainHelper.loadUid()
    }
    
    // 드래그앤 드랍 후 마커 업데이트 메서드 추가
    @MainActor
    func updateMarkersAfterDragDrop(locationData: [LocationNameModel]) async {
        // 마커 좌표 업데이트
        markerCoordinates = locationData.compactMap { item in
            if let lat = Double(item.lat), let lon = Double(item.lon) {
                return NMGLatLng(lat: lat, lng: lon)
            } else {
                return nil
            }
        }
        
        // 마커 아이콘 순서 업데이트 (새로운 순서 반영)
        markerIcons = locationData.enumerated().map { (index, item) in
            switch item.type {
            case "Start":
                return MarkerIcons.startMarker
            case "Goal":
                return MarkerIcons.goalMarker
            case "WayPoint":
                return MarkerIcons.numberMarker(index) // 새로운 순서의 index 사용
            default:
                return MarkerIcons.numberMarker(0)
            }
        }
        
        print("드래그앤 드랍 후 마커 순서 업데이트 완료: \(markerIcons.count)개")
    }
    
    // 지도 표시 새로고침 (앱 포그라운드 복귀 시 사용)
    @MainActor
    func refreshMapDisplay() {
        print("🔄 지도 표시 새로고침 시작")
        
        // 마커 매니저가 있으면 마커 다시 그리기
        if let markerManager = markerManager {
            markerManager.clearMarkers()
            markerManager.addMarkers(coordinates: markerCoordinates, icons: markerIcons)
            print("✅ 마커 새로고침 완료: \(markerCoordinates.count)개")
        }
        
        // 경로 매니저가 있으면 경로선 다시 그리기
        if let pathManager = pathManager {
            pathManager.clearPath()
            pathManager.setCoordinates(pathCoordinates)
            print("✅ 경로선 새로고침 완료: \(pathCoordinates.count)개")
        }
        
        print("🔄 지도 표시 새로고침 완료")
    }
    
    
}

//MARK: -  Riding 시작하기 중 라이딩 뷰 함수
extension RidingViewModel {
    
    // 편의점 토글
    func toggleConvenienceStore(locaion: String){
        showConvenienceStore.toggle()
        
        if showConvenienceStore {
            updateConvenienceStoreMarkers(location: locaion)
        } else {
            // 편의점 마커  제거
            csMarkerCoordinates.removeAll()
            csMarkerIcons.removeAll()
            print("편의점 마커 제거됨")
        }
    }
    
    // 편의점 마커 업데이트 (토글 없이)
    func updateConvenienceStoreMarkers(location: String) {
        let lat = splitCoordinateLatitude(location: location)
        let lon = splitCoordinateLongitude(location: location)
        
        Task{
            await postRoutesConvenienceStoreAPI(lon: lon, lat: lat)
            
            // API 호출 완료 후 마커 추가 (메인 스레드에서 실행)
            await MainActor.run {
                // 기존 마커는 유지하고 편의점 마커만 추가
                csMarkerCoordinates.removeAll()
                csMarkerIcons.removeAll()
                
                csMarkerCoordinates.append(
                    contentsOf: csList.compactMap { item in
                        if let lat = Double(item.lat), let lon = Double(item.lon) {
                            return NMGLatLng(lat: lat, lng: lon)
                        } else {
                            return nil
                        }
                    }
                )
                
                csMarkerIcons.append(contentsOf: csList.map { _ in
                    MarkerIcons.csMarker
                })
                
                // 디버깅용 로그
                print("편의점 마커 추가됨: \(csMarkerCoordinates.count)개")
                print("편의점 아이콘 추가됨: \(csMarkerIcons.count)개")
            }
        }
    }

    // 화장실 토글도 동일하게 수정
    func toggleToilet(locaion: String){
        showToilet.toggle()
        
        if showToilet {
            updateToiletMarkers(location: locaion)
        } else {
            // 화장실 마커 제거
            toiletMarkerCoordinates.removeAll()
            toiletMarkerIcons.removeAll()
            print("화장실 마커 제거됨")
        }
    }
    
    // 화장실 마커 업데이트 (토글 없이)
    func updateToiletMarkers(location: String) {
        let lat = splitCoordinateLatitude(location: location)
        let lon = splitCoordinateLongitude(location: location)
        
        Task{
            await postRoutesToiletAPI(lon: lon, lat: lat)
            
            // API 호출 완료 후 마커 추가 (메인 스레드에서 실행)
            await MainActor.run {
                // 기존 마커는 유지하고 화장실 마커만 추가
                toiletMarkerCoordinates.removeAll()
                toiletMarkerIcons.removeAll()
                
                toiletMarkerCoordinates.append(
                    contentsOf: toiletList.compactMap { item in
                        if let lat = Double(item.lat), let lon = Double(item.lon) {
                            return NMGLatLng(lat: lat, lng: lon)
                        } else {
                            return nil
                        }
                    }
                )
                
                toiletMarkerIcons.append(contentsOf: toiletList.map { _ in
                    MarkerIcons.toiletMarker
                })
                
                // 디버깅용 로그
                print("화장실 마커 추가됨: \(toiletMarkerCoordinates.count)개")
                print("화장실 아이콘 추가됨: \(toiletMarkerIcons.count)개")
            }
        }
    }
}
