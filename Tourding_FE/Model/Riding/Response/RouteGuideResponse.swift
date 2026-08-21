//
//  RouteGuideResponse.swift
//  Tourding_FE
//
//  서버 RouteGuideRespDto. /routes, /routes/guide, /routes/by-name 이 모두 이 형태를 반환한다.
//

import Foundation

struct RouteGuideResponse: Codable {
    let routeSummaryId: Int
    let isUsed: Bool
    let duration: Double
    let distance: Double
    let guides: [GuideModel]
    let paths: [RoutePathModel]
    let locations: [LocationNameModel]

    // MARK: - 라이딩 스타일 반영 결과
    //
    // **전부 옵셔널이다.** 필드 하나 때문에 응답 전체가 폐기되는 실패를 두 번 겪었다
    // (/routes/guide 형태 변경, 상세의 분류 필드 누락).

    /// 누적 상승(m)
    var ascent: Double? = nil
    /// 누적 하강(m)
    var descent: Double? = nil
    /// 오르막 강도 — LOW / MEDIUM / HIGH
    var uphillLevel: String? = nil
    /// 사용자 스타일과의 적합도
    var preferenceScore: Double? = nil
    /// 서버가 **실제로 적용한** 옵션.
    /// 요청에 routeOption을 안 보냈다면 서버 디폴트가 담긴다 — 사용자 프로필이 아니다.
    var appliedOption: RouteOptionModel? = nil
}
