//
//  RouteRepository.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/31/25.
//

import Foundation

final class RouteRepository: RouteRepositoryProtocol {
    
    static let shared = RouteRepository()
    
    private init() {}
    
    func postRoutes(requestBody: RequestRouteModel) async throws {
        print("🔵 RouteRepository.postRoutes 호출")
        print("🔵 요청 데이터: \(requestBody)")
        
        do{
            print("🔵 NetworkService.request 호출 시작")
            _ = try await NetworkService.request(
                apiType: .main,
                endpoint: "/routes",
                body: requestBody,
                method: "POST"
            ) as EmptyResponse
            print("🔵 NetworkService.request 성공")
        } catch{
            print("❌ RouteRepository.postRoutes 에러: \(error)")
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
