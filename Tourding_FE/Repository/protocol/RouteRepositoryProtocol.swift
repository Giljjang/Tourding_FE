//
//  RouteRepositoryProtocol.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/30/25.
//

import Foundation

protocol RouteRepositoryProtocol {
    func postRoutes(requestBody: RequestRouteModel) async throws
    func getRoutesPath(userId: Int, isUsed: Bool) async throws -> [RoutePathModel]
    func getRoutesLocationName(userId: Int, isUsed: Bool) async throws  -> [LocationNameModel]
    func getRoutesGuide(userId: Int, isUsed: Bool) async throws  -> [GuideModel]
    
    func getRoutes(userId: Int, isUsed: Bool) async throws  -> RoutesModel
    func getRoutesRidingRecommend(pageNum:Int) async throws -> [RouteRidingRecommendModel]
    func postRoutesByName(requestBody:ReqRoutesByNameModel) async throws -> RoutesModel

    /// GET /routes — 요약·가이드·경로선·장소를 한 번에 반환한다.
    /// 개별 엔드포인트를 각각 부르면 서버가 같은 경로를 여러 번 재계산한다.
    func getRouteBundle(userId: Int, isUsed: Bool) async throws -> RouteGuideResponse
}
