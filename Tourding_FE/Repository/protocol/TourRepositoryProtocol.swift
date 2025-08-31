//
//  TourRepositoryProtocol.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/28/25.
//

import Foundation

protocol TourRepositoryProtocol {
    func searchLocationSpots(pageNum: Int, mapX: String, mapY: String, radius: String, typeCode: String) async throws -> [SpotData]
    func searchByKeyword(keyword: String, pageNum: Int, typeCode: String, areaCode: Int) async throws -> [SpotData]
}

