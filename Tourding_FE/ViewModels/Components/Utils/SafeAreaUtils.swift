//
//  SafeAreaUtils.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/7/25.
//

import SwiftUI

struct SafeAreaUtils {
    
    // 노치 크기에 따른 배율 적용
    // - Parameter topSafeArea: 상단 Safe Area 값
    // - Returns: 배율이 적용된 Safe Area 값
    static func getMultipliedSafeArea(topSafeArea: CGFloat) -> CGFloat {
        switch topSafeArea {
        case 47...: // Dynamic Island (큰 노치)
            return topSafeArea * 1.5
        case 44...46: // 일반 노치 (중간 크기)
            return topSafeArea * 2.0
        case 20...43: // 홈버튼 모델 또는 작은 노치
            return topSafeArea * 2.0
        default:
            return topSafeArea * 2.0
        }
    }
}
