//
//  RouteRequestBuilder.swift
//  Tourding_FE
//
//  POST /routes 본문 조립. **다섯 곳에 복붙돼 있던 것을 모았다.**
//
//  복붙이 만든 버그가 세 건이다 — typeCode만 `insert(at: count-1)`이라
//  새 스팟과 마지막 경유지의 카테고리가 뒤바뀌었고(SpotAdd·Detail 양쪽),
//  Detail은 contentTypeId 자리에 contentId를 넣었다.
//
//  계약은 `RouteRequestBuilderTests`가, 두 진입점의 동치는
//  `RouteAddRequestTests.bothEntryPointsProduceIdenticalRequestBody`가 잠근다.
//

import Foundation

enum RouteRequestBuilder {

    /// 경로 목록을 그대로 POST /routes 본문으로 조립한다.
    ///
    /// - `start`/`goal`: 첫·마지막 항목. ⚠️ **경도,위도** 순이다
    ///   (`LocationManager.getCurrentLocationString()`의 위도,경도와 반대)
    /// - `wayPoints`·`typeCode`·`contentId`·`contentTypeId`: **중간만**. 개수가 서로 같아야 한다
    /// - `locateName`: 출발·도착을 포함한 전체
    ///
    /// - Returns: 경로가 비었으면 `nil`. 호출부는 이때 POST를 걸러야 한다.
    static func make(
        from locations: [LocationNameModel],
        userId: Int,
        isUsed: Bool,
        routeOption: RouteOptionModel? = nil
    ) -> RequestRouteModel? {
        guard let start = locations.first, let goal = locations.last else { return nil }

        let middle = locations.dropFirst().dropLast()

        return RequestRouteModel(
            userId: userId,
            start: "\(start.lon),\(start.lat)",
            goal: "\(goal.lon),\(goal.lat)",
            wayPoints: middle.map { "\($0.lon),\($0.lat)" }.joined(separator: "|"),
            locateName: locations.map { $0.name }.joined(separator: ","),
            typeCode: middle.map { $0.typeCode }.joined(separator: ","),
            contentId: middle.map { $0.contentId }.joined(separator: ","),
            contentTypeId: middle.map { $0.contentTypeId }.joined(separator: ","),
            isUsed: isUsed,
            routeOption: routeOption
        )
    }

    /// 새 스팟을 **도착지 앞**에 끼워 넣는다.
    ///
    /// 스팟 추가는 별도 규칙이 아니다 — 여기서 끼운 뒤 `make(from:)`에 넘기면
    /// 그대로 스팟 추가 본문이 된다.
    static func insertingSpotBeforeGoal(
        _ spot: SpotData,
        into locations: [LocationNameModel]
    ) -> [LocationNameModel] {
        let newLocation = LocationNameModel(
            sequenceNum: max(locations.count - 1, 0),
            name: spot.title,
            type: "WayPoint",
            typeCode: spot.typeCode,
            contentId: spot.contentid,
            contentTypeId: spot.contenttypeid,
            lon: spot.mapx,
            lat: spot.mapy
        )

        // 도착지가 없는 경로(항목 1개 이하)는 끼울 자리가 없으니 뒤에 붙인다
        guard locations.count >= 2 else { return locations + [newLocation] }

        var result = locations
        result.insert(newLocation, at: result.count - 1)
        return result
    }
}
