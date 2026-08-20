//
//  LoadingStateOnFailureTests.swift
//  Tourding_FETests
//
//  B1 — 스팟 추가 POST가 실패하면 로딩 오버레이가 영구히 남는다.
//
//  SpotAddViewModel.postRouteAPI는 isLoading = true 이후 해제를 do 블록 **안**에서만 한다.
//  catch에는 해제가 없고 defer도 없어서, 서버가 실패하면 화면이 로딩에 잠긴 채로 멈춘다.
//
//  같은 파일의 getRouteLocationAPI와 DetailSpotViewModel.postRouteAPI는 defer를 쓴다 —
//  이 메서드만 빠졌다. "isLoading defer 통일"이 여기서 새어 있었다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct LoadingStateOnFailureTests {

    private func makeSpotAddViewModel(_ repository: FakeRouteRepository) -> SpotAddViewModel {
        SpotAddViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49)
        )
    }

    /// 실패해도 로딩은 반드시 풀려야 한다 — 보고된 증상 그 자체
    @Test func spotAddPostFailureClearsLoading() async {
        let repository = FakeRouteRepository()
        repository.postRoutesError = FakeRouteRepository.FakeError.postFailed
        let viewModel = makeSpotAddViewModel(repository)

        await viewModel.postRouteAPI(
            originalData: TestRoute.startGoal,
            updatedData: TestSpot.sample
        )

        #expect(repository.capturedPostRoutes.count == 1, "전제: POST가 실제로 시도됐다")
        #expect(viewModel.isLoading == false,
                "POST가 실패해도 로딩 오버레이는 내려가야 한다")
    }

    /// 성공 경로가 함께 깨지지 않는지 잠근다
    @Test func spotAddPostSuccessClearsLoading() async {
        let repository = FakeRouteRepository()
        let viewModel = makeSpotAddViewModel(repository)

        await viewModel.postRouteAPI(
            originalData: TestRoute.startGoal,
            updatedData: TestSpot.sample
        )

        #expect(viewModel.isLoading == false)
    }

    /// 요청을 보내기도 전에 막히는 가드 경로에서는 로딩이 애초에 켜지지 않아야 한다
    @Test func spotAddGuardFailureLeavesLoadingUntouched() async {
        let repository = FakeRouteRepository()
        let viewModel = makeSpotAddViewModel(repository)

        // start/goal을 못 만드는 입력 — 가드에 걸려 POST 자체가 나가지 않는다
        await viewModel.postRouteAPI(originalData: [], updatedData: TestSpot.sample)

        #expect(repository.capturedPostRoutes.isEmpty, "전제: 가드에 걸려 POST가 나가지 않았다")
        #expect(viewModel.isLoading == false)
    }
}
