//
//  TourRepository.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/28/25.
//

import Foundation

class TourRepository: TourRepositoryProtocol {
    func searchLocationSpots(pageNum: Int, mapX: String, mapY: String, radius: String, typeCode: String) async throws -> [SpotData] {
        let requestBody = SpotSearchRequest(
            pageNum: pageNum,
            mapX: mapX,
            mapY: mapY,
            radius: radius,
            typeCode: typeCode,
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
    
    
    // 키워드 검색
    func searchByKeyword(keyword: String, pageNum: Int, typeCode: String, areaCode: Int) async throws -> [SpotData] {
       let requestBody = TourKeywordRequest(
            keyword: keyword,
            pageNum: pageNum,
            typeCode: typeCode,
            areaCode: areaCode
        )
        
        let spots: [SpotData] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/tour/search-keyword",
            body: requestBody,
            method: "POST"
        )
        return spots
    }
    
    // 상세정보
    func getTourAreaDetail(requestBody: ReqDetailModel) async throws -> ContentDetailModel {
        let detail: ContentDetailModel = try await NetworkService.downloadRequest(
            apiType: .main,
            endpoint: "/tour/area-detail",
            method: "POST",
            body: requestBody
        )
        return detail
    }
}
