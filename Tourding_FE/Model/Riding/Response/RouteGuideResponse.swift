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
}
