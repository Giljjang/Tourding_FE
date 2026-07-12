//
//  RouteRepository.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/31/25.
//

import Foundation

final class RouteRepository: RouteRepositoryProtocol {
    
    init() {}
    
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
    
    func getRoutesPath(userId: Int, isUsed: Bool) async throws -> [RoutePathModel]{
        let routePaths: [RoutePathModel] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/path",
            parameters: ["userId": String(userId), "isUsed": String(isUsed)]
        )
        
        return routePaths
    }
    
    func getRoutesLocationName(userId: Int , isUsed: Bool) async throws  -> [LocationNameModel]{
        let routeLocations: [LocationNameModel] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/location-name",
            parameters: ["userId": String(userId), "isUsed": String(isUsed)]
        )
        
        return routeLocations
    }
    
    func getRoutesGuide(userId: Int , isUsed: Bool) async throws  -> [GuideModel]{
        let routeGuides: [GuideModel] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/guide",
            parameters: ["userId": String(userId), "isUsed": String(isUsed)]
        )
        
        return routeGuides
    }
    
    // 경로 총시간, 거리
    func getRoutes(userId: Int, isUsed: Bool) async throws  -> RoutesModel {
        let routesTotal: RoutesModel = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes",
            parameters: ["userId": String(userId), "isUsed": String(isUsed)]
        )
            
        return routesTotal
    }
    
    //추천코스
    func getRoutesRidingRecommend(pageNum:Int) async throws -> [RouteRidingRecommendModel] {
        let routesRecommendList: [RouteRidingRecommendModel] = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/riding-recommend",
            parameters: ["pageNum": String(pageNum)]
        )
        
        return routesRecommendList
    }
    
    func postRoutesByName(requestBody:ReqRoutesByNameModel) async throws -> RoutesModel {
        let routesByName: RoutesModel = try await NetworkService.request(
            apiType: .main,
            endpoint: "/routes/by-name",
            body: requestBody,
            method: "POST"
        )
        
        return routesByName
    }
}
