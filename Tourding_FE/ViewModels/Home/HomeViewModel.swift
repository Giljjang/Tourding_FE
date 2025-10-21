//
//  HomeViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

final class HomeViewModel: ObservableObject {
    //MARK: - 서버 데이터 저장
    @Published var userId: Int?
    @Published var routeLocation: [LocationNameModel] = []
    @Published var routeRecommendList: [RouteRidingRecommendModel] = []
    
    // MARK: - Home 화면 전용 상태들
    @Published var isLoading: Bool = false
    @Published var abendFlag: Bool = true
    
    private let routeRepository: RouteRepositoryProtocol
    
    init(routeRepository: RouteRepositoryProtocol) {
        self.routeRepository = routeRepository
    }
    
    // MARK: - Home 화면 전용 비즈니스 로직
    
    func isFirstAndLastCoordinateEqual(start: LocationData, end: LocationData) -> Bool {
        
        return start.latitude == end.latitude && start.longitude == end.longitude
    }
    
    //MARK: - API 호출
    @MainActor
    func postRouteAPI(start: LocationData, end: LocationData) async {
        guard let uid = KeychainHelper.loadUid()  else {
            print("⏭️ postRouteAPI skipped: userId is nil")
            return
        }
        isLoading = true
        let requestBody = RequestRouteModel(
            userId: uid,
            start: "\(start.longitude),\(start.latitude)",
            goal: "\(end.longitude),\(end.latitude)",
            wayPoints: "",
            locateName: "\(start.name),\(end.name)",
            typeCode: "",
            contentId: "",
            contentTypeId: "",
            isUsed: false
        )
        do {
            try await routeRepository.postRoutes(requestBody: requestBody)
        } catch {
            print("POST ERROR:", error)
        }
        isLoading = false
    }
    
    @MainActor
    func getRouteLocationAPI() async {
        
        guard let uid = KeychainHelper.loadUid() else {
            print("⏭️ getRouteLocationAPI skipped: userId is nil")
            return
        }
        
        do {
            let response = try await routeRepository.getRoutesLocationName(userId: uid, isUsed: true)
            routeLocation = response
        } catch {
            print("GET ERROR:", error)
        }
    }
    
    // 추천코스
    @MainActor
    func getRouteRecommendAPI() async {
        guard let uid = KeychainHelper.loadUid() else {
            print("⏭️ getRouteRecommendAPI skipped: userId is nil")
            return
        }
        
        isLoading = true
        do{
            let response = try await routeRepository.getRoutesRidingRecommend(pageNum: 0)
            routeRecommendList = response
            print("추천코스: \(response)")
            
        } catch {
            print("GET getRouteRecommendAPI ERROR: ", error)
        }
        isLoading = false
    }
    
    @MainActor
    func postRouteByNameAPI(start: String, goal: String) async {
        guard let uid = KeychainHelper.loadUid() else {
            print("⏭️ getRouteRecommendAPI skipped: userId is nil")
            return
        }
        
        isLoading = true
        let requestBody = ReqRoutesByNameModel(userId: uid, start: start, goal: goal)
        do {
            try await routeRepository.postRoutesByName(requestBody: requestBody)
        } catch {
            print("POST postRouteByNameAPI ERROR: ", error)
            print("requestBody: ", requestBody)
        }
        isLoading = false
    }
}
