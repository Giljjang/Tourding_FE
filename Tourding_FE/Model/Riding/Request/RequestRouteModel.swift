//
//  RequestRouteModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/30/25.
//

import Foundation

struct RequestRouteModel {
    let userId: Int
    let start: String //lat,lon
    let goal: String //lat,lon
    var wayPoints: String = "" // "alat,along|blat,blon"
    let locateName: String // "aa,bb,cc,dd"
}
