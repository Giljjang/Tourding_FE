//
//  RouteOptionModel.swift
//  Tourding_FE
//
//  라이딩 스타일. **앱 전체에서 이 타입 하나만 쓴다.**
//
//  같은 값이 세 곳을 오간다 —
//    PUT/GET /user/{id}/riding-profile 의 routeOption (저장된 스타일)
//    POST /routes · /routes/by-name 의 routeOption (이번 경로에 적용할 스타일)
//    응답의 appliedOption (서버가 실제로 적용한 스타일)
//  필드가 똑같은 `RouteOptionDto`가 따로 있던 시절엔 그 사이마다 변환이 필요했다.
//

import Foundation

struct RouteOptionModel: Codable, Equatable {
    let cyclingProfile: String
    let fastRoute: Bool
    let avoidSteps: Bool
    let avoidFords: Bool
    let skillLevel: String
}

extension RouteOptionModel {
    /// 온보딩·설정 화면의 선택값에서 만든다
    init(bikeType: BikeType, skillLevel: RidingSkillLevel, fastRoute: Bool, avoidSteps: Bool, avoidFords: Bool) {
        self.init(
            cyclingProfile: bikeType.apiValue,
            fastRoute: fastRoute,
            avoidSteps: avoidSteps,
            avoidFords: avoidFords,
            skillLevel: skillLevel.apiValue
        )
    }
}
