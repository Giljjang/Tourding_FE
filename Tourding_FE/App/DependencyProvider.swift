//
//  DependencyProvider.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/25/25.
//

import Foundation

struct DependencyProvider {
    static func makeTabViewModels() -> TabViewModelsContainer {
        let repository = TestRepository()
        let homeViewModel = HomeViewModel(testRepository: repository)
        let myPageViewModel = MyPageViewModel()
        let tourRecommendationViewModel = TourRecommendationViewModel()
        
        return TabViewModelsContainer(
            homeViewModel: homeViewModel,
            myPageViewModel: myPageViewModel,
            tourRecommendationViewModel: tourRecommendationViewModel
        )
    }
}
