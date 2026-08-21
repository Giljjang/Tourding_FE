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

extension RouteOptionModel {
    /// 콘솔 대조용 한 줄 표기.
    ///
    /// 라이딩 스타일이 경로에 반영되는지는 **지도만 봐서는 알기 어렵다.**
    /// 보낸 옵션과 서버가 돌려준 `appliedOption`을 이 형식으로 나란히 찍어 비교한다.
    var logDescription: String {
        let toggles = [
            "빠른\(fastRoute ? "O" : "X")",
            "계단회피\(avoidSteps ? "O" : "X")",
            "물길회피\(avoidFords ? "O" : "X")"
        ].joined(separator: " ")
        return "\(cyclingProfile) / \(skillLevel) / \(toggles)"
    }
}
