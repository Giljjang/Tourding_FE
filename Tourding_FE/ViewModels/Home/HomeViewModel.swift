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
    
    // 최근 경로 관련 데이터 (routeContinue 섹션용)
    @Published var recentRoute: RecentRouteData?
    
    private let routeRepository: RouteRepositoryProtocol
    
    init(routeRepository: RouteRepositoryProtocol) {
        self.routeRepository = routeRepository
        loadRecentRoute()
    }
    
    // MARK: - Home 화면 전용 비즈니스 로직
    
    /// 최근 경로 데이터 로드
    private func loadRecentRoute() {
        // TODO: 실제로는 UserDefaults나 서버에서 최근 경로 가져오기
        recentRoute = RecentRouteData(
            startLocationName: "한동대",
            endLocationName: "영남대"
        )
    }
    
    /// 최근 경로 이어서 가기 기능
    func continueRecentRoute() {
        guard let recent = recentRoute else { return }
        print("🔄 최근 경로 이어서 가기: \(recent.startLocationName) → \(recent.endLocationName)")
        // 라우팅 로직 처리
    }
    
    //MARK: - API 호출
    @MainActor
    func postRouteAPI() async {
        isLoading = true
        let requestBody: RequestRouteModel = RequestRouteModel(
            userId: userId,
            start: "\(routeLocation.first!.lon),\(routeLocation.first!.lat)",
            goal: "\(routeLocation.last!.lon),\(routeLocation.last!.lat)",
            wayPoints: "",
            locateName: "\(routeLocation.first!.name),\(routeLocation.last!.name)"
        )
        
        do {
            let response: () = try await routeRepository.postRoutes(requestBody: requestBody)

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

// MARK: - Home 화면 전용 데이터 모델
struct RecentRouteData {
    let startLocationName: String
    let endLocationName: String
}
