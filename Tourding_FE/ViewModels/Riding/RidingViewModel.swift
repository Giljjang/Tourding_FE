//
//  RidingViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import Foundation
import NMapsMap
import SwiftUI
import CoreLocation

final class RidingViewModel: ObservableObject {
    @Published var userId: Int?
    @Published var isLoading: Bool = false
    @Published var isStartingRiding: Bool = false // 라이딩 시작하기 전용 로딩 상태
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
    var userLocationManager: LocationManager?
    var mapView: NMFMapView?
    var markerManager: MarkerManager?
    var pathManager: PathManager?
    var mapViewController: MapViewController?
    
    
    // MARK: - 지도 관련 프로퍼티
    @Published var pathCoordinates: [NMGLatLng] = []
    
    // 기존 마커 (경로 관련)
    @Published var markerCoordinates: [NMGLatLng] = []
    @Published var markerIcons: [NMFOverlayImage] = []
    
    // 라이딩 중 경로선 유지를 위한 백업 데이터
    private var originalPathCoordinates: [NMGLatLng] = []
    private var originalMarkerCoordinates: [NMGLatLng] = []
    private var originalMarkerIcons: [NMFOverlayImage] = []
    
    // 화장실 마커
    @Published var toiletMarkerCoordinates: [NMGLatLng] = []
    @Published var toiletMarkerIcons: [NMFOverlayImage] = []
    
    // 편의점 마커
    @Published var csMarkerCoordinates: [NMGLatLng] = []
    @Published var csMarkerIcons: [NMFOverlayImage] = []
    
    // MARK: - 사용자 위치 추적 관련
    @Published var currentUserLocation: NMGLatLng?
    let markerPassThreshold: Double = 50.0 // 마커를 지나간 것으로 판단하는 거리 (미터)
    
    let routeRepository: RouteRepositoryProtocol
    let kakaoRepository: KakaoRepositoryProtocol
    
    // 앱 생명주기 관련
    @AppStorage("wasLastRunNormal") var wasLastRunNormal: Bool = true
    
    init(routeRepository: RouteRepositoryProtocol,
         kakaoRepository: KakaoRepositoryProtocol
    ) {
        self.routeRepository = routeRepository
        self.kakaoRepository = kakaoRepository
        self.userId = KeychainHelper.loadUid()
        
        // 앱 생명주기 알림 등록
        setupAppLifecycleObservers()
    }
    
    deinit {
        // 알림 해제
        NotificationCenter.default.removeObserver(self)
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
        }
        
        print("🔄 지도 표시 새로고침 완료")
    }
    
    // 라이딩 시작 전 원본 데이터 백업
    @MainActor
    func backupOriginalData() {
        originalPathCoordinates = pathCoordinates
        originalMarkerCoordinates = markerCoordinates
        originalMarkerIcons = markerIcons
        
        print("💾 원본 경로 데이터 백업 완료: 경로선 \(originalPathCoordinates.count)개, 마커 \(originalMarkerCoordinates.count)개")
    }
    
    // 라이딩 중 경로선 복원 (가이드 마커와 함께 표시)
    @MainActor
    func restorePathWithGuides() {
        // 경로선은 원본 데이터로 복원
        pathCoordinates = originalPathCoordinates
        
        // 마커는 가이드 마커 유지 (라이딩 중이므로)
        // pathCoordinates만 복원하여 경로선이 다시 표시되도록 함
        
        // 경로 매니저에 복원된 경로선 적용
        if let pathManager = pathManager {
            pathManager.setCoordinates(pathCoordinates)
            print("🔄 라이딩 중 경로선 복원 완료: \(pathCoordinates.count)개")
        }
    }
    
    // 라이딩 종료 시 원본 데이터로 완전 복원
    @MainActor
    func restoreOriginalData() {
        pathCoordinates = originalPathCoordinates
        markerCoordinates = originalMarkerCoordinates
        markerIcons = originalMarkerIcons
        
        // 지도에 복원된 데이터 적용
        if let pathManager = pathManager {
            pathManager.setCoordinates(pathCoordinates)
        }
        
        if let markerManager = markerManager {
            markerManager.clearMarkers()
            markerManager.addMarkers(coordinates: markerCoordinates, icons: markerIcons)
        }
        
        print("🔄 라이딩 종료 후 원본 데이터 복원 완료")
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
