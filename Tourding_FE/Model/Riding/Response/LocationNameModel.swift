//
//  LocationNameModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/31/25.
//

import Foundation

struct LocationNameModel: Codable, Hashable {
    let sequenceNum: Int
    let name: String
    let type: String
    let typeCode: String
    let lon: String
    let lat: String
    
    init(sequenceNum: Int, name: String, type: String, typeCode: String, lon: String, lat: String) {
        self.sequenceNum = sequenceNum
        self.name = name
        self.type = type
        self.typeCode = typeCode
        self.lon = lon
        self.lat = lat
    }
}

