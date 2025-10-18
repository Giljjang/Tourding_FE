//
//  RoutesModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/24/25.
//

import Foundation

struct RoutesModel : Codable {
    let isUsed: Bool
    let duration: Double // 초 단위
    let distance: Double // 미터 단위
}
