//
//  DetailSpotViewModelLoadingStateTests.swift
//  Tourding_FETests
//
//  P0-5 — isLoading = true 직후 guard로 early return 하면 로딩 오버레이가 화면을 잠근다
//
//  "uid 미확정" 상태는 주입된 세션으로 표현한다 (전역 Keychain을 만지지 않는다).
//

import Testing
@testable import Tourding_FE

@MainActor
struct DetailSpotViewModelLoadingStateTests {

    private func makeViewModel(userId: Int?) -> DetailSpotViewModel {
        DetailSpotViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: FakeRouteRepository(),
            userSession: FakeUserSession(userId: userId),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository())
        )
    }

    @Test func clearsLoadingWhenUserIdIsMissingOnRouteLocationFetch() async {
        let viewModel = makeViewModel(userId: nil)

        await viewModel.getRouteLocationAPI()

        #expect(viewModel.isLoading == false)
    }

    @Test func clearsLoadingWhenUserIdIsMissingOnRoutePost() async {
        let viewModel = makeViewModel(userId: nil)

        await viewModel.postRouteAPI(
            originalData: TestRoute.startGoal,
            updatedData: TestSpot.sample
        )

        #expect(viewModel.isLoading == false)
    }

    @Test func clearsLoadingAfterSuccessfulRoutePost() async {
        let viewModel = makeViewModel(userId: 14)

        await viewModel.postRouteAPI(
            originalData: TestRoute.startGoal,
            updatedData: TestSpot.sample
        )

        #expect(viewModel.isLoading == false)
    }
}
