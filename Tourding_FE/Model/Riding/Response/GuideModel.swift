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
    let locationName: String
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
        case roundabout = "교차로"
    }

    /// type 기반으로 GuideType 매핑
    var guideType: GuideType? {
        switch type {
        case 0, 2, 4, 12: // Left / Sharp left / Slight left / Keep left
            return .leftTurn
        case 1, 3, 5, 13: // Right / Sharp right / Slight right / Keep right
            return .rightTurn
        case 6: // Straight
            return .straight
        case 7, 8: // Enter roundabout / Exit roundabout
            return .roundabout
        case 9: // U-turn
            return .stopOver
        case 10: // Goal
            return .end
        case 11: // Depart
            return .start
        default:
            return .straight
        }
    }
    
    /// type 기반으로 가공된 텍스트
    var guideText: String {
        guard let guideType = guideType else { return "" }
        
        switch type {
        case 6: // Straight
            return locationName.isEmpty ? guideType.rawValue : "\(locationName) 방면으로 계속 \(guideType.rawValue)"
        case 12: // Keep left
            return "왼쪽 길로 계속 진행"
        case 13: // Keep right
            return "오른쪽 길로 계속 진행"
        case 7: // Enter roundabout
            return "교차로 진입"
        case 8: // Exit roundabout
            return "교차로 진출"
        case 2: // Sharp left
            return locationName.isEmpty ? "급좌회전" : "\(locationName) 방면으로 급좌회전"
        case 3: // Sharp right
            return locationName.isEmpty ? "급우회전" : "\(locationName) 방면으로 급우회전"
        case 4: // Slight left
            return locationName.isEmpty ? "좌측 방향" : "\(locationName) 방면으로 좌측 방향"
        case 5: // Slight right
            return locationName.isEmpty ? "우측 방향" : "\(locationName) 방면으로 우측 방향"
        case 0, 1: // Left / Right
            return locationName.isEmpty ? guideType.rawValue : "\(locationName) 방면으로 \(guideType.rawValue)"
        default:
            return guideType.rawValue
        }
    }


}



