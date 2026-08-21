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
    @Published var abnormalEndFlag: Bool = true
    
    private let routeRepository: RouteRepositoryProtocol
    private let userSession: UserSessionProviding

    /// 라이딩 스타일 공급원. 경로 요청에 실을 값을 여기서 얻는다.
    let profileStore: RidingProfileProviding

    init(routeRepository: RouteRepositoryProtocol,
         userSession: UserSessionProviding,
         profileStore: RidingProfileProviding) {
        self.routeRepository = routeRepository
        self.userSession = userSession
        self.profileStore = profileStore
    }
    
    // MARK: - Home 화면 전용 비즈니스 로직
    
    func isFirstAndLastCoordinateEqual(start: LocationData, end: LocationData) -> Bool {
        
        return start.latitude == end.latitude && start.longitude == end.longitude
    }
    
    //MARK: - API 호출
    @MainActor
    func postRouteAPI(start: LocationData, end: LocationData) async {
        guard let uid = userSession.userId else {
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
            isUsed: false,
            routeOption: await profileStore.currentOption(userId: uid)
        )
        // #region agent log
        DebugSessionLogger.log(
            location: "HomeViewModel.swift:postRouteAPI",
            message: "home course created as draft",
            hypothesisId: "H2",
            data: [
                "startName": start.name,
                "endName": end.name,
                "start": requestBody.start,
                "goal": requestBody.goal,
                "isUsed": String(requestBody.isUsed)
            ]
        )
        // #endregion
        do {
            try await routeRepository.postRoutes(requestBody: requestBody)
        } catch {
            print("POST ERROR:", error)
        }
        isLoading = false
    }
    
    @MainActor
    func getRouteLocationAPI() async {
        
        guard let uid = userSession.userId else {
            print("⏭️ getRouteLocationAPI skipped: userId is nil")
            // 사용자가 없으면 보여줄 최근 경로도 없다.
            // 이전 값을 남기면 로그아웃·탈퇴 후에도 직전 계정의 경로가 홈에 계속 보인다.
            routeLocation = []
            return
        }

        do {
            let response = try await routeRepository.getRoutesLocationName(userId: uid, isUsed: true)
            routeLocation = response
            // #region agent log
            DebugSessionLogger.log(
                location: "HomeViewModel.swift:getRouteLocationAPI",
                message: "home recent route loaded",
                hypothesisId: "H1",
                data: [
                    "isUsed": "true",
                    "first": response.first?.name ?? "nil",
                    "last": response.last?.name ?? "nil",
                    "count": String(response.count)
                ]
            )
            // #endregion
        } catch {
            print("GET ERROR:", error)
        }
    }
    
    // 추천코스 (userId 불필요 — 로그인 직후 uid 저장 전에도 호출 가능)
    @MainActor
    func getRouteRecommendAPI() async {
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
    /// 추천 코스를 사용자의 draft 경로로 저장하고, **성공 여부**를 돌려준다.
    ///
    /// 추천 코스는 서버에 따로 저장되지 않는다. 이 요청이 draft 슬롯을 덮어쓰는데,
    /// 그 자리는 사용자가 직접 만든 코스와 같다. 저장에 실패했는데 화면을 넘기면
    /// 다음 화면이 draft를 읽어 **옛 코스를 추천 코스인 양 보여준다.**
    /// 그래서 호출부는 이 값이 true일 때만 이동해야 한다.
    @discardableResult
    func postRouteByNameAPI(start: String, goal: String) async -> Bool {
        guard let uid = userSession.userId else {
            print("⏭️ postRouteByNameAPI skipped: userId is nil")
            return false
        }

        isLoading = true
        defer { isLoading = false }

        let requestBody = ReqRoutesByNameModel(
            userId: uid, start: start, goal: goal, isUsed: false,
            routeOption: await profileStore.currentOption(userId: uid)
        )
        do {
            try await routeRepository.postRoutesByName(requestBody: requestBody)
            return true
        } catch {
            print("POST postRouteByNameAPI ERROR: ", error)
            print("requestBody: ", requestBody)
            return false
        }
    }
}
