//
//  DetailSpotViewModelLoadingStateTests.swift
//  Tourding_FETests
//
//  P0-5 — isLoading = true 직후 guard로 early return 하면 로딩 오버레이가 화면을 잠근다
//

import Testing
@testable import Tourding_FE

@MainActor
struct DetailSpotViewModelLoadingStateTests {

    /// uid 미확정 상태(로그인 직후 addUserToServer 실패, Keychain 접근 실패)를 결정적으로 재현한다.
    private func withoutStoredUid(_ body: () async -> Void) async {
        let previous = KeychainHelper.loadUid()
        KeychainHelper.deleteUid()
        await body()
        if let previous {
            KeychainHelper.saveUid(key: previous)
        }
    }

    @Test func clearsLoadingWhenUserIdIsMissingOnRouteLocationFetch() async {
        let viewModel = DetailSpotViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: FakeRouteRepository()
        )

        await withoutStoredUid {
            await viewModel.getRouteLocationAPI()
        }

        #expect(viewModel.isLoading == false)
    }

    @Test func clearsLoadingWhenUserIdIsMissingOnRoutePost() async {
        let viewModel = DetailSpotViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: FakeRouteRepository()
        )

        await withoutStoredUid {
            await viewModel.postRouteAPI(
                originalData: TestRoute.startGoal,
                updatedData: TestSpot.sample
            )
        }

        #expect(viewModel.isLoading == false)
    }
}
