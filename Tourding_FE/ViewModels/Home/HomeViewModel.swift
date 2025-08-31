//
//  HomeViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

final class HomeViewModel: ObservableObject {
    //MARK: - 서버 데이터 저장
    @Published var userId: Int = 2
    @Published var routeLocation: [LocationNameModel] = []
    
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
        isLoading = true
        let requestBody: RequestRouteModel = RequestRouteModel(
            userId: userId,
            start: "\(start.longitude),\(start.latitude)",
            goal: "\(end.longitude),\(end.latitude)",
            wayPoints: "",
            locateName: "\(start.name),\(end.name)"
        )
        
        do {
            let response: () = try await routeRepository.postRoutes(requestBody: requestBody)

            isLoading = false
//            print("POST SUCCESS: /routes \(response)")
        } catch {
            print("POST ERROR: /routes \(error)")
        }
    }
    
    @MainActor
    func getRouteLocationAPI() async {
        do {
            let response = try await routeRepository.getRoutesLocationName(userId: userId)
            routeLocation = response
//            print("response : \(routeLocation)")
        } catch {
            print("GET ERROR: /routes/location-name \(error)")
        }
    }
    
}
