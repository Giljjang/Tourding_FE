//
//  KakaoRepositoryProtocol.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/3/25.
//

import Foundation

protocol KakaoRepositoryProtocol {
    func postRouteToilet(requestBody: ReqFacilityInfoModel) async throws -> [FacilityInfoModel]
    func postRouteConvenienceStore(requestBody: ReqFacilityInfoModel) async throws -> [FacilityInfoModel]
}
