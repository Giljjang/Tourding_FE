//
//  ReqFacilityInfoModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/3/25.
//

import Foundation

struct ReqFacilityInfoModel: Codable {
    let lon: String
    let lat: String
    let radius: String = "20000"
}
