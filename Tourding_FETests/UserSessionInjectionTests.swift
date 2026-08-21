//
//  UserSessionInjectionTests.swift
//  Tourding_FETests
//
//  ViewModel이 userId를 전역 Keychain이 아니라 주입된 세션에서 가져오는지.
//
//  전역 의존이면 테스트가 시뮬레이터 Keychain 상태에 좌우되고,
//  "uid 미확정" 시나리오(로그인 직후 저장 전)를 재현할 수 없다.
//
//  Keychain에 어떤 값이 들어 있든 결과가 갈리도록 실제로 쓰이지 않는 userId를 쓴다.
//

import Testing
@testable import Tourding_FE

@MainActor
struct UserSessionInjectionTests {

    @Test func ridingViewModelSendsInjectedUserId() async {
        let repository = FakeRouteRepository()
        let viewModel = RidingViewModel(
            routeRepository: repository,
            kakaoRepository: FakeKakaoRepository(),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: RouteEditSession(),
            userSession: FakeUserSession(userId: 777_001)
        )

        await viewModel.postRouteDragNDropAPI(locationData: TestRoute.startTwoWaypointsGoal)

        #expect(repository.capturedPostRoutes.last?.userId == 777_001)
    }

    @Test func ridingViewModelSkipsRequestWhenSessionHasNoUserId() async {
        let repository = FakeRouteRepository()
        let viewModel = RidingViewModel(
            routeRepository: repository,
            kakaoRepository: FakeKakaoRepository(),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: RouteEditSession(),
            userSession: FakeUserSession(userId: nil)
        )

        await viewModel.postRouteDragNDropAPI(locationData: TestRoute.startTwoWaypointsGoal)

        #expect(repository.capturedPostRoutes.isEmpty)
    }

    @Test func detailSpotViewModelSendsInjectedUserId() async {
        let repository = FakeRouteRepository()
        let viewModel = DetailSpotViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 777_003),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: RouteEditSession()
        )

        await viewModel.postRouteAPI(originalData: TestRoute.startGoal, updatedData: TestSpot.sample)

        #expect(repository.capturedPostRoutes.last?.userId == 777_003)
    }

    @Test func detailSpotViewModelSkipsRequestWhenSessionHasNoUserId() async {
        let repository = FakeRouteRepository()
        let viewModel = DetailSpotViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: nil),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: RouteEditSession()
        )

        await viewModel.postRouteAPI(originalData: TestRoute.startGoal, updatedData: TestSpot.sample)

        #expect(repository.capturedPostRoutes.isEmpty)
    }

    @Test func spotAddViewModelUsesInjectedUserId() {
        let viewModel = SpotAddViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: FakeRouteRepository(),
            userSession: FakeUserSession(userId: 777_002),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: RouteEditSession()
        )

        #expect(viewModel.userId == 777_002)
    }

    @Test func spotAddViewModelHasNoUserIdWhenSessionIsEmpty() {
        let viewModel = SpotAddViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: FakeRouteRepository(),
            userSession: FakeUserSession(userId: nil),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: RouteEditSession()
        )

        #expect(viewModel.userId == nil)
    }
}
