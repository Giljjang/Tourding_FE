//
//  DependencyProvider.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/25/25.
//

import Foundation

struct DependencyProvider {
    @MainActor static func makeTabViewModels() -> TabViewModelsContainer {
        let RouteRepository = RouteRepository()
        let Tourerepository = TourRepository()
        
        let homeViewModel = HomeViewModel(routeRepository: RouteRepository)
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
    
    @MainActor static func makespotAddViewModel() -> SpotAddViewModel {
        let Tourerepository = TourRepository()
        
        let spotAddViewModel = SpotAddViewModel(tourRepository: Tourerepository)
        return spotAddViewModel
    }
}
