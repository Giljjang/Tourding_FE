//
//  DependencyProvider.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/25/25.
//

import Foundation

struct DependencyProvider {
    private static func makeRouteRepository() -> RouteRepositoryProtocol {
        #if DEBUG
        if MockAPIConfiguration.useMockAPI {
            print("🧪 Using MockRouteRepository")
            return MockRouteRepository.shared
        }
        #endif
        return RouteRepository.shared
    }

    private static func makeKakaoRepository() -> KakaoRepositoryProtocol {
        #if DEBUG
        if MockAPIConfiguration.useMockAPI {
            print("🧪 Using MockKakaoRepository")
            return MockKakaoRepository.shared
        }
        #endif
        return KakaoRepository.shared
    }

    @MainActor static func makeTabViewModels() -> TabViewModelsContainer {
        let routeRepository = makeRouteRepository()
        let tourRepository = TourRepository.shared

        let homeViewModel = HomeViewModel(routeRepository: routeRepository)
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
        let ridingViewModel = RidingViewModel(
            routeRepository: makeRouteRepository(),
            kakaoRepository: makeKakaoRepository()
        )
        return ridingViewModel
    }

    static func makeRouteSharedManager() -> RouteSharedManager {
        return RouteSharedManager()
    }

    @MainActor static func makeSpotAddViewModel() -> SpotAddViewModel {
        let tourRepository = TourRepository.shared
        let routeRepository = makeRouteRepository()

        let spotAddViewModel = SpotAddViewModel(
            tourRepository: tourRepository,
            routeRepository: routeRepository)
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
        let routeRepository = makeRouteRepository()

        return DetailSpotViewModel(
            tourRepository: tourRepository,
            routeRepository: routeRepository)
    }

    static func makeRecommendViewModel() -> RecommendRouteViewModel {
        let tourRepository = TourRepository.shared
        let routeRepository = makeRouteRepository()

        return RecommendRouteViewModel(
            tourRepository: tourRepository,
            routeRepository: routeRepository)
    }
}
