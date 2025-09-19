//
//  KakaoRepository.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/3/25.
//

import Foundation

final class KakaoRepository: KakaoRepositoryProtocol {
    
    static let shared = KakaoRepository()
    
    private init() {}
    
    func postRouteToilet(requestBody: ReqFacilityInfoModel) async throws -> [FacilityInfoModel]{
        let response: [FacilityInfoModel] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/toilet",
            body: requestBody,
            method: "POST",
        )
        
        return response
    }
    
    func postRouteConvenienceStore(requestBody: ReqFacilityInfoModel) async throws -> [FacilityInfoModel]{
        let response: [FacilityInfoModel] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/convenience-store",
            body: requestBody,
            method: "POST",
        )
        
        return response
    }
}
