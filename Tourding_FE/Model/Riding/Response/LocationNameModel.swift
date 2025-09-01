//
//  LocationNameModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/31/25.
//

import Foundation

struct LocationNameModel: Codable {
    let sequenceNum: Int
    let name: String
    let type: String
    let typeCode: String
    let lon: String
    let lat: String
}

