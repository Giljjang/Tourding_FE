//
//  Tourding_FEApp.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

@main
struct Tourding_FEApp: App {
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some Scene {
        
        // 레파지토리 및 뷰모델 의존성 주입
        let repository = TestRepository()
        
        // 탭뷰의 뷰모델은 예외로 3개를 묶어서 뷰로 전달함
        let homeViewModel = HomeViewModel(testRepository: repository)
        let myPageViewModel = MyPageViewModel()
        let tourRecommendationViewModel = TourRecommendationViewModel()

        let viewModels = TabViewModelsContainer(
            homeViewModel: homeViewModel,
            myPageViewModel: myPageViewModel,
            tourRecommendationViewModel: tourRecommendationViewModel
        )
        
        WindowGroup {
            NavigationStack(path: $navigationManager.path) {
                TabContentView(viewModel: viewModels)
                    .navigationDestination(for: ViewType.self) { path in
                        switch path{
                            // case 추가해서 탭뷰 제외 뷰 넣으면 됨
                        default :
                            EmptyView()
                        }
                    } // : navigationDestination
            } // : NavigationStack
            .environmentObject(navigationManager)
        }
    }
}
