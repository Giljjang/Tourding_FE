//
//  RecommendRouteBundleTests.swift
//  Tourding_FETests
//
//  ④ 추천 코스 화면이 경로를 세 번 나눠 받던 것을 한 번으로 합친다.
//
//  화면에 들어갈 때마다 GET /routes · /routes/location-name · /routes/path 를 순서대로 불렀다.
//  셋 다 같은 경로를 가리키므로 서버는 같은 계산을 세 번 한다.
//  라이딩 화면은 이미 `getRouteBundle`(GET /routes) 하나로 요약·장소·경로선을 받는다 —
//  실측상 짧은 세션에 /routes 200 응답이 12회 나간 뒤 세 엔드포인트가 연쇄 500을 반환했다.
//
//  추천 화면은 **draft(isUsed: false)** 를 읽는다. 사용자가 아직 라이딩을 시작하지 않았다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RecommendRouteBundleTests {

    private func makeViewModel(_ repository: FakeRouteRepository) -> RecommendRouteViewModel {
        RecommendRouteViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49)
        )
    }

    private var bundle: RouteGuideResponse {
        RouteGuideResponse(
            routeSummaryId: 60,
            isUsed: false,
            duration: 3600,
            distance: 12345,
            guides: [],
            paths: [
                RoutePathModel(sequenceNum: 0, lon: "127.0", lat: "37.0"),
                RoutePathModel(sequenceNum: 1, lon: "127.1", lat: "37.1")
            ],
            locations: [
                TestRoute.location(sequenceNum: 0, name: "출발", type: "Start", lat: "37.0", lon: "127.0"),
                TestRoute.location(sequenceNum: 1, name: "경유", type: "WayPoint", lat: "37.05", lon: "127.05"),
                TestRoute.location(sequenceNum: 2, name: "도착", type: "Goal", lat: "37.1", lon: "127.1")
            ]
        )
    }

    // MARK: - 호출 횟수

    /// **핵심** — 한 번만 부른다. 셋으로 나뉘어 있던 시절 서버가 같은 경로를 세 번 계산했다
    @Test func loadsEverythingWithASingleRequest() async {
        let repository = FakeRouteRepository()
        repository.bundle = bundle

        await makeViewModel(repository).loadRouteBundleAPI()

        #expect(repository.capturedBundleRequests.count == 1)
    }

    /// 추천 화면은 아직 라이딩 전이므로 draft를 읽는다
    @Test func readsDraftRoute() async {
        let repository = FakeRouteRepository()
        repository.bundle = bundle

        await makeViewModel(repository).loadRouteBundleAPI()

        #expect(repository.capturedBundleRequests.first?.isUsed == false)
        #expect(repository.capturedBundleRequests.first?.userId == 49)
    }

    // MARK: - 반영

    @Test func fillsSummaryLocationsAndPath() async {
        let repository = FakeRouteRepository()
        repository.bundle = bundle
        let viewModel = makeViewModel(repository)

        await viewModel.loadRouteBundleAPI()

        #expect(viewModel.routeTotal?.routeSummaryId == 60)
        #expect(viewModel.routeTotal?.distance == 12345)
        #expect(viewModel.routeLocation.map { $0.name } == ["출발", "경유", "도착"])
        #expect(viewModel.routeMapPaths.count == 2)
    }

    /// 지도에 그릴 좌표까지 만들어져야 한다 — 화면이 따로 변환하지 않는다
    @Test func buildsMapCoordinates() async {
        let repository = FakeRouteRepository()
        repository.bundle = bundle
        let viewModel = makeViewModel(repository)

        await viewModel.loadRouteBundleAPI()

        #expect(viewModel.pathCoordinates.count == 2)
        #expect(viewModel.markerCoordinates.count == 3)
        #expect(viewModel.markerIcons.count == 3)
    }

    // MARK: - 실패

    /// 실패하면 화면에 아무것도 그리지 않는다.
    ///
    /// **옛 코스를 추천 코스인 양 보여주면 안 된다.** 실제로 그런 일이 있었다 —
    /// /routes/by-name 실패를 삼키고 화면을 넘겨, draft에 남아 있던 사용자의 옛 코스가
    /// 추천 코스 자리에 떴다.
    @Test func leavesRouteEmptyWhenRequestFails() async {
        let repository = FakeRouteRepository()   // bundle 미설정 → notConfigured
        let viewModel = makeViewModel(repository)

        await viewModel.loadRouteBundleAPI()

        #expect(viewModel.routeLocation.isEmpty)
        #expect(viewModel.pathCoordinates.isEmpty)
    }

    /// 실패해도 로딩은 반드시 내려간다 — 오버레이가 영구히 남으면 화면이 잠긴다
    @Test func clearsLoadingOnFailure() async {
        let repository = FakeRouteRepository()
        let viewModel = makeViewModel(repository)

        await viewModel.loadRouteBundleAPI()

        #expect(viewModel.isLoading == false)
    }
}
