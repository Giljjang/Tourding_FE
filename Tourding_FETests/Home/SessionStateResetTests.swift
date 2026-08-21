//
//  SessionStateResetTests.swift
//  Tourding_FETests
//
//  로그아웃·회원탈퇴 후 이전 사용자의 화면 상태가 남지 않아야 한다.
//
//  증상: 탈퇴 직후(앱을 끄지 않고) 홈에 들어가면 "최근 경로 이어서 가기"가 그대로 보였다.
//  원인 두 겹 —
//   ① HomeViewModel.getRouteLocationAPI가 uid 없을 때 routeLocation을 남긴 채 early return
//   ② 세션 종료 시 ViewModel 상태를 비우는 지점이 아예 없었다
//

import Testing
@testable import Tourding_FE

@MainActor
struct HomeViewModelSessionTests {

    @Test func loadsRecentRouteForInjectedUser() async {
        let repository = FakeRouteRepository()
        repository.locationNames = TestRoute.startTwoWaypointsGoal
        let viewModel = HomeViewModel(
            routeRepository: repository,
            userSession: FakeUserSession(userId: 14),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository())
        )

        await viewModel.getRouteLocationAPI()

        #expect(viewModel.routeLocation.count == 4)
        #expect(repository.capturedLocationNameRequests.last?.userId == 14)
        // 홈의 "최근 경로"는 사용 완료 경로다
        #expect(repository.capturedLocationNameRequests.last?.isUsed == true)
    }

    /// 사용자가 사라졌으면 최근 경로도 화면에서 사라져야 한다.
    /// 이전에는 guard가 early return만 해서 직전 계정의 경로가 그대로 남았다.
    @Test func clearsRecentRouteWhenSessionHasNoUser() async {
        let repository = FakeRouteRepository()
        let viewModel = HomeViewModel(
            routeRepository: repository,
            userSession: FakeUserSession(userId: nil),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository())
        )
        viewModel.routeLocation = TestRoute.startTwoWaypointsGoal   // 직전 계정 데이터

        await viewModel.getRouteLocationAPI()

        #expect(viewModel.routeLocation.isEmpty)
        #expect(repository.capturedLocationNameRequests.isEmpty)
    }

    /// 나머지 호출부도 전역 Keychain이 아니라 주입된 세션을 봐야 한다.
    ///
    /// "세션이 nil이면 요청 안 함"으로 단언하면 시뮬레이터 Keychain이 비어 있어
    /// 전역을 읽는 코드도 통과한다. 실제로 쓰이는지 보려면 주입한 값이 요청에 실려야 한다.
    @Test func routePostUsesInjectedUserId() async {
        let repository = FakeRouteRepository()
        let viewModel = HomeViewModel(
            routeRepository: repository,
            userSession: FakeUserSession(userId: 777_005),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository())
        )

        await viewModel.postRouteAPI(
            start: LocationData(name: "출발", latitude: 37.0, longitude: 127.0),
            end: LocationData(name: "도착", latitude: 37.5, longitude: 127.5)
        )

        #expect(repository.capturedPostRoutes.last?.userId == 777_005)
    }

    @Test func routeByNamePostUsesInjectedUserId() async {
        let repository = FakeRouteRepository()
        repository.routes = RoutesModel(isUsed: false, duration: 1, distance: 1)
        let viewModel = HomeViewModel(
            routeRepository: repository,
            userSession: FakeUserSession(userId: 777_006),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository())
        )

        await viewModel.postRouteByNameAPI(start: "팔당대교", goal: "충주탄금대")

        #expect(repository.capturedByNameRequests.last?.userId == 777_006)
    }
}

@MainActor
struct AppContainerSessionResetTests {

    /// 세션 종료 시 사용자별 상태를 한 곳에서 비운다.
    /// ViewModel이 늘 때마다 View의 로그아웃 처리에 줄을 추가하는 방식은 빠뜨리기 쉽다.
    @Test func clearSessionStateEmptiesUserScopedState() {
        let container = AppContainer()
        let home = container.tabViewModels.homeViewModel
        let recentSearch = container.tabViewModels.recentSearchViewModel

        home.routeLocation = TestRoute.startTwoWaypointsGoal
        home.userId = 14
        recentSearch.add("올리브영")

        container.clearSessionState()

        #expect(home.routeLocation.isEmpty)
        #expect(home.userId == nil)
        #expect(recentSearch.items.isEmpty)
    }

    /// 컨테이너가 들고 있는 별도 RecentSearchViewModel 인스턴스도 함께 비워야 한다
    @Test func clearSessionStateEmptiesEveryRecentSearchInstance() {
        let container = AppContainer()
        container.tabViewModels.recentSearchViewModel.add("탭용")
        container.recentSearchViewModel.add("검색화면용")

        container.clearSessionState()

        #expect(container.tabViewModels.recentSearchViewModel.items.isEmpty)
        #expect(container.recentSearchViewModel.items.isEmpty)
    }

    /// 공개 데이터인 추천 코스는 로그인과 무관하므로 지우지 않는다
    @Test func clearSessionStateKeepsPublicRecommendations() {
        let container = AppContainer()
        let home = container.tabViewModels.homeViewModel
        home.routeRecommendList = [
            RouteRidingRecommendModel(
                arrival: "충주탄금대", description: "설명", minutes: "30", hours: "2",
                departure: "팔당대교", courseType: "종주코스", courseName: "남한강자전거길"
            )
        ]

        container.clearSessionState()

        #expect(home.routeRecommendList.count == 1)
    }
}
