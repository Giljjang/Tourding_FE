//
//  DependencyProvider.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/25/25.
//

import Foundation

struct DependencyProvider {
    #if DEBUG
    // Mock은 scenario 상태를 뷰모델 간에 공유해야 하므로 단일 인스턴스를 유지한다.
    private static let sharedMockRoute = MockRouteRepository()
    private static let sharedMockKakao = MockKakaoRepository()
    #endif

    private static func makeRouteRepository() -> RouteRepositoryProtocol {
        #if DEBUG
        if MockAPIConfiguration.useMockAPI {
            print("🧪 Using MockRouteRepository")
            return sharedMockRoute
        }
        #endif
        return RouteRepository()
    }

    private static func makeKakaoRepository() -> KakaoRepositoryProtocol {
        #if DEBUG
        if MockAPIConfiguration.useMockAPI {
            print("🧪 Using MockKakaoRepository")
            return sharedMockKakao
        }
        #endif
        return KakaoRepository()
    }

    @MainActor static func makeTabViewModels() -> TabViewModelsContainer {
        let routeRepository = makeRouteRepository()
        let tourRepository = TourRepository()

        let homeViewModel = HomeViewModel(routeRepository: routeRepository,
                                          userSession: makeUserSession(),
                                          profileStore: makeRidingProfileStore())
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

    /// 라이딩 스타일 단일 공급원. 앱 수명 하나만 둔다 —
    /// 경로를 만드는 일곱 호출부가 같은 값을 보고, GET은 앱 실행당 한 번이다.
    @MainActor private static var sharedProfileStore: RidingProfileStore?

    @MainActor static func makeRidingProfileStore() -> RidingProfileProviding {
        if let sharedProfileStore { return sharedProfileStore }
        let store = RidingProfileStore(userRepository: UserRepository())
        sharedProfileStore = store
        return store
    }

    private static func makeUserSession() -> UserSessionProviding {
        return KeychainUserSession()
    }

    @MainActor static func makeRidingViewModel() -> RidingViewModel {
        let ridingViewModel = RidingViewModel(
            routeRepository: makeRouteRepository(),
            kakaoRepository: makeKakaoRepository(),
            profileStore: makeRidingProfileStore(),
            userSession: makeUserSession()
        )
        return ridingViewModel
    }

    static func makeRouteSharedManager() -> RouteSharedManager {
        return RouteSharedManager()
    }

    @MainActor static func makeSpotAddViewModel() -> SpotAddViewModel {
        let tourRepository = TourRepository()
        let routeRepository = makeRouteRepository()

        let spotAddViewModel = SpotAddViewModel(
            tourRepository: tourRepository,
            routeRepository: routeRepository,
            userSession: makeUserSession(),
            profileStore: makeRidingProfileStore())
        return spotAddViewModel
    }

    static func makeRecentSearchViewModel() -> RecentSearchViewModel {
        let makeRecentSearchViewModel = RecentSearchViewModel()
        return makeRecentSearchViewModel
    }

    @MainActor static func makeFilterBarViewModel() -> FilterBarViewModel {
        let FilterBarViewModel = FilterBarViewModel(tourRepository: TourRepository())
        return FilterBarViewModel
    }

    @MainActor static func makeDetailViewModel() -> DetailSpotViewModel {
        let tourRepository = TourRepository()
        let routeRepository = makeRouteRepository()

        return DetailSpotViewModel(
            tourRepository: tourRepository,
            routeRepository: routeRepository,
            userSession: makeUserSession(),
            profileStore: makeRidingProfileStore())
    }

    static func makeRecommendViewModel() -> RecommendRouteViewModel {
        let tourRepository = TourRepository()
        let routeRepository = makeRouteRepository()

        return RecommendRouteViewModel(
            tourRepository: tourRepository,
            routeRepository: routeRepository,
            userSession: KeychainUserSession())
    }
}
