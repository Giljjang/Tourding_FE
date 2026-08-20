//
//  DetailSpotAddRaceTests.swift
//  Tourding_FETests
//
//  버그 4의 쌍둥이 — 상세보기에서 "코스에 추가"를 누르는 경로.
//
//  DetailSpotView.onAppear도 상세 정보를 먼저 받고 getRouteLocationAPI를 나중에 부른다.
//  상세가 그려진 순간 추가 버튼을 누를 수 있는데, 그때 routeLocation이 비어 있으면
//  postRouteAPI의 guard에 걸려 POST가 나가지 않는다. 그대로 RidingView까지 pop되므로
//  사용자는 추가된 줄 알지만 경로에는 없다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct DetailSpotAddRaceTests {

    private func makeViewModel(_ repository: FakeRouteRepository) -> DetailSpotViewModel {
        DetailSpotViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49)
        )
    }

    /// 경로가 아직 로드되지 않은 시점에 추가를 눌러도 요청이 유실되면 안 된다
    @Test func addingSpotBeforeRouteLoadStillSendsRequest() async {
        let repository = FakeRouteRepository()
        repository.locationNames = TestRoute.startGoal
        let viewModel = makeViewModel(repository)

        #expect(viewModel.routeLocation.isEmpty, "상세만 뜬 상태를 재현한다")

        await viewModel.addSpotToRoute(TestSpot.sample)

        #expect(repository.capturedPostRoutes.count == 1, "경로 로드 전 추가가 조용히 유실되면 안 된다")
        #expect(repository.capturedPostRoutes.first?.locateName.contains("추가 스팟") == true)
    }

    /// 이미 로드된 경우에는 불필요한 재조회 없이 그대로 보낸다
    @Test func addingSpotAfterRouteLoadDoesNotRefetch() async {
        let repository = FakeRouteRepository()
        repository.locationNames = TestRoute.startGoal
        let viewModel = makeViewModel(repository)
        await viewModel.getRouteLocationAPI()
        let fetchesAfterLoad = repository.capturedLocationNameRequests.count

        await viewModel.addSpotToRoute(TestSpot.sample)

        #expect(repository.capturedPostRoutes.count == 1)
        #expect(repository.capturedLocationNameRequests.count == fetchesAfterLoad,
                "이미 있는 경로를 다시 받지 않는다")
    }

    /// 경로 자체를 못 받으면 POST를 보내지 않고 알릴 근거를 남긴다
    @Test func addingSpotWithoutAnyRouteReportsInsteadOfSilentlyDropping() async {
        let repository = FakeRouteRepository()
        repository.locationNames = []
        let viewModel = makeViewModel(repository)

        await viewModel.addSpotToRoute(TestSpot.sample)

        #expect(repository.capturedPostRoutes.isEmpty)
        #expect(viewModel.errorMessage != nil, "조용히 성공한 척하면 안 된다")
    }
}
