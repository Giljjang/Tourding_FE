//
//  GuideModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/23/25.
//

import Foundation

struct GuideModel: Codable, Hashable {
    let sequenceNum: Int
    let distance: Int
    let duration: Int
    let instructions: String
    let pointIndex: Int
    let type: Int
    let lon: String
    let lat: String

    enum GuideType: String {
        case rightTurn = "우회전"
        case leftTurn = "좌회전"
        case straight = "직진"
        case stopOver = "경유지"
        case end = "목적지"
        case start = "출발지"
    }

    // instructions 내용 기반으로 guideType 반환
    var guideType: GuideType? {
        if instructions.contains("우회전") || instructions.contains("오른쪽"){
            return .rightTurn
        } else if instructions.contains("좌회전") || instructions.contains("왼쪽") {
            return .leftTurn
        } else if instructions.contains("직진") {
            return .straight
        } else if instructions.contains("경유지") || instructions.contains("유턴") {
            return .stopOver
        } else if instructions.contains("목적지") {
            return .end
        } else if instructions.contains("출발지")  {
            return .start
        }
        else {
            return .straight
        }
    }
}


