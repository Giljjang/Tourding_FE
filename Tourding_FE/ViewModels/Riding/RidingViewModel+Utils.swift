//
//  RidingViewModel+Utils.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import Foundation
import NMapsMap

extension RidingViewModel {
    //MARK: - 라이딩 시작하기 전 Utils
    private func calculateNthLineHeight() {
        nthLineHeight = Double((routeLocation.count * 66) + (routeLocation.count + 1) * 8)
    } // : func calculateNthLineHeight
    
    func matchTitle(_ typeCode: String) -> String {
        switch typeCode {
        case "A01":
            return "자연"
        case "A02":
            return "인문(문화/예술/역사)"
        case "A03":
            return "레포츠"
        case "A04":
            return "쇼핑"
        case "A05":
            return "음식"
        case "B02":
            return "숙박"
        case "C01":
            return "추천코스"
        default:
            return "자연"
        }
    }
    
    //MARK: - 라이딩 중 Utils
    func splitCoordinateLatitude(location: String) -> String {
        let parts = location.split(separator: ",")
        return parts.count > 0 ? String(parts[0]).trimmingCharacters(in: .whitespaces) : "0.0"
    }
    
    func splitCoordinateLongitude(location: String) -> String {
        let parts = location.split(separator: ",")
        return parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : "0.0"
    }
    
    static func insertLineBreakAtMiddleWord(_ text: String) -> String {
        // 22자 이하이면 그대로 반환
        guard text.count > 22 else { return text }
        
        let words = text.split(separator: " ")
        let totalLength = text.count
        let halfLength = totalLength / 2
        
        var currentLength = 0
        var breakIndex = 0
        
        // 중간에 가장 가까운 단어 경계 찾기
        for (i, word) in words.enumerated() {
            currentLength += word.count + 1 // 단어 + 공백
            if currentLength >= halfLength {
                breakIndex = i
                break
            }
        }
        
        let firstPart = words[0...breakIndex].joined(separator: " ")
        let secondPart = words[(breakIndex+1)...].joined(separator: " ")
        
        return firstPart + "\n" + secondPart
    }
    
//    static func formatMillisecondsToMinutes(_ milliseconds: Double) -> String {
//        let minutes = Int((milliseconds / 1000 / 60).rounded()) // 밀리초 → 분, 정수 반올림
//        if minutes == 0 {
//            return "" // 0분이면 빈 문자열
//        } else {
//            return "약 \(minutes)분"
//        }
//    }
    
    static func formatDistance(_ distance: Int) -> String {
        if distance >= 1000 {
            let km = Double(distance) / 1000
            return String(format: "%.1fkm", km) // 1.2km
        } else {
            return "\(distance)m" // 69m
        }
    }
    
    func resolvedGuideType(for item: GuideModel, index: Int, count: Int) -> GuideModel.GuideType {
        if item.guideType == .end, index != count - 1 {
            return .stopOver
        } else {
            return item.guideType ?? .straight
        }
    }

}
