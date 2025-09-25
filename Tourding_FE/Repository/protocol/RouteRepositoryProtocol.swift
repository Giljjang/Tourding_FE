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
}
