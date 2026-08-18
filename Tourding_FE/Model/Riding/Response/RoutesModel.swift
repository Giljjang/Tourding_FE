//
//  RoutesModel.swift
//  Tourding_FE
//

import Foundation

struct RoutesModel: Codable {
    let isUsed: Bool
    let duration: Double // 초 단위
    let distance: Double // 미터 단위

    // 변경된 서버 응답(RouteGuideRespDto)의 요약 필드. 옛 응답에는 없으므로 전부 옵셔널.
    let routeSummaryId: Int? // AI 경로 재설정 요청에 필요
    let ascent: Double? // 누적 상승고도
    let descent: Double?
    let uphillLevel: String? // LOW / MEDIUM / HIGH
    let preferenceScore: Double? // 취향 적합도
    let appliedOption: RouteOptionModel?

    init(
        isUsed: Bool,
        duration: Double,
        distance: Double,
        routeSummaryId: Int? = nil,
        ascent: Double? = nil,
        descent: Double? = nil,
        uphillLevel: String? = nil,
        preferenceScore: Double? = nil,
        appliedOption: RouteOptionModel? = nil
    ) {
        self.isUsed = isUsed
        self.duration = duration
        self.distance = distance
        self.routeSummaryId = routeSummaryId
        self.ascent = ascent
        self.descent = descent
        self.uphillLevel = uphillLevel
        self.preferenceScore = preferenceScore
        self.appliedOption = appliedOption
    }
}
