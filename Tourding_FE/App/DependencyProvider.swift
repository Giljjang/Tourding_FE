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
        let tourRepository = TourRepository.shared
        
        let homeViewModel = HomeViewModel(routeRepository: RouteRepository)
        let myPageViewModel = MyPageViewModel()
        let spotSearchViewModel = SpotSearchViewModel(tourRepository: tourRepository)
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
    
    @MainActor static func makeSpotAddViewModel() -> SpotAddViewModel {
        let tourRepository = TourRepository.shared
        let RouteRepository = RouteRepository.shared
        
        let spotAddViewModel = SpotAddViewModel(
            tourRepository: tourRepository,
            routeRepository: RouteRepository)
        return spotAddViewModel
    }
    
    static func makeRecentSearchViewModel() -> RecentSearchViewModel {
        let makeRecentSearchViewModel = RecentSearchViewModel()
        return makeRecentSearchViewModel
    }
    
    @MainActor static func makeFilterBarViewModel() -> FilterBarViewModel {
        let FilterBarViewModel = FilterBarViewModel(tourRepository: TourRepository.shared)
        return FilterBarViewModel
    }
    
    @MainActor static func makeDetailViewModel() -> DetailSpotViewModel {
        let tourRepository = TourRepository.shared
        let RouteRepository = RouteRepository.shared
        
        return DetailSpotViewModel(
            tourRepository: tourRepository,
            routeRepository: RouteRepository)
    }
    
    static func makeRecommendViewModel() -> RecommendRouteViewModel {
        let tourRepository = TourRepository.shared
        let RouteRepository = RouteRepository.shared
        
        return RecommendRouteViewModel(
            tourRepository: tourRepository,
            routeRepository: RouteRepository)
    }
}
