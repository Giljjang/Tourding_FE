//
//  SpotSearchModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/28/25.
//

import Foundation

// MARK: - Request Models

/// 스팟 검색 요청 바디
struct SpotSearchRequest: Codable {
    let pageNum: Int
    let mapX: String
    let mapY: String
    let radius: String
}

// MARK: - Response Models

/// 서버 응답 구조
struct SpotSearchResponse: Codable {
    let data: [SpotData]
    let hasNext: Bool
    let totalElements: Int
    
    // 서버 응답에 따라 필드명 조정 필요할 수 있음
}

/// 스팟 데이터 구조 (서버 응답에 맞게 조정)
struct SpotData: Codable, Identifiable {
    let id = UUID() // SwiftUI ForEach용
    let title: String
    let addr1: String
    let contentId: String
    let contentTypeId: String
    let firstImage: String
    let firstImage2: String
    let mapX: String
    let mapY: String
    
    // JSON 키와 Swift 프로퍼티명이 다를 경우 CodingKeys 사용
    private enum CodingKeys: String, CodingKey {
        case title
        case addr1
        case contentId = "contentid"
        case contentTypeId = "contenttypeid"
        case firstImage = "firstimage"
        case firstImage2 = "firstimage2"
        case mapX = "mapx"
        case mapY = "mapy"
    }
}

// MARK: - Additional Models (필요시 추가)

/// 스팟 상세 정보 응답
struct SpotDetailResponse: Codable {
    let data: SpotDetailData
}

/// 스팟 상세 데이터
struct SpotDetailData: Codable {
    let contentId: String
    let title: String
    let addr1: String
    let addr2: String?
    let tel: String?
    let homepage: String?
    let overview: String?
    let firstImage: String
    let firstImage2: String
    let mapX: String
    let mapY: String
    let contentTypeId: String
}

/// 북마크 요청
struct BookmarkRequest: Codable {
    let contentId: String
}

/// 북마크 응답
struct BookmarkResponse: Codable {
    let success: Bool
    let message: String
}
