//
//  RidingViewModelLoadingStateTests.swift
//  Tourding_FETests
//
//  P0-5 — POST 실패 시 isLoading이 해제되지 않아 로딩 오버레이가 화면을 잠그는 문제
//

import Testing
@testable import Tourding_FE

@MainActor
struct RidingViewModelLoadingStateTests {

    @Test func clearsLoadingWhenRidingStartPostFails() async {
        let repository = FakeRouteRepository()
        repository.postRoutesError = FakeRouteRepository.FakeError.postFailed
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.postRidingStartAPI(locationData: TestRoute.startGoal)

        #expect(viewModel.isLoading == false)
    }

    @Test func clearsLoadingWhenDeletePostFails() async {
        let repository = FakeRouteRepository()
        repository.postRoutesError = FakeRouteRepository.FakeError.postFailed
        let viewModel = makeTestRidingViewModel(repository: repository)
        let route = TestRoute.startTwoWaypointsGoal

        await viewModel.postRouteDeleteAPI(originalData: route, selectedData: route[1])

        #expect(viewModel.isLoading == false)
    }

    @Test func clearsLoadingWhenDragDropPostFails() async {
        let repository = FakeRouteRepository()
        repository.postRoutesError = FakeRouteRepository.FakeError.postFailed
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.postRouteDragNDropAPI(locationData: TestRoute.startTwoWaypointsGoal)

        #expect(viewModel.isLoading == false)
    }

    @Test func clearsLoadingOnSuccessPath() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.postRidingStartAPI(locationData: TestRoute.startGoal)

        #expect(viewModel.isLoading == false)
    }
}
