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
        let spotSearchViewModel = SpotSearchViewModel()
        
        return TabViewModelsContainer(
            homeViewModel: homeViewModel,
            myPageViewModel: myPageViewModel,
            spotSearchViewModel: spotSearchViewModel
        )
    }
    
    static func makeRidingViewModel() -> RidingViewModel {
        let ridingViewModel = RidingViewModel()
        return ridingViewModel
    }
    
    static func makeRouteSharedManager() -> RouteSharedManager {
        return RouteSharedManager()
    }
    
    static func makespotAddViewModel() -> SpotAddViewModel {
        let spotAddViewModel = SpotAddViewModel()
        return spotAddViewModel
    }
}
