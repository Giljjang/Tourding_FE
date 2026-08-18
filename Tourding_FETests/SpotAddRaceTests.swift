//
//  SpotAddRaceTests.swift
//  Tourding_FETests
//
//  버그 4 재현 — "스팟을 추가했는데 리스트에도 지도에도 안 나타난다 (간혹)"
//
//  SpotAddView.loadInitialData는 스팟 리스트를 먼저 받고 routeLocation을 나중에 받는다.
//  리스트가 뜨는 순간 사용자는 탭할 수 있는데, 그때 routeLocation이 아직 비어 있으면
//  postRouteAPI의 `guard let start = originalData.first` 에 걸려 POST가 아예 나가지 않는다.
//  errorMessage는 화면 어디에도 표시되지 않아 그대로 pop되고,
//  복귀 후 재조회는 추가되지 않은 원래 경로를 돌려준다 — 리스트·지도가 함께 빈다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct SpotAddRaceTests {

    private func makeViewModel(_ repository: FakeRouteRepository) -> SpotAddViewModel {
        SpotAddViewModel(
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

        #expect(viewModel.routeLocation.isEmpty, "리스트만 뜬 상태를 재현한다")

        await viewModel.addSpotToRoute(TestSpot.sample)

        #expect(repository.capturedPostRoutes.count == 1, "경로 로드 전 추가가 조용히 유실되면 안 된다")
        #expect(repository.capturedPostRoutes.first?.locateName.contains("추가 스팟") == true)
    }

    /// 이미 로드된 경우에는 불필요한 재조회 없이 그대로 보낸다
    @Test func addingSpotAfterRouteLoadDoesNotRefetch() async {
        let repository = FakeRouteRepository()
        repository.locationNames = TestRoute.startGoal
        let viewModel = makeViewModel(repository)
        await viewModel.getRouteLocationAPI(showsLoading: false)
        let fetchesAfterLoad = repository.capturedLocationNameRequests.count

        await viewModel.addSpotToRoute(TestSpot.sample)

        #expect(repository.capturedPostRoutes.count == 1)
        #expect(repository.capturedLocationNameRequests.count == fetchesAfterLoad,
                "이미 있는 경로를 다시 받지 않는다")
    }

    /// 경로 자체를 못 받으면 POST를 보내지 않고 사용자에게 알릴 근거를 남긴다
    @Test func addingSpotWithoutAnyRouteReportsInsteadOfSilentlyDropping() async {
        let repository = FakeRouteRepository()
        repository.locationNames = []
        let viewModel = makeViewModel(repository)

        await viewModel.addSpotToRoute(TestSpot.sample)

        #expect(repository.capturedPostRoutes.isEmpty)
        #expect(viewModel.errorMessage != nil, "조용히 성공한 척하면 안 된다")
    }
}
