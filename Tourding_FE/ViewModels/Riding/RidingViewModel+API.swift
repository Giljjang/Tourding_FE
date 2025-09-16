//
//  RidingViewModel+API.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import Foundation
import NMapsMap

extension RidingViewModel {
    //MARK: - 라이딩 시작하기 전 API 호출
    @MainActor
    func getRouteLocationAPI() async {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
        isLoading = true
        
        // 재시도 메커니즘 (최대 3회)
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            do {
                let response = try await routeRepository.getRoutesLocationName(userId: userId)
                routeLocation = response
//                print("✅ 경로 위치 API 호출 성공: \(routeLocation.count)개")
                
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
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
        isLoading = true
        
        // 재시도 메커니즘 (최대 3회)
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            do {
                let response = try await routeRepository.getRoutesPath(userId: userId)
                routeMapPaths = response
//                print("✅ 경로 경로선 API 호출 성공: \(routeMapPaths.count)개")
                
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
    
    // 드래그앤 드랍 수정시
    @MainActor
    func postRouteDeleteAPI(originalData: [LocationNameModel], selectedData: LocationNameModel) async {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
        guard let start = originalData.first,
              let end = originalData.last else {
            print("❌ 경로 데이터가 부족합니다")
            return
        }
        
        isLoading = true
        
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
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
        guard let start = locationData.first,
              let end = locationData.last else {
            print("❌ 경로 데이터가 부족합니다")
            return
        }
        
        isLoading = true
        
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
            
            // 드래그앤 드랍 후 마커 순서 업데이트
           await updateMarkersAfterDragDrop(locationData: locationData)
            
            isLoading = false
        } catch {
            print("POST ERROR: /routes \(error)")
        }
    }
    
    //MARK: - 라이딩 중 API 호출
    @MainActor
    func getRouteGuideAPI() async {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
//        isLoading = true
        do {
            let response = try await routeRepository.getRoutesGuide(userId: userId)
            guideList = response
            
//            print("guideList: \(guideList)")
            
            // 기존 마커들을 제거하고 가이드 마커들로 교체
            markerCoordinates = guideList.compactMap { item in
                if let lat = Double(item.lat), let lon = Double(item.lon) {
                    return NMGLatLng(lat: lat, lng: lon)
                } else {
                    return nil
                }
            }
            
//            print("markerCoordinates: \(markerCoordinates)")
            
            
            markerIcons = guideList.map { item in
                switch item.guideType {
                case .start:
                    return MarkerIcons.startMarker
                case .end:
                    return MarkerIcons.goalMarker
                case .leftTurn:
                    return MarkerIcons.leftMarker
                case .rightTurn:
                    return MarkerIcons.rightMarker
                case .straight:
                    return MarkerIcons.straightMarker
                case .stopOver:
                    return MarkerIcons.stopoverMarker
                case .none:
                    return MarkerIcons.straightMarker
                case .roundabout:
                    return MarkerIcons.crossingMarker
                }
            }
            
//            print("markerIcons: \(markerIcons)")
            
        } catch {
            print("GET ERROR: /routes/guide \(error)")
        }
//        isLoading = false
    }
    
    @MainActor
    func postRoutesToiletAPI(lon: String, lat: String) async {
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
    func postRoutesConvenienceStoreAPI(lon: String, lat: String) async {
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
