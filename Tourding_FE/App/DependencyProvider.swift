//
//  DependencyProvider.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/25/25.
//

import Foundation

struct DependencyProvider {
    @MainActor static func makeTabViewModels() -> TabViewModelsContainer {
        let RouteRepository = RouteRepository.shared
        let Tourerepository = TourRepository.shared
        
        let homeViewModel = HomeViewModel(routeRepository: RouteRepository)
        let myPageViewModel = MyPageViewModel()
        let spotSearchViewModel = SpotSearchViewModel(tourRepository: Tourerepository)
        let dsViewModel = DestinationSearchViewModel()
        let recentSearchViewModel = RecentSearchViewModel()
        
        return TabViewModelsContainer(
            homeViewModel: homeViewModel,
            myPageViewModel: myPageViewModel,
            spotSearchViewModel: spotSearchViewModel,
            dsViewModel: dsViewModel,
            recentSearchViewModel: recentSearchViewModel
        )
    }
    
    @MainActor static func makeRidingViewModel() -> RidingViewModel {
        let RouteRepository = RouteRepository.shared
        let KakaoRepository = KakaoRepository.shared
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
        let Tourerepository = TourRepository.shared
        let RouteRepository = RouteRepository.shared
        
        let spotAddViewModel = SpotAddViewModel(
            tourRepository: Tourerepository,
            routeRepository: RouteRepository)
        return spotAddViewModel
    }
    
    static func makeRecentSearchViewModel() -> RecentSearchViewModel {
        let makeRecentSearchViewModel = RecentSearchViewModel()
        return makeRecentSearchViewModel
    }
    
    @MainActor static func makesFilterBarViewModel() -> FilterBarViewModel {
        let FilterBarViewModel = FilterBarViewModel(tourRepository: TourRepository.shared)
        return FilterBarViewModel
    }
    
    @MainActor static func makeDetailViewModel() -> DetailSpotViewModel {
        let Tourerepository = TourRepository.shared
        let RouteRepository = RouteRepository.shared
        
        return DetailSpotViewModel(
            tourRepository: Tourerepository,
            routeRepository: RouteRepository)
    }
    
    static func makeRecommendViewModel() -> RecommendRouteViewModel {
        let Tourerepository = TourRepository.shared
        let RouteRepository = RouteRepository.shared
        
        return RecommendRouteViewModel(
            tourRepository: Tourerepository,
            routeRepository: RouteRepository)
    }
}
