//
//  RouteRepositoryProtocol.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/30/25.
//

import Foundation

protocol RouteRepositoryProtocol {
    func postRoutes(requestBody: RequestRouteModel) async throws
    func getRoutesPath(userId: Int) async throws -> [RoutePathModel]
    func getRoutesLocationName(userId: Int) async throws  -> [LocationNameModel]
    func getRoutesGuide(userId: Int) async throws  -> [GuideModel]
}
