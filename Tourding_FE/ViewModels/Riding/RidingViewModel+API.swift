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
        logAppliedStyle(bundle)

        // 스타일 화면이 **이 경로에 적용된 값**을 보여주도록 기록한다.
        // 유저 프로필을 보여주면 화면과 실제 경로가 어긋난다.
        editSession.recordAppliedOption(bundle.appliedOption)

        routeTotal = RoutesModel(
            isUsed: bundle.isUsed,
            duration: bundle.duration,
            distance: bundle.distance,
            routeSummaryId: bundle.routeSummaryId
        )
    }

    /// 서버가 **실제로 적용한** 스타일과 그 결과 수치를 찍는다.
    ///
    /// 요청 본문은 `NetworkService`가 이미 통째로 찍으므로(`🔵 Request Body`),
    /// 여기서는 응답 쪽만 본다. 두 줄을 비교하면 셋 중 어디가 문제인지 갈린다 —
    /// 앱이 안 보냈는가 · 서버가 무시했는가 · 반영했는데 경로가 그대로인가.
    ///
    /// 같은 구간을 스타일만 바꿔 두 번 만들어 `[Route]` 줄의 수치를 비교하면
    /// 경로가 실제로 달라졌는지 알 수 있다. 지도만 봐서는 티가 안 난다.
    @MainActor
    private func logAppliedStyle(_ bundle: RouteGuideResponse) {
        #if DEBUG
        print("🚴 [Style] 서버 적용 ← \(bundle.appliedOption?.logDescription ?? "없음 (디폴트로 계산됨)")")

        let km = String(format: "%.2f", bundle.distance / 1000)
        let min = Int(bundle.duration / 60)
        let up = bundle.ascent.map { String(format: "↑%.0fm", $0) } ?? "↑-"
        let down = bundle.descent.map { String(format: "↓%.0fm", $0) } ?? "↓-"
        let score = bundle.preferenceScore.map { String(format: "%.2f", $0) } ?? "-"
        print("🚴 [Route] \(km)km · \(min)분 · \(up) \(down) · 오르막 \(bundle.uphillLevel ?? "-") · 적합도 \(score) · 좌표 \(bundle.paths.count)개")
        #endif
    }

    /// 지금 스타일로 경로를 **다시 계산**한다. 반영에 성공하면 true.
    ///
    /// `GET /routes`는 저장된 경로를 읽을 뿐 재계산하지 않는다.
    /// 스타일을 바꿔도 화면이 그대로였던 원인이 이것이다.
    ///
    /// 응답을 그대로 반영하므로 이어지는 GET이 필요 없다 —
    /// POST 응답에 요약·guides·paths·locations가 모두 담겨 온다.
    @MainActor
    @discardableResult
    func recalculateRouteWithCurrentStyle() async -> Bool {
        guard let userId, routeLocation.count >= 2 else { return false }

        guard let requestBody = RouteRequestBuilder.make(
            from: routeLocation,
            userId: userId,
            isUsed: isUsedRoute,
            routeOption: await profileStore.currentOption(userId: userId)
        ) else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            let bundle = try await routeRepository.postRoutes(requestBody: requestBody)
            applyRouteBundle(bundle)
            print("♻️ 라이딩 스타일 변경 — 경로 재계산 완료")
            return true
        } catch {
            print("❌ 경로 재계산 실패: \(error)")
            return false
        }
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
        
        // 명시 인자 > 추천 코스 흐름(!isRecommend) > 현재 화면이 다루는 경로(isUsedRoute)
        let isUsed = isUsedOverride ?? (isRecommend != nil ? !isRecommend! : self.isUsedRoute)

        let response = await RetryPolicy.run(label: "경로 위치 API") {
            try await self.routeRepository.getRoutesLocationName(userId: userId, isUsed: isUsed)
        }

        if let response {
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
        
        let routeIsUsed = isUsed ?? self.isUsedRoute

        let response = await RetryPolicy.run(label: "경로 경로선 API") {
            try await self.routeRepository.getRoutesPath(userId: userId, isUsed: routeIsUsed)
        }

        if let response {
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

        // 출발·도착이 있어야 경로다
        guard originalData.count >= 2 else {
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

        guard let requestBody = RouteRequestBuilder.make(
            from: survivors,
            userId: userId,
            // 편집 중인 경로의 출처를 따른다. flag는 라이딩 여부일 뿐이라
            // 최근 사용 경로(.recentUsed)를 편집할 때 draft를 덮어쓴다.
            isUsed: routeSource.isUsed,
            routeOption: await profileStore.currentOption(userId: userId)
        ) else {
            print("❌ 경로 본문을 만들 수 없습니다")
            return
        }


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

        // 출발·도착이 있어야 경로다
        guard locationData.count >= 2 else {
            print("❌ 경로 데이터가 부족합니다")
            return
        }

        isLoading = true
        defer { isLoading = false }

        guard let requestBody = RouteRequestBuilder.make(
            from: locationData,
            userId: userId,
            // 편집 중인 경로의 출처를 따른다. flag는 라이딩 여부일 뿐이라
            // 최근 사용 경로(.recentUsed)를 편집할 때 draft를 덮어쓴다.
            isUsed: routeSource.isUsed,
            routeOption: await profileStore.currentOption(userId: userId)
        ) else {
            print("❌ 경로 본문을 만들 수 없습니다")
            return
        }

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

        // 출발·도착이 있어야 경로다
        guard locationData.count >= 2 else {
            print("❌ 경로 데이터가 부족합니다")
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        guard let requestBody = RouteRequestBuilder.make(
            from: locationData,
            userId: userId,
            isUsed: true,
            routeOption: await profileStore.currentOption(userId: userId)
        ) else {
            print("❌ 경로 본문을 만들 수 없습니다")
            return nil
        }


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
