//
//  OnboardingModels.swift
//  Tourding_FE
//
//  Created by Claude on 8/17/26.
//

import Foundation

enum BikeType: String, CaseIterable, Identifiable {
    case normal = "일반 자전거"
    case electric = "전기 자전거"
    case road = "로드 자전거"
    case mountain = "산악 자전거"

    var id: Self { self }
}

enum RidingSkillLevel: String, CaseIterable, Identifiable {
    case beginner = "입문자"
    case novice = "초보자"
    case skilled = "숙련자"
    case expert = "전문가"

    var id: Self { self }

    var subtitle: String {
        switch self {
        case .beginner: return "천천히 편하게 탈래요"
        case .novice: return "주말마다 근처를 돌아다니는 정도예요"
        case .skilled: return "오르막도 어느 정도 괜찮아요"
        case .expert: return "거리·경사 상관없이 잘 달려요"
        }
    }
}
