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
    @Published var isStartingRiding: Bool = false // 라이딩 시작하기 전용 로딩 상태
    @Published var flag: Bool = false // 라이딩 전 <-> 라이딩 후 화면 변경

    /// 이 화면이 다루는 경로의 출처. 편집 모드 API·재정렬 POST의 `isUsed` 판정 단일 소스.
    /// `handleInitialEntry`에서 1회 저장한다.
    @Published var routeSource: RidingRouteSource = .draft
    
    //라이딩 시작 전
    @Published var routeLocation: [LocationNameModel] = []
    @Published var routeMapPaths: [RoutePathModel] = []
    @Published var routeTotal: RoutesModel? = nil
    
    @Published var nthLineHeight: Double = 0 // spotRow 왼쪽 라인 길이
    
    // 라이딩 시작 중
    @Published var showToilet: Bool = false
    @Published var showConvenienceStore: Bool = false
    @Published var guideList: [GuideModel] = []
    
    @Published var toiletList: [FacilityInfoModel] = []
    @Published var csList: [FacilityInfoModel] = []
    
    // MARK: - 지도 관련 프로퍼티
    //
    // 전부 weak — 소유자는 화면(MapViewController / RidingView의 @StateObject)이고
    // RidingViewModel은 앱 수명 동안 살아 있다. strong으로 잡으면 화면을 떠난 뒤에도
    // MapViewController와 그 CLLocationManager가 해제되지 않아 GPS·지도가 계속 살아남는다.
    weak var locationManager: LocationManager?
    weak var userLocationManager: LocationManager?
    weak var mapView: NMFMapView?
    weak var markerManager: MarkerManager?
    weak var pathManager: PathManager?
    weak var mapViewController: MapViewController?
    
    
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
    let markerPassThreshold: Double = 30.0 // 마커를 지나간 것으로 판단하는 거리 (미터)
    
    let routeRepository: RouteRepositoryProtocol
    let kakaoRepository: KakaoRepositoryProtocol

    /// 경유지 드래그 디바운스 POST Task
    var reorderPersistTask: Task<Void, Never>?

    /// 편의시설 마커 갱신 Task — 화면 이탈·라이딩 종료 시 취소해야 한다
    var toiletMarkerTask: Task<Void, Never>?
    var convenienceStoreMarkerTask: Task<Void, Never>?
    
    let userSession: UserSessionProviding

    init(routeRepository: RouteRepositoryProtocol,
         kakaoRepository: KakaoRepositoryProtocol,
         userSession: UserSessionProviding
    ) {
        self.routeRepository = routeRepository
        self.kakaoRepository = kakaoRepository
        self.userSession = userSession
        self.userId = userSession.userId
    }
    
    // MARK: - 지도 마커 (routeLocation 순서 반영)

    @MainActor
    func applyRouteLocationMarkers(from locationData: [LocationNameModel]) {
        markerCoordinates = locationData.compactMap { item in
            guard let lat = Double(item.lat), let lon = Double(item.lon) else { return nil }
            return NMGLatLng(lat: lat, lng: lon)
        }
        markerIcons = Self.makeMarkerIcons(for: locationData)
    }

    /// 마커 종류·경유지 순번 계산 (순수 함수).
    /// 경유지 번호는 배열 index가 아니라 WayPoint 등장 순서를 따른다.
    static func markerKinds(for locationData: [LocationNameModel]) -> [RouteMarkerKind] {
        var waypointNumber = 0
        return locationData.map { item in
            switch item.type {
            case "Start":
                return .start
            case "Goal":
                return .goal
            case "WayPoint":
                waypointNumber += 1
                return .waypoint(number: waypointNumber)
            default:
                return .unknown
            }
        }
    }

    static func makeMarkerIcons(for locationData: [LocationNameModel]) -> [NMFOverlayImage] {
        markerKinds(for: locationData).map { kind in
            switch kind {
            case .start:
                return MarkerIcons.startMarker
            case .goal:
                return MarkerIcons.goalMarker
            case .waypoint(let number):
                return MarkerIcons.numberMarker(number)
            case .unknown:
                return MarkerIcons.numberMarker(0)
            }
        }
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
    func restoreOriginalData(isStart: Bool) {
        pathCoordinates = originalPathCoordinates
        
        if !isStart {
            markerCoordinates = originalMarkerCoordinates
            markerIcons = originalMarkerIcons
        }
        
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
    @MainActor
    func toggleConvenienceStore(location: String){
        showConvenienceStore.toggle()
        
        if showConvenienceStore {
            updateConvenienceStoreMarkers(location: location)
        } else {
            // 진행 중인 요청을 먼저 취소해야 뒤늦은 응답이 마커를 되살리지 않는다
            convenienceStoreMarkerTask?.cancel()
            convenienceStoreMarkerTask = nil
            csMarkerCoordinates.removeAll()
            csMarkerIcons.removeAll()
            print("편의점 마커 제거됨")
        }
    }
    
    // 편의점 마커 업데이트 (토글 없이)
    @MainActor
    func updateConvenienceStoreMarkers(location: String) {
        let lat = splitCoordinateLatitude(location: location)
        let lon = splitCoordinateLongitude(location: location)

        convenienceStoreMarkerTask?.cancel()
        convenienceStoreMarkerTask = Task { @MainActor in
            await postRoutesConvenienceStoreAPI(lon: lon, lat: lat)
            guard !Task.isCancelled else { return }
            applyConvenienceStoreMarkers()
            print("편의점 마커 추가됨: \(csMarkerCoordinates.count)개")
        }
    }

    /// 좌표와 아이콘을 한 배열에서 파생시켜 개수가 구조적으로 어긋날 수 없게 한다.
    /// (좌표는 compactMap, 아이콘은 map으로 따로 만들면 파싱 실패 항목에서 길이가 틀어진다)
    @MainActor
    func applyToiletMarkers() {
        let coordinates = Self.facilityCoordinates(from: toiletList)
        toiletMarkerCoordinates = coordinates
        toiletMarkerIcons = coordinates.map { _ in MarkerIcons.toiletMarker }
    }

    @MainActor
    func applyConvenienceStoreMarkers() {
        let coordinates = Self.facilityCoordinates(from: csList)
        csMarkerCoordinates = coordinates
        csMarkerIcons = coordinates.map { _ in MarkerIcons.csMarker }
    }

    static func facilityCoordinates(from list: [FacilityInfoModel]) -> [NMGLatLng] {
        list.compactMap { item in
            guard let lat = Double(item.lat), let lon = Double(item.lon) else { return nil }
            return NMGLatLng(lat: lat, lng: lon)
        }
    }

    /// 라이딩 종료·화면 이탈 시 호출. 뒤늦게 끝난 요청이 지운 마커를 되살리는 것을 막는다.
    @MainActor
    func cancelFacilityMarkerTasks() {
        toiletMarkerTask?.cancel()
        toiletMarkerTask = nil
        convenienceStoreMarkerTask?.cancel()
        convenienceStoreMarkerTask = nil
    }

    // 화장실 토글도 동일하게 수정
    @MainActor
    func toggleToilet(location: String){
        showToilet.toggle()
        
        if showToilet {
            updateToiletMarkers(location: location)
        } else {
            // 진행 중인 요청을 먼저 취소해야 뒤늦은 응답이 마커를 되살리지 않는다
            toiletMarkerTask?.cancel()
            toiletMarkerTask = nil
            toiletMarkerCoordinates.removeAll()
            toiletMarkerIcons.removeAll()
            print("화장실 마커 제거됨")
        }
    }
    
    // 화장실 마커 업데이트 (토글 없이)
    @MainActor
    func updateToiletMarkers(location: String) {
        let lat = splitCoordinateLatitude(location: location)
        let lon = splitCoordinateLongitude(location: location)

        toiletMarkerTask?.cancel()
        toiletMarkerTask = Task { @MainActor in
            await postRoutesToiletAPI(lon: lon, lat: lat)
            guard !Task.isCancelled else { return }
            applyToiletMarkers()
            print("화장실 마커 추가됨: \(toiletMarkerCoordinates.count)개")
        }
    }
}
