//
//  GuideModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/23/25.
//

import Foundation

struct GuideModel: Decodable, Hashable {
    let sequenceNum: Int
    let distance: Int
    let duration: Int
    let instructions: String
    let pointIndex: Int
    let type: Int

    enum GuideType: String {
        case rightTurn = "우회전"
        case leftTurn = "좌회전"
        case straight = "직진"
    }

    // instructions 내용 기반으로 guideType 반환
    var guideType: GuideType? {
        if instructions.contains("우회전") {
            return .rightTurn
        } else if instructions.contains("좌회전") {
            return .leftTurn
        } else if instructions.contains("직진") {
            return .straight
        } else {
            return nil
        }
    }
}


