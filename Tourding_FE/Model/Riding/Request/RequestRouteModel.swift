//
//  RequestRouteModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/30/25.
//

import Foundation

/// POST /routes 요청 본문.
///
/// ⚠️ 좌표는 **경도,위도** 순이다.
/// `LocationManager.getCurrentLocationString()`이 만드는 문자열(위도,경도 — 편의시설 API용)과 반대이므로
/// 새 조립부를 쓸 때 혼동하지 말 것. 규약은 `RouteAddRequestTests`가 고정한다.
///
/// `wayPoints`/`typeCode`/`contentId`/`contentTypeId`는 **경유지만** 담으며 개수가 서로 같아야 한다.
/// `locateName`은 출발·도착을 포함한 전체다.
struct RequestRouteModel: Codable {
    let userId: Int
    let start: String // "경도,위도"
    let goal: String // "경도,위도"
    var wayPoints: String = "" // "경도,위도|경도,위도"
    let locateName: String // "출발,경유,경유,도착"
    let typeCode: String // 경유지 관광 카테고리 코드 "A01,A02"
    let contentId: String // 경유지 콘텐츠 ID "630741,2766859"
    let contentTypeId: String // 경유지 관광타입 "12,39"
    let isUsed: Bool
}
