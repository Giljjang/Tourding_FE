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
}

// MARK: - Response
struct SpotData: Codable, Identifiable {
    let id = UUID()
    let title: String
    let addr1: String
    let contentid: String
    let contenttypeid: String
    let firstimage: String
    let firstimage2: String
    let mapx: String
    let mapy: String
    
    private enum CodingKeys: String, CodingKey {
        case title, addr1, contentid, contenttypeid
        case firstimage, firstimage2, mapx, mapy
    }
}
