//
//  RidingSpotModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/6/25.
//

import Foundation

struct RidingSpotModel: Hashable, Identifiable {
    let id: UUID = UUID()
    let name: String
    let themeType: ThemeType
}

enum ThemeType: String, CaseIterable, Codable {
    case nature = "자연"
    case humanities = "인문(문화/예술/역사)"
    case leisureSports = "레포츠"
    case shopping = "쇼핑"
    case food = "음식"
    case accommodation = "숙박"
}
