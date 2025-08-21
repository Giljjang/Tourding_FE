//
//  HomeViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

final class HomeViewModel: ObservableObject {
    
    // MARK: - Home 화면 전용 상태들
    @Published var abendFlag: Bool = true
    
    // 최근 경로 관련 데이터 (routeContinue 섹션용)
    @Published var recentRoute: RecentRouteData?
    
    private let testRepository: TestRepositoryProtocol
    
    init(testRepository: TestRepositoryProtocol) {
        self.testRepository = testRepository
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
    
    // MARK: - 기존 테스트 관련 메서드 (Home 화면에서 필요한 경우)
    func getTestList() async -> [TestModel] {
        do {
            let tests = try await testRepository.getTest()
            return tests
        } catch {
            return []
        }
    }
}

// MARK: - Home 화면 전용 데이터 모델
struct RecentRouteData {
    let startLocationName: String
    let endLocationName: String
}
