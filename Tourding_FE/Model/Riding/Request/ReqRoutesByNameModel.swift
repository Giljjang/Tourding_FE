//
//  ReqRoutesByNameModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/24/25.
//

import Foundation

struct ReqRoutesByNameModel: Codable, Equatable {
    let userId: Int
    let start: String
    let goal: String
    /// 검색용(false) / 실제 라이딩용(true) 저장 구분
    let isUsed: Bool
    /// 라이딩 스타일. **서버는 없으면 디폴트로 계산한다** — 저장된 프로필을 꺼내 쓰지 않는다.
    /// 추천 코스도 사용자 스타일로 계산되어야 하므로 반드시 싣는다.
    var routeOption: RouteOptionModel? = nil
}
