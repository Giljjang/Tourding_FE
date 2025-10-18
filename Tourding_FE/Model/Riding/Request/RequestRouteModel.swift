//
//  RequestRouteModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/30/25.
//

import Foundation

struct RequestRouteModel: Codable {
    let userId: Int
    let start: String //lat,lon
    let goal: String //lat,lon
    var wayPoints: String = "" // "alat,along|blat,blon"
    let locateName: String // "aa,bb,cc,dd",
    let typeCode: String // "aa,bb"
    let contentId: String // "1,2"
    let contentTypeId: String // "1,2"
    let isUsed: Bool
}
