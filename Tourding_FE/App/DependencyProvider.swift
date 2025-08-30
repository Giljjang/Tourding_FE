//
//  DependencyProvider.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/25/25.
//

import Foundation

struct DependencyProvider {
    @MainActor static func makeTabViewModels() -> TabViewModelsContainer {
        let repository = TestRepository()
        let Tourerepository = TourRepository()
        
        let homeViewModel = HomeViewModel(testRepository: repository)
        let myPageViewModel = MyPageViewModel()
        let spotSearchViewModel = SpotSearchViewModel(tourRepository: Tourerepository)
        let dsViewModel = DestinationSearchViewModel()
        
        return TabViewModelsContainer(
            homeViewModel: homeViewModel,
            myPageViewModel: myPageViewModel,
            spotSearchViewModel: spotSearchViewModel,
            dsViewModel: dsViewModel
        )
    }
    
    static func makeRidingViewModel() -> RidingViewModel {
        let ridingViewModel = RidingViewModel()
        
        return ridingViewModel
    }
    static func makeRouteSharedManager() -> RouteSharedManager {
        return RouteSharedManager()
    }
}
