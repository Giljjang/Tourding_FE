//
//  RetryPolicyTests.swift
//  Tourding_FETests
//
//  ViewModel 5곳에 재시도 루프가 복붙돼 있고, 어떤 에러든 3회를 돈다.
//  오늘 로그에서 /routes/path 500이 3회 연속 같은 답을 받았다.
//  이 서버의 500은 결정적이라 재시도가 순수 낭비이고, 이미 무너진 서버를 더 밀어붙인다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RetryPolicyTests {

    private func makeRepository(failingWith error: ErrorType) -> FakeRouteRepository {
        let repository = FakeRouteRepository()
        repository.getRoutesError = error
        return repository
    }

    // MARK: - RidingViewModel

    @Test func ridingPathDoesNotRetryServerError() async {
        let repository = makeRepository(failingWith: .serverDefinedError(.internalServerError))
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.getRoutePathAPI(isUsed: false)

        #expect(repository.capturedPathRequests.count == 1, "500은 다시 걸어도 같은 답이다")
    }

    @Test func ridingPathRetriesTransientError() async {
        let repository = makeRepository(failingWith: .serverDefinedError(.serviceUnavailable))
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.getRoutePathAPI(isUsed: false)

        #expect(repository.capturedPathRequests.count == 3, "503은 재시도 대상이다")
    }

    @Test func ridingLocationDoesNotRetryClientError() async {
        let repository = makeRepository(failingWith: .serverDefinedError(.badRequest))
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.getRouteLocationAPI(isUsedOverride: false)

        #expect(repository.capturedLocationNameRequests.count == 1, "400은 재시도해도 소용없다")
    }

    // MARK: - RecommendRouteViewModel
    //
    // 추천 코스 화면도 오늘 500을 낸 엔드포인트를 부른다.
    // 예전엔 /routes/location-name·/routes/path를 따로 불러 재시도 지점이 둘이었고,
    // 지금은 GET /routes 하나로 합쳐져 여기 한 곳만 남았다.

    private func makeRecommendViewModel(_ repository: FakeRouteRepository) -> RecommendRouteViewModel {
        RecommendRouteViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49)
        )
    }

    @Test func recommendBundleDoesNotRetryServerError() async {
        let repository = FakeRouteRepository()
        repository.bundleError = ErrorType.serverDefinedError(.internalServerError)
        let viewModel = makeRecommendViewModel(repository)

        await viewModel.loadRouteBundleAPI()

        #expect(repository.capturedBundleRequests.count == 1, "500은 다시 걸어도 같은 답이 온다")
    }

    /// 일시적 장애는 다시 건다 — 정책이 통째로 빠지지 않았는지 확인한다
    @Test func recommendBundleRetriesTransientError() async {
        let repository = FakeRouteRepository()
        repository.bundleError = ErrorType.serverDefinedError(.serviceUnavailable)
        let viewModel = makeRecommendViewModel(repository)

        await viewModel.loadRouteBundleAPI()

        #expect(repository.capturedBundleRequests.count == RetryPolicy.defaultMaxAttempts)
    }
}
