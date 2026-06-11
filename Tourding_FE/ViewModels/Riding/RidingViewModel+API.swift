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
    func getRoutesTotalAPI() async {
        guard let userId = userId else {
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
    func getRouteLocationAPI(isRecommend: Bool? = nil) async {
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
                // isRecommend가 nil이 아닐 때는 !isRecommend, nil일 때는 self.flag 사용
                let isUsed = isRecommend != nil ? !isRecommend! : self.flag
                
                let response = try await routeRepository.getRoutesLocationName(userId: userId, isUsed: isUsed)
                routeLocation = response
                applyRouteLocationMarkers(from: response)
                
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
                let response = try await routeRepository.getRoutesPath(userId: userId, isUsed: self.flag)
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
        
        // contentIds (0, last 제외 + 선택된 데이터 삭제)
        let middleContentsid = originalData.dropFirst().dropLast().filter { $0.contentId != selectedData.contentId }
        let contentIdArray = middleContentsid.map { "\($0.contentId)" }
        let contentids = contentIdArray.joined(separator: ",")
        
        // contentTypeId (0, last 제외 + 선택된 데이터 삭제)
        let middleContentTypeid = originalData.dropFirst().dropLast().filter { $0.contentTypeId != selectedData.contentTypeId }
        let contentTypeIdArray = middleContentTypeid.map { "\($0.contentTypeId)" }
        let contentTypeids = contentTypeIdArray.joined(separator: ",")
        
        let requestBody = RequestRouteModel(
            userId: userId,
            start: "\(start.lon),\(start.lat)",
            goal: "\(end.lon),\(end.lat)",
            wayPoints: wayPoints,
            locateName: locateName,
            typeCode: typeCode,
            contentId: contentids,
            contentTypeId: contentTypeids,
            isUsed: self.flag
        )
        
        print("requestBody.contentId: \(requestBody.contentId)")
        
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
        
        // contentIds (0, last 제외)
        let middleIds = locationData.dropFirst().dropLast()
        let contentIdsArray = middleIds.map { "\($0.contentId)" }
        let contentsIds = contentIdsArray.joined(separator: ",")
        
        // contentTypeId (0, last 제외)
        let middleTypeIds = locationData.dropFirst().dropLast()
        let contentTypeIdsArray = middleTypeIds.map { "\($0.contentTypeId)" }
        let contentsTypeIds = contentTypeIdsArray.joined(separator: ",")
        
        let requestBody = RequestRouteModel(
            userId: userId,
            start: "\(start.lon),\(start.lat)",
            goal: "\(end.lon),\(end.lat)",
            wayPoints: wayPoints,
            locateName: locateName,
            typeCode: typeCode,
            contentId: contentsIds,
            contentTypeId: contentsTypeIds,
            isUsed: self.flag
        )

        logDragDropPostBody(locationData: locationData, requestBody: requestBody)

        do {
            let _: () = try await routeRepository.postRoutes(requestBody: requestBody)
            isLoading = false
        } catch {
            print("POST ERROR: /routes \(error)")
            isLoading = false
        }
    }

    private func logDragDropPostBody(locationData: [LocationNameModel], requestBody: RequestRouteModel) {
        print("🛣️ [DragDrop] routeLocation: \(locationData.map { "\($0.sequenceNum):\($0.name)" }.joined(separator: " → "))")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsonData = try? encoder.encode(requestBody),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("🛣️ [DragDrop] POST /routes body:\n\(jsonString)")
        }
    }
    
    //MARK: - 라이딩 중 API 호출
    
    // 라이딩이 시작했으니 실제로 길찾기에 사용된 코스를 저장하기 위해 post
    @MainActor
    func postRidingStartAPI(locationData: [LocationNameModel]) async {
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
        
        // contentIds (0, last 제외)
        let middleIds = locationData.dropFirst().dropLast()
        let contentIdsArray = middleIds.map { "\($0.contentId)" }
        let contentsIds = contentIdsArray.joined(separator: ",")
        
        // contentTypeId (0, last 제외)
        let middleTypeIds = locationData.dropFirst().dropLast()
        let contentTypeIdsArray = middleTypeIds.map { "\($0.contentTypeId)" }
        let contentsTypeIds = contentTypeIdsArray.joined(separator: ",")
        
        let requestBody = RequestRouteModel(
            userId: userId,
            start: "\(start.lon),\(start.lat)",
            goal: "\(end.lon),\(end.lat)",
            wayPoints: wayPoints,
            locateName: locateName,
            typeCode: typeCode,
            contentId: contentsIds,
            contentTypeId: contentsTypeIds,
            isUsed: true
        )
        
        print("requestBody.contentId: \(requestBody.contentId)")
        
        do {
            let response: () = try await routeRepository.postRoutes(requestBody: requestBody)
            
            isLoading = false
        } catch {
            print("로그 확인: \(requestBody)")
            print("POST ERROR: /routes \(error)")
        }
    }
    
    // routes/guide & routes/path
    @MainActor
    func getRouteGuideAPI(isNotNormal: Bool?) async {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
        print("🔄 가이드 API 호출 시작 - isNotNormal: \(isNotNormal != nil)")
        
        // 가이드 API 호출 시 로딩 상태 설정
        isStartingRiding = true
        
        // 라이딩 시작 전 원본 데이터 백업 (정상/비정상 종료 모두)
        print("🔄 라이딩 시작 - 원본 데이터 백업")
        
        // 비정상 종료 시에는 기존 데이터가 비어있을 수 있으므로 API 호출 후 백업
        if let isNotNormal = isNotNormal, isNotNormal {
            print("🔄 비정상 종료 감지 - 경로 데이터 재로드 후 백업")
            
            // 경로 데이터 재로드
            do {
                try Task.checkCancellation()
                await getRouteLocationAPI(isRecommend: true) // 이거 추천코스에서 받은 데이터 false일 때 isUsed flase로 설정해서 데이터 받아오고 그걸 post해서 라이딩 시작하기 바로 가능하도록 구현...
                
                try Task.checkCancellation()
                await postRidingStartAPI(locationData: routeLocation) // true로 바꿈
                
                try Task.checkCancellation()
                await getRoutePathAPI()
                
                try Task.checkCancellation()
                await getRouteLocationAPI()
                
                // 데이터 로드 완료 후 백업
                backupOriginalData()
                print("✅ 비정상 종료 복구 - 경로 데이터 재로드 및 백업 완료")
            } catch {
                print("❌ 비정상 종료 복구 실패: \(error)")
                // 실패해도 기존 데이터로 백업 시도
                backupOriginalData()
            }
        } else {
            
            do {
                try Task.checkCancellation()
                await postRidingStartAPI(locationData: routeLocation)
                
                // 정상 시작 시에는 기존 데이터로 바로 백업
                backupOriginalData()
            } catch {
                print("❌ 정상 라이딩 시작시 post 에러: \(error)")
            }
        }
        
        // 재시도 메커니즘 (비정상 종료 시 안정성 강화)
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            do {
                let response = try await routeRepository.getRoutesGuide(userId: userId, isUsed: true)
                guideList = response
                
                print("✅ 가이드 데이터 로드 완료: \(guideList.count)개")
                
                // 기존 마커들을 제거하고 가이드 마커들로 교체
                markerCoordinates = guideList.compactMap { item in
                    if let lat = Double(item.lat), let lon = Double(item.lon) {
                        return NMGLatLng(lat: lat, lng: lon)
                    } else {
                        return nil
                    }
                }
                
                markerIcons = guideList.enumerated().map { (index, item) in
                    switch item.guideType {
                    case .start:
                        return MarkerIcons.startMarker
                    case .end:
                        if index == guideList.count - 1 {
                            return MarkerIcons.goalMarker
                        } else {
                            return MarkerIcons.stopoverMarker
                        }
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
                
                print("✅ 가이드 마커 설정 완료: \(markerCoordinates.count)개")
                
                // 가이드 마커 설정 후 경로선 복원 (경로선이 사라지지 않도록)
                restorePathWithGuides()
                
                // 성공하면 루프 종료
                break
                
            } catch {
                retryCount += 1
                print("❌ 가이드 API 호출 실패 (시도 \(retryCount)/\(maxRetries)): \(error)")
                
                if retryCount < maxRetries {
                    // 재시도 전 잠시 대기
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
                } else {
                    print("❌ 가이드 API 호출 최종 실패")
                    
                    // 비정상 종료 시 가이드 데이터가 없어도 기본 마커 유지
                    if isNotNormal != nil {
                        print("⚠️ 비정상 종료 시 가이드 데이터 없음 - 기본 마커 유지")
                        // 기존 마커 데이터 유지
                    }
                }
            }
        }
        
        // 가이드 API 호출 완료 후 로딩 상태 해제
        isStartingRiding = false
    }
    
    @MainActor
    func postRoutesToiletAPI(lon: String, lat: String) async {
        isLoading = true
        
        let requestBody: ReqFacilityInfoModel = ReqFacilityInfoModel(lon: lon, lat: lat)
        do {
            toiletList = try await kakaoRepository.postRouteToilet(requestBody: requestBody)
 
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
            
        } catch {
            print("GET ERROR: /routes/convenience-store \(error)")
        }
        isLoading = false
    }
}
