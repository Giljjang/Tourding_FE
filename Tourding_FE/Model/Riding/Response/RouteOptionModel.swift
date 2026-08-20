//
//  RouteOptionModel.swift
//  Tourding_FE
//
//  서버가 경로 생성에 실제로 적용한 라이딩 옵션 (appliedOption).
//  온보딩 라이딩 정보 / AI 경로 재설정의 routeOption과 같은 형태다.
//

import Foundation

struct RouteOptionModel: Codable, Equatable {
    let cyclingProfile: String
    let fastRoute: Bool
    let avoidSteps: Bool
    let avoidFords: Bool
    let skillLevel: String
}
