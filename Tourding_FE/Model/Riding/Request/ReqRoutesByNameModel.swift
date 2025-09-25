//
//  ReqRoutesByNameModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/24/25.
//

import Foundation

struct ReqRoutesByNameModel: Codable {
    let userId: Int
    let start: String
    let goal: String
}
