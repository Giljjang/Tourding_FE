//
//  RouteBundleTests.swift
//  Tourding_FETests
//
//  편집 모드 진입이 /routes, /routes/location-name, /routes/path 를 각각 호출해
//  같은 경로를 세 번 재계산시킨다. 실측: 짧은 세션 하나에 /routes(82KB) 응답만 12회.
//  서버가 /routes·/routes/path·/routes/guide 에서 연쇄 500을 내는 상황과 맞물린다.
//
//  서버 응답 확인(🔎 [Diag/Bundle] guides=40 paths=1257 locations=2):
//  /routes 하나에 요약·가이드·경로선·장소가 전부 들어 있다. 한 번만 부르면 된다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RouteBundleTests {

    private func makeBundle() throws -> RouteGuideResponse {
        try FixtureLoader.load("routes_guide_response.json")
    }

    /// 한 번의 요청으로 요약·경유지·경로선이 모두 채워져야 한다
    @Test func loadsSummaryLocationsAndPathFromSingleRequest() async throws {
        let repository = FakeRouteRepository()
        repository.bundle = try makeBundle()
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.loadRouteBundleAPI(isUsed: false)

        #expect(repository.capturedBundleRequests.count == 1)
        #expect(viewModel.routeTotal?.distance == 49457.3)
        #expect(viewModel.routeLocation.count == 3)
        #expect(viewModel.pathCoordinates.count == 2)
    }

    /// 마커도 함께 갱신돼야 한다 — 좌표와 아이콘 개수가 어긋나면 지도가 빈다
    @Test func appliesMarkersFromBundleLocations() async throws {
        let repository = FakeRouteRepository()
        repository.bundle = try makeBundle()
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.loadRouteBundleAPI(isUsed: false)

        #expect(viewModel.markerCoordinates.isEmpty == false, "마커가 실제로 생겨야 한다")
        #expect(viewModel.markerCoordinates.count == viewModel.markerIcons.count)
        #expect(viewModel.markerCoordinates.count == viewModel.routeLocation.count)
    }

    /// 편집 모드 진입이 세 엔드포인트를 각각 부르지 않아야 한다
    @Test func editModeLoadIssuesOneRequestInsteadOfThree() async throws {
        let repository = FakeRouteRepository()
        repository.bundle = try makeBundle()
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.loadEditModeRouteData(cameraOnlyWhenNotRiding: true, routeSource: .draft)

        #expect(repository.capturedBundleRequests.count == 1)
        #expect(repository.capturedRoutesRequests.isEmpty, "요약을 따로 부르지 않는다")
        #expect(repository.capturedLocationNameRequests.isEmpty, "경유지를 따로 부르지 않는다")
        #expect(repository.capturedPathRequests.isEmpty, "경로선을 따로 부르지 않는다")
    }

    /// 어느 경로(draft / 사용 완료)를 읽는지가 유지돼야 한다
    @Test func bundleRequestCarriesRouteSource() async throws {
        let repository = FakeRouteRepository()
        repository.bundle = try makeBundle()
        let viewModel = makeTestRidingViewModel(repository: repository)

        await viewModel.loadEditModeRouteData(cameraOnlyWhenNotRiding: true, routeSource: .recentUsed)

        #expect(repository.capturedBundleRequests.last?.isUsed == true)
    }
}
