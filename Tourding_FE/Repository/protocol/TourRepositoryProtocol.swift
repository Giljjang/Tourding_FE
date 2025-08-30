//
//  TourRepositoryProtocol.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/28/25.
//

import Foundation

protocol TourRepositoryProtocol {
    func searchLocationSpots(pageNum: Int, mapX: String, mapY: String, radius: String) async throws -> [SpotData]
}
