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
    
    @Published var toiletList: [FacilityInfoModel] = []
    @Published var csList: [FacilityInfoModel] = []
    
    // MARK: - 지도 관련 프로퍼티
    var locationManager: LocationManager?
    var mapView: NMFMapView?
    
    
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

//MARK: -  Riding 시작하기 중 라이딩 뷰 함수
extension RidingViewModel {
    
    //MARK: - Utils
    func splitCoordinateLatitude(location: String) -> String {
        let parts = location.split(separator: ",")
        return parts.count > 0 ? String(parts[0]).trimmingCharacters(in: .whitespaces) : "0.0"
    }
    
    func splitCoordinateLongitude(location: String) -> String {
        let parts = location.split(separator: ",")
        return parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : "0.0"
    }
    
    static func formatMillisecondsToMinutes(_ milliseconds: Double) -> String {
        let minutes = Int((milliseconds / 1000 / 60).rounded()) // 밀리초 → 분, 정수 반올림
        if minutes == 0 {
            return "" // 0분이면 빈 문자열
        } else {
            return "약 \(minutes)분"
        }
    }
    
    static func insertLineBreakAtMiddleWord(_ text: String) -> String {
        // 22자 이하이면 그대로 반환
        guard text.count > 22 else { return text }
        
        let words = text.split(separator: " ")
        let totalLength = text.count
        let halfLength = totalLength / 2
        
        var currentLength = 0
        var breakIndex = 0
        
        // 중간에 가장 가까운 단어 경계 찾기
        for (i, word) in words.enumerated() {
            currentLength += word.count + 1 // 단어 + 공백
            if currentLength >= halfLength {
                breakIndex = i
                break
            }
        }
        
        let firstPart = words[0...breakIndex].joined(separator: " ")
        let secondPart = words[(breakIndex+1)...].joined(separator: " ")
        
        return firstPart + "\n" + secondPart
    }


    
    //MARK: - View Logic
    // 편의점 토글
    func toggleConvenienceStore(locaion: String){
        showConvenienceStore.toggle()
        
        if showConvenienceStore {
            let lat = splitCoordinateLatitude(location: locaion)
            let lon = splitCoordinateLongitude(location: locaion)
            
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
        } else {
            // 편의점 마커 제거
            csMarkerCoordinates.removeAll()
            csMarkerIcons.removeAll()
            print("편의점 마커 제거됨")
        }
    }

    // 화장실 토글도 동일하게 수정
    func toggleToilet(locaion: String){
        showToilet.toggle()
        
        if showToilet {
            let lat = splitCoordinateLatitude(location: locaion)
            let lon = splitCoordinateLongitude(location: locaion)
            
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
        } else {
            // 화장실 마커 제거
            toiletMarkerCoordinates.removeAll()
            toiletMarkerIcons.removeAll()
            print("화장실 마커 제거됨")
            
        }
    }
    
    //MARK: - API 호출
    @MainActor
    func getRouteGuideAPI() async {
        isLoading = true
        do {
            let response = try await routeRepository.getRoutesGuide(userId: userId)
            guideList = response
            
            //            print("guideList: \(guideList)")
        } catch {
            print("GET ERROR: /routes/guide \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    private func postRoutesToiletAPI(lon: String, lat: String) async {
        isLoading = true
        
        let requestBody: ReqFacilityInfoModel = ReqFacilityInfoModel(lon: lon, lat: lat)
        do {
            toiletList = try await kakaoRepository.postRouteToilet(requestBody: requestBody)
            
            //            print("postRoutesToiletAPI: \(toiletList)")
        } catch {
            print("GET ERROR: /routes/toilet \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    private func postRoutesConvenienceStoreAPI(lon: String, lat: String) async {
        isLoading = true
        
        let requestBody: ReqFacilityInfoModel = ReqFacilityInfoModel(lon: lon, lat: lat)
        do {
            csList = try await kakaoRepository.postRouteConvenienceStore(requestBody: requestBody)
            
            //            print("postRoutesConvenienceStoreAPI: \(csList)")
        } catch {
            print("GET ERROR: /routes/convenience-store \(error)")
        }
        isLoading = false
    }
    
}

