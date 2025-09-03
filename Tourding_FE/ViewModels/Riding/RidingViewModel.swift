//
//  RidingViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import Foundation
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
    
    private let routeRepository: RouteRepositoryProtocol
    private let kakaoRepository: KakaoRepositoryProtocol
    
    init(routeRepository: RouteRepositoryProtocol,
         kakaoRepository: KakaoRepositoryProtocol
    ) {
        self.routeRepository = routeRepository
        self.kakaoRepository = kakaoRepository
        
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
    
    //초기 출발지, 도착지만 입력시 POST
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
    
    // 드래그앤 드랍 수정시
    @MainActor
    func postRouteDeleteAPI(originalData: [LocationNameModel], selectedData: LocationNameModel) async {
        isLoading = true
        guard let start = originalData.first,
              let end = originalData.last else {
            return
        }
        
        // wayPoints (0, last 제외 + 선택된 데이터 삭제)
        let middlePoints = originalData.dropFirst().dropLast().filter { $0.sequenceNum != selectedData.sequenceNum }
        let wayPointsArray = middlePoints.map { "\($0.lon),\($0.lat)" }
        let wayPoints = wayPointsArray.joined(separator: "|")
        
        // locateName (전체 이름 중 선택된 데이터 삭제)
        let locateNames = originalData.map { $0.name }.filter { $0 != selectedData.name }
        let locateName = locateNames.joined(separator: ",")
        
        // typeCode (0번, 마지막 제외 + 선택된 데이터 삭제)
        let typeCodes = originalData.dropFirst().dropLast()
            .filter { $0.sequenceNum != selectedData.sequenceNum }
            .map { $0.typeCode }
        let typeCode = typeCodes.joined(separator: ",")
        
        let requestBody = RequestRouteModel(
            userId: userId,
            start: "\(start.lon),\(start.lat)",
            goal: "\(end.lon),\(end.lat)",
            wayPoints: wayPoints,
            locateName: locateName,
            typeCode: typeCode
        )
        
        //        print("requestBody: \(requestBody)")
        
        do {
            let response: () = try await routeRepository.postRoutes(requestBody: requestBody)
            isLoading = false
        } catch {
            print("POST ERROR: /routes \(error)")
        }
    }
    
    @MainActor
    func postRouteDragNDropAPI(locationData: [LocationNameModel]) async {
        isLoading = true
        guard let start = locationData.first,
              let end = locationData.last else {
            return
        }
        
        // wayPoints (0, last 제외)
        let middlePoints = locationData.dropFirst().dropLast()
        let wayPointsArray = middlePoints.map { "\($0.lon),\($0.lat)" }
        let wayPoints = wayPointsArray.joined(separator: "|")
        
        // locateName (모두 포함)
        let locateNames = locationData.map { $0.name }
        let locateName = locateNames.joined(separator: ",")
        
        // typeCode (0번, 마지막 제외)
        let typeCodes = locationData.dropFirst().dropLast().map { $0.typeCode }
        let typeCode = typeCodes.joined(separator: ",")
        
        let requestBody = RequestRouteModel(
            userId: userId,
            start: "\(start.lon),\(start.lat)",
            goal: "\(end.lon),\(end.lat)",
            wayPoints: wayPoints,
            locateName: locateName,
            typeCode: typeCode
        )
        
        //    print("requestBody: \(requestBody)")
        
        do {
            let response: () = try await routeRepository.postRoutes(requestBody: requestBody)
            isLoading = false
        } catch {
            print("POST ERROR: /routes \(error)")
        }
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
    
    @MainActor
    func getRouteGuideAPI() async {
        isLoading = true
        do {
            let response = try await routeRepository.getRoutesGuide(userId: userId)
            guideList = response
            
            print("guideList: \(guideList)")
        } catch {
            print("GET ERROR: /routes/guide \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func postRoutesToiletAPI() async {
        isLoading = true
        
        let requestBody: ReqFacilityInfoModel = ReqFacilityInfoModel(lon: "0.0", lat: "0.0")
        do {
            let response = try await kakaoRepository.postRouteToilet(requestBody: requestBody)
            
            print("postRoutesToiletAPI: \(response)")
        } catch {
            print("GET ERROR: /routes/toilet \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func postRoutesConvenienceStoreAPI() async {
        isLoading = true
        
        let requestBody: ReqFacilityInfoModel = ReqFacilityInfoModel(lon: "0.0", lat: "0.0")
        do {
            let response = try await kakaoRepository.postRouteConvenienceStore(requestBody: requestBody)
            
            print("postRoutesConvenienceStoreAPI: \(response)")
        } catch {
            print("GET ERROR: /routes/convenience-store \(error)")
        }
        isLoading = false
    }
    
}

