//
//  SpotSearchModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/28/25.
//

import Foundation

// MARK: - Request
struct SpotSearchRequest: Codable {
    let pageNum: Int
    let mapX: String
    let mapY: String
    let radius: String
    let typeCode: String
}

// request: 기본값 적용(typeCode "0", areaCode 0)
struct TourKeywordRequest: Codable {
    let keyword: String
    let pageNum: Int
    let typeCode: String
    let areaCode: Int
}

// MARK: - Response
struct SpotData: Codable, Identifiable, Hashable {
    let id = UUID()
    let title: String
    let addr1: String
    let typeCode: String
    let contentid: String
    let contenttypeid: String
    let firstimage: String
    let firstimage2: String
    let mapx: String
    let mapy: String
    
    private enum CodingKeys: String, CodingKey {
        case title, addr1, typeCode, contentid, contenttypeid
        case firstimage, firstimage2, mapx, mapy
    }
}
