//
//  RouteRidingRecommendModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/24/25.
//

import Foundation

struct RouteRidingRecommendModel: Codable, Hashable {
    let arrival: String
    let description: String
    let minutes: String
    let hours: String
    let departure: String
    let courseType: String
    let courseName: String
}
