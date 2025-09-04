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
    
    @MainActor static func makeRidingViewModel() -> RidingViewModel {
        let RouteRepository = RouteRepository()
        let KakaoRepository = KakaoRepository()
        let ridingViewModel = RidingViewModel(
            routeRepository: RouteRepository,
            kakaoRepository: KakaoRepository
        )
        return ridingViewModel
    }
    
    static func makeRouteSharedManager() -> RouteSharedManager {
        return RouteSharedManager()
    }
    
    @MainActor static func makespotAddViewModel() -> SpotAddViewModel {
        let Tourerepository = TourRepository()
        let RouteRepository = RouteRepository()
        
        let spotAddViewModel = SpotAddViewModel(
            tourRepository: Tourerepository,
            routeRepository: RouteRepository)
        return spotAddViewModel
    }
    
    @MainActor static func makesFilterBarViewModel() -> FilterBarViewModel {
        let FilterBarViewModel = FilterBarViewModel(tourRepository: TourRepository())
        return FilterBarViewModel
    }
    
    @MainActor static func makeDetailViewModel() -> DetailSpotViewModel {
        let Tourerepository = TourRepository()
        let RouteRepository = RouteRepository()
        
        return DetailSpotViewModel(
            tourRepository: Tourerepository,
            routeRepository: RouteRepository)
    }
}
