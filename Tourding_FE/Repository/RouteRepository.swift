//
//  RouteRepository.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/31/25.
//

import Foundation

final class RouteRepository: RouteRepositoryProtocol {
    func postRoutes(requestBody: RequestRouteModel) async throws {
        do{
            let response: APIResponse = try await NetworkService.request(
                apiType: .main,
                endpoint: "/routes",
                body: requestBody,
                method: "POST"
            )
        } catch{
            throw error
        }
    }
    
    func getRoutesPath(userId: Int) async throws -> [RoutePathModel]{
        let routePaths: [RoutePathModel] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/path", parameters: ["userId": String(userId)]
        )
        
        return routePaths
    }
    
    func getRoutesLocationName(userId: Int) async throws  -> [LocationNameModel]{
        let routeLocations: [LocationNameModel] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/location-name", parameters: ["userId": String(userId)]
        )
        
        return routeLocations
    }
    
    func getRoutesGuide(userId: Int) async throws  -> [GuideModel]{
        let routeGuides: [GuideModel] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/guide", parameters: ["userId": String(userId)]
        )
        
        return routeGuides
    }
}
