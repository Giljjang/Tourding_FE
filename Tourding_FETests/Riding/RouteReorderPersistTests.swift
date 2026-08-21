//
//  RouteReorderPersistTests.swift
//  Tourding_FETests
//
//  P0-6 — 디바운스 저장 Task가 자기 자신을 취소해 경유지 순서 POST가 유실되는 문제
//  P0-7 — routeSource가 반영되지 않아 최근 사용 경로가 draft로 덮이는 문제
//

import Testing
@testable import Tourding_FE

@MainActor
struct RouteReorderPersistTests {

    // MARK: - P0-6

    @Test func debouncedPersistPostsWithoutSelfCancellation() async throws {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.routeLocation = TestRoute.startTwoWaypointsGoal

        viewModel.schedulePersistRouteOrderAfterReorder()
        let scheduled = try #require(viewModel.reorderPersistTask)
        await scheduled.value

        #expect(repository.capturedPostRoutes.count == 1)
        #expect(repository.postRoutesCancellationStates == [false])
    }

    /// 회귀 가드 — performDrop 즉시 저장 경로는 그대로 동작해야 한다
    @Test func immediatePersistSendsPost() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.routeLocation = TestRoute.startTwoWaypointsGoal

        await viewModel.persistRouteOrderAfterReorder()

        #expect(repository.capturedPostRoutes.count == 1)
        #expect(repository.postRoutesCancellationStates == [false])
    }

    /// 회귀 가드 — 즉시 저장은 예약된 디바운스 Task를 취소해 중복 POST를 막아야 한다
    @Test func immediatePersistCancelsScheduledDebounce() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.routeLocation = TestRoute.startTwoWaypointsGoal

        viewModel.schedulePersistRouteOrderAfterReorder()
        let scheduled = viewModel.reorderPersistTask
        await viewModel.persistRouteOrderAfterReorder()
        await scheduled?.value

        #expect(repository.capturedPostRoutes.count == 1)
    }

    // MARK: - P0-7

    @Test func dragDropPostUsesRouteSourceForIsUsed() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.flag = false
        viewModel.routeSource = .recentUsed

        await viewModel.postRouteDragNDropAPI(locationData: TestRoute.startTwoWaypointsGoal)

        #expect(repository.capturedPostRoutes.last?.isUsed == true)
    }

    /// 재정렬 저장 후 경로선 재조회도 같은 경로(routeSource)를 가리켜야 한다.
    /// 어긋나면 리스트는 최근 사용 경로인데 지도 경로선만 draft로 바뀐다.
    @Test func persistRefetchesPathForSameRouteSource() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.routeLocation = TestRoute.startTwoWaypointsGoal
        viewModel.flag = false
        viewModel.routeSource = .recentUsed

        await viewModel.persistRouteOrderAfterReorder()

        #expect(repository.capturedPathRequests.last?.isUsed == true)
    }

    /// 경유지 삭제도 같은 출처에 저장해야 한다 (재정렬과 동일한 결함)
    @Test func deletePostUsesRouteSourceForIsUsed() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.flag = false
        viewModel.routeSource = .recentUsed
        let route = TestRoute.startTwoWaypointsGoal

        await viewModel.postRouteDeleteAPI(originalData: route, selectedData: route[1])

        #expect(repository.capturedPostRoutes.last?.isUsed == true)
    }

    @Test func dragDropPostKeepsDraftForDraftSource() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.flag = false
        viewModel.routeSource = .draft

        await viewModel.postRouteDragNDropAPI(locationData: TestRoute.startTwoWaypointsGoal)

        #expect(repository.capturedPostRoutes.last?.isUsed == false)
    }
}
