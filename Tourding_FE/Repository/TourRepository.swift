//
//  TourRepository.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/28/25.
//

import Foundation

class TourRepository: TourRepositoryProtocol {
    func searchLocationSpots(pageNum: Int, mapX: String, mapY: String, radius: String) async throws -> [SpotData] {
        let requestBody = SpotSearchRequest(
            pageNum: pageNum,
            mapX: mapX,
            mapY: mapY,
            radius: radius
        )
        
        // NetworkService 직접 활용
        let spots: [SpotData] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/tour/search-location",
            body: requestBody,
            method: "POST"
        )
        
        return spots
    }
}
