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
    // 이 두 곳이 오늘 500을 낸 바로 그 엔드포인트(/routes/location-name, /routes/path)를 부른다.
    // 라이딩 화면만 고치면 추천 코스 화면은 계속 3번씩 때린다.

    private func makeRecommendViewModel(_ repository: FakeRouteRepository) -> RecommendRouteViewModel {
        RecommendRouteViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49)
        )
    }

    @Test func recommendLocationDoesNotRetryServerError() async {
        let repository = makeRepository(failingWith: .serverDefinedError(.internalServerError))
        let viewModel = makeRecommendViewModel(repository)

        await viewModel.getRouteLocationAPI()

        #expect(repository.capturedLocationNameRequests.count == 1)
    }

    @Test func recommendPathDoesNotRetryServerError() async {
        let repository = makeRepository(failingWith: .serverDefinedError(.internalServerError))
        let viewModel = makeRecommendViewModel(repository)

        await viewModel.getRoutePathAPI()

        #expect(repository.capturedPathRequests.count == 1)
    }
}
