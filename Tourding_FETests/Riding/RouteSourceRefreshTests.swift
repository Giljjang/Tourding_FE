//
//  RouteSourceRefreshTests.swift
//  Tourding_FETests
//
//  최근 경로 이어가기에서 경유지를 삭제하면 목록이 원상복구되던 문제.
//
//  삭제 POST는 routeSource(사용 완료)에 반영되는데, 직후 재조회는 기본값이 `flag`라
//  편집 모드(flag == false)에서 draft 경로를 읽어왔다.
//  draft와 사용 완료 경로는 라이딩 시작 시 같은 내용으로 두 벌 저장되므로,
//  화면에는 "지우기 전 목록"이 다시 그려져 삭제가 안 된 것처럼 보였다.
//

import Testing
@testable import Tourding_FE

@MainActor
struct RouteSourceRefreshTests {

    // MARK: - 어느 경로를 읽어야 하는가

    /// 라이딩 중이면 서버에 사용 완료로 저장돼 있고, 최근 경로 이어가기도 사용 완료 경로다.
    @Test func resolvesUsedRouteFromFlagAndRouteSource() {
        let viewModel = makeTestRidingViewModel()

        viewModel.flag = false
        viewModel.routeSource = .draft
        #expect(viewModel.isUsedRoute == false)

        viewModel.flag = false
        viewModel.routeSource = .recentUsed
        #expect(viewModel.isUsedRoute == true)

        viewModel.flag = true
        viewModel.routeSource = .draft
        #expect(viewModel.isUsedRoute == true)

        viewModel.flag = true
        viewModel.routeSource = .recentUsed
        #expect(viewModel.isUsedRoute == true)
    }

    // MARK: - 삭제 후 재조회

    @Test func deleteRefreshReadsTheSameRouteItWroteTo() async {
        let repository = FakeRouteRepository()
        repository.locationNames = TestRoute.startTwoWaypointsGoal
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.flag = false
        viewModel.routeSource = .recentUsed
        viewModel.routeLocation = TestRoute.startTwoWaypointsGoal

        await viewModel.deleteWaypointAndRefresh(TestRoute.startTwoWaypointsGoal[1])

        #expect(repository.capturedPostRoutes.last?.isUsed == true)
        #expect(repository.capturedLocationNameRequests.last?.isUsed == true)
        #expect(repository.capturedPathRequests.last?.isUsed == true)
    }

    @Test func deleteRefreshStaysOnDraftWhenEditingDraft() async {
        let repository = FakeRouteRepository()
        repository.locationNames = TestRoute.startTwoWaypointsGoal
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.flag = false
        viewModel.routeSource = .draft
        viewModel.routeLocation = TestRoute.startTwoWaypointsGoal

        await viewModel.deleteWaypointAndRefresh(TestRoute.startTwoWaypointsGoal[1])

        #expect(repository.capturedPostRoutes.last?.isUsed == false)
        #expect(repository.capturedLocationNameRequests.last?.isUsed == false)
        #expect(repository.capturedPathRequests.last?.isUsed == false)
    }

    // MARK: - 총계 갱신

    /// 거리·소요시간도 같은 경로에서 읽어야 한다
    @Test func routeTotalRefreshReadsSameRoute() async {
        let repository = FakeRouteRepository()
        repository.routes = RoutesModel(isUsed: true, duration: 100, distance: 200)
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.flag = false
        viewModel.routeSource = .recentUsed

        await viewModel.getRoutesTotalAPI()

        #expect(repository.capturedRoutesRequests.last?.isUsed == true)
    }

    // MARK: - 회귀 가드

    /// 라이딩 시작 흐름은 의도적으로 draft를 읽는다 (`isRecommend: true`)
    @Test func recommendFlowStillReadsDraftRoute() async {
        let repository = FakeRouteRepository()
        repository.locationNames = TestRoute.startGoal
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.flag = true
        viewModel.routeSource = .recentUsed

        await viewModel.getRouteLocationAPI(isRecommend: true)

        #expect(repository.capturedLocationNameRequests.last?.isUsed == false)
    }

    /// 명시 인자는 언제나 기본값을 이긴다
    @Test func explicitOverrideWinsOverResolvedRoute() async {
        let repository = FakeRouteRepository()
        repository.locationNames = TestRoute.startGoal
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.flag = true
        viewModel.routeSource = .recentUsed

        await viewModel.getRouteLocationAPI(isUsedOverride: false)
        await viewModel.getRoutePathAPI(isUsed: false)

        #expect(repository.capturedLocationNameRequests.last?.isUsed == false)
        #expect(repository.capturedPathRequests.last?.isUsed == false)
    }
}
