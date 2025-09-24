//
//  RoutesModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/24/25.
//

import Foundation

struct RoutesModel : Codable {
    let isUsed: Bool
    let duration: Int // 초 단위
    let distance: Int // 미터 단위
}
