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
    func getRoutesTotalAPI(isUsed: Bool? = nil, showsLoading: Bool = true) async {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            return
        }
        
        // 드래그 중 배경 갱신은 오버레이를 띄우지 않는다 — 뜨면 제스처가 끊긴다
        if showsLoading { isLoading = true }
        defer { if showsLoading { isLoading = false } }

        do {
            let routeIsUsed = isUsed ?? self.isUsedRoute
            let response = try await routeRepository.getRoutes(userId: userId, isUsed: routeIsUsed)
            routeTotal = response
            // #region agent log
            DebugSessionLogger.log(
                location: "RidingViewModel+API.swift:getRoutesTotalAPI",
                message: "riding total loaded",
                hypothesisId: "H1",
                data: [
                    "isUsed": String(routeIsUsed),
                    "distance": String(response.distance),
                    "duration": String(response.duration)
                ]
            )
            // #endregion
            
        } catch {
            print("ERRO: GET - \(error)")
        }
    }
    
    /// 번들 응답을 편집 모드 상태로 반영한다 — 요약·경유지·장소 기준 마커·경로선.
    ///
    /// `POST /routes`·`GET /routes`·AI 경로 재설정이 모두 같은 `RouteGuideResponse`를
    /// 돌려주므로 반영 경로를 하나로 둔다.
    /// 요약만 반영한다.
    ///
    /// `routeSummaryId`는 AI 경로 재설정(`/ai/routes/adjustments/*`)의 필수 입력이다.
    /// 라이딩 중에는 draft가 아니라 **사용 중** 경로의 id를 들고 있어야 한다.
    @MainActor
    func applyRouteSummary(_ bundle: RouteGuideResponse) {
        routeTotal = RoutesModel(
            isUsed: bundle.isUsed,
            duration: bundle.duration,
            distance: bundle.distance,
            routeSummaryId: bundle.routeSummaryId
        )
    }

    @MainActor
    func applyRouteBundle(_ bundle: RouteGuideResponse) {
        applyRouteSummary(bundle)

        routeLocation = bundle.locations
        applyRouteLocationMarkers(from: bundle.locations)

        routeMapPaths = bundle.paths
        pathCoordinates = bundle.paths.compactMap { item in
            guard let lat = Double(item.lat), let lon = Double(item.lon) else { return nil }
            return NMGLatLng(lat: lat, lng: lon)
        }

        print("✅ 경로 번들 반영 - 경유지 \(bundle.locations.count)개, 경로선 \(pathCoordinates.count)개")
    }

    /// 라이딩 중 표시용 — 안내(guides) 기준 마커로 교체한다.
    /// **반드시 `backupOriginalData()` 뒤에 부를 것.** 백업에는 장소 기준 마커가 남아야
    /// 라이딩 종료 시 원래대로 복원된다.
    @MainActor
    func applyGuideMarkers(_ guides: [GuideModel]) {
        guideList = guides

        markerCoordinates = guides.compactMap { item in
            guard let lat = Double(item.lat), let lon = Double(item.lon) else { return nil }
            return NMGLatLng(lat: lat, lng: lon)
        }

        markerIcons = guides.enumerated().map { (index, item) in
            switch item.guideType {
            case .start:      return MarkerIcons.startMarker
            case .end:        return index == guides.count - 1 ? MarkerIcons.goalMarker : MarkerIcons.stopoverMarker
            case .leftTurn:   return MarkerIcons.leftMarker
            case .rightTurn:  return MarkerIcons.rightMarker
            case .straight:   return MarkerIcons.straightMarker
            case .stopOver:   return MarkerIcons.stopoverMarker
            case .none:       return MarkerIcons.straightMarker
            case .roundabout: return MarkerIcons.crossingMarker
            }
        }

        print("✅ 가이드 마커 설정 완료: \(markerCoordinates.count)개")
        restorePathWithGuides()
    }

    /// /routes 한 번으로 요약·경유지·경로선을 모두 채운다.
    ///
    /// 이전에는 /routes, /routes/location-name, /routes/path 를 각각 불러 서버가 같은 경로를
    /// 세 번 재계산했다. 응답 하나가 80KB대이고 편집 화면 진입·복귀마다 반복된다.
    ///
    /// 재시도를 두지 않는다. 세 엔드포인트가 연쇄 500을 내는 상황에서 재시도는 부하를 키운다.
    @MainActor
    func loadRouteBundleAPI(isUsed: Bool? = nil) async {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let routeIsUsed = isUsed ?? self.isUsedRoute
            let bundle = try await routeRepository.getRouteBundle(userId: userId, isUsed: routeIsUsed)

            applyRouteBundle(bundle)
        } catch {
            print("ERRO: GET /routes (bundle) - \(error)")
        }
    }

    @MainActor
    func getRouteLocationAPI(isRecommend: Bool? = nil, isUsedOverride: Bool? = nil) async {
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
                // 명시 인자 > 추천 코스 흐름(!isRecommend) > 현재 화면이 다루는 경로(isUsedRoute)
                let isUsed = isUsedOverride ?? (isRecommend != nil ? !isRecommend! : self.isUsedRoute)
                
                let response = try await routeRepository.getRoutesLocationName(userId: userId, isUsed: isUsed)
                routeLocation = response
                applyRouteLocationMarkers(from: response)
                // #region agent log
                DebugSessionLogger.log(
                    location: "RidingViewModel+API.swift:getRouteLocationAPI",
                    message: "riding route locations loaded",
                    hypothesisId: "H1_H4",
                    data: [
                        "isUsed": String(isUsed),
                        "flag": String(flag),
                        "first": response.first?.name ?? "nil",
                        "last": response.last?.name ?? "nil",
                        "count": String(response.count)
                    ]
                )
                // #endregion
                
                // 성공하면 루프 종료
                break
                
            } catch {
                // 500·4xx는 다시 걸어도 같은 답이 온다 (실측: /routes/path 500 3회 연속 동일)
                guard (error as? ErrorType)?.isRetryable ?? true else {
                    print("🚫 재시도하지 않는 에러 - 중단: \(error)")
                    break
                }

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
    func getRoutePathAPI(isUsed: Bool? = nil) async {
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
                let routeIsUsed = isUsed ?? self.isUsedRoute
                let response = try await routeRepository.getRoutesPath(userId: userId, isUsed: routeIsUsed)
                routeMapPaths = response
                // #region agent log
                DebugSessionLogger.log(
                    location: "RidingViewModel+API.swift:getRoutePathAPI",
                    message: "riding path loaded",
                    hypothesisId: "H1",
                    data: [
                        "isUsed": String(routeIsUsed),
                        "pathCount": String(response.count)
                    ]
                )
                // #endregion
                
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
                // 500·4xx는 다시 걸어도 같은 답이 온다 (실측: /routes/path 500 3회 연속 동일)
                guard (error as? ErrorType)?.isRetryable ?? true else {
                    print("🚫 재시도하지 않는 에러 - 중단: \(error)")
                    break
                }

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
        defer { isLoading = false }

        // 삭제 후 남는 항목을 **한 번만** 골라낸다.
        //
        // 이전에는 목록마다 다른 기준으로 걸렀다 — locateName은 name, contentId는 contentId,
        // contentTypeId는 contentTypeId 값으로. 경유지들이 같은 값을 공유하면
        // (추천 코스는 서버가 contentTypeId를 전부 빈 문자열로 내려준다)
        // 선택하지 않은 항목까지 함께 사라져 배열 길이가 어긋났고,
        // 서버가 그 경로를 저장한 뒤 GET /routes/location-name이 500을 반환했다.
        // sequenceNum이 이 경로에서 항목을 식별하는 유일한 키다.
        let survivors = originalData.filter { $0.sequenceNum != selectedData.sequenceNum }
        let remainingWayPoints = survivors.dropFirst().dropLast()

        // wayPoints (0, last 제외)
        let wayPoints = remainingWayPoints
            .map { "\($0.lon),\($0.lat)" }
            .joined(separator: "|")

        // locateName (출발·도착 포함 전체)
        let locateName = survivors
            .map { $0.name }
            .joined(separator: ",")

        // typeCode (0, last 제외)
        let typeCode = remainingWayPoints
            .map { $0.typeCode }
            .joined(separator: ",")

        // contentIds (0, last 제외)
        let contentids = remainingWayPoints
            .map { $0.contentId }
            .joined(separator: ",")

        // contentTypeId (0, last 제외)
        let contentTypeids = remainingWayPoints
            .map { $0.contentTypeId }
            .joined(separator: ",")

        let requestBody = RequestRouteModel(
            userId: userId,
            start: "\(start.lon),\(start.lat)",
            goal: "\(end.lon),\(end.lat)",
            wayPoints: wayPoints,
            locateName: locateName,
            typeCode: typeCode,
            contentId: contentids,
            contentTypeId: contentTypeids,
            isUsed: routeSource.isUsed
        )
        
        print("requestBody.contentId: \(requestBody.contentId)")
        
        do {
            try await routeRepository.postRoutes(requestBody: requestBody)
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
        defer { isLoading = false }

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
            // 편집 중인 경로의 출처를 따른다. flag는 라이딩 여부일 뿐이라
            // 최근 사용 경로(.recentUsed)를 편집할 때 draft를 덮어쓴다.
            isUsed: routeSource.isUsed
        )

        logDragDropPostBody(locationData: locationData, requestBody: requestBody)

        do {
            try await routeRepository.postRoutes(requestBody: requestBody)
        } catch {
            print("POST ERROR: /routes \(error)")
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
    /// 라이딩 시작 POST. 서버가 돌려주는 경로 전체를 반환한다 — 실패 시 nil.
    @MainActor
    @discardableResult
    func postRidingStartAPI(locationData: [LocationNameModel]) async -> RouteGuideResponse? {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            return nil
        }

        guard let start = locationData.first,
              let end = locationData.last else {
            print("❌ 경로 데이터가 부족합니다")
            return nil
        }

        isLoading = true
        defer { isLoading = false }

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
            let response = try await routeRepository.postRoutes(requestBody: requestBody)
            print("✅ 라이딩 시작 POST 완료 - routeSummaryId \(response.routeSummaryId)")
            return response
        } catch {
            print("로그 확인: \(requestBody)")
            print("POST ERROR: /routes \(error)")
            return nil
        }
    }
    
    // routes/guide & routes/path
    @MainActor
    func getRouteGuideAPI(isNotNormal: Bool?) async {
        print("🔄 라이딩 시작 - isNotNormal: \(isNotNormal != nil)")

        // 취소로 중간에 빠져나가도 반드시 내려야 하므로 defer로 묶는다
        isStartingRiding = true
        defer { isStartingRiding = false }

        do {
            // 비정상 종료 후에는 화면 데이터가 비어 있을 수 있어, 무엇을 POST할지 draft에서 먼저 읽는다
            if isNotNormal == true {
                print("🔄 비정상 종료 감지 - draft 재로드")
                try Task.checkCancellation()
                await getRouteLocationAPI(isRecommend: true)
            }

            try Task.checkCancellation()

            // 서버는 이 POST 응답으로 경로 전체(요약·guides·paths·locations)를 돌려준다.
            // 예전에는 이걸 버리고 /routes/path·/routes/location-name·/routes/guide 를
            // 다시 불러 같은 재계산을 반복했다.
            guard let bundle = await postRidingStartAPI(locationData: routeLocation) else {
                print("❌ 라이딩 시작 POST 실패 - 기존 데이터로 백업")
                backupOriginalData()
                return
            }

            // 응답이 도착하는 사이 라이딩이 끝났으면 적용하지 않는다.
            // 적용하면 편집 모드 화면이 가이드 마커로 덮인다.
            if Task.isCancelled {
                print("🚫 라이딩 시작 응답 도착 후 취소 확인 - 적용하지 않음")
                return
            }

            // 비정상 복구는 서버가 방금 만든 경로로 화면을 새로 채운다.
            // 정상 시작은 편집 모드에서 이미 그린 것을 그대로 백업한다.
            if isNotNormal == true {
                // 비정상 복구는 서버가 방금 만든 경로로 화면을 새로 채운다
                applyRouteBundle(bundle)
            } else {
                // 정상 시작은 요약만 갱신한다.
                // 전체를 반영하면 편집 모드에서 사용자가 그린 경유지가 서버 응답으로 덮인다.
                applyRouteSummary(bundle)
            }

            // 순서가 중요하다 — 장소 기준 마커를 백업한 뒤 안내 기준으로 교체한다.
            // 라이딩을 끝내면 restoreOriginalData가 백업본으로 되돌린다.
            backupOriginalData()
            applyGuideMarkers(bundle.guides)

        } catch is CancellationError {
            print("🚫 라이딩 시작 Task 취소됨")
        } catch {
            print("❌ 라이딩 시작 실패: \(error)")
            backupOriginalData()
        }
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
