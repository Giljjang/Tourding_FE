//
//  RidingStartRecoveryTests.swift
//  Tourding_FETests
//
//  라이딩 시작 흐름의 **특성화 테스트** — 현재 동작을 고정한다.
//
//  RED 단계가 아니다. `POST /routes` 응답을 재사용하도록 바꾸기 전에,
//  지금 무엇이 어떤 순서로 일어나는지를 잠가두는 안전망이다.
//  특히 비정상 종료 복구(isNotNormal == true)는 재현이 어려운 경로라
//  조용히 깨져도 알아채기 힘들다.
//
//  핵심 계약: "백업 후 교체"
//    장소(locations) 기준 마커를 백업한 뒤, 화면은 안내(guides) 기준 마커로 바꾼다.
//    라이딩을 끝내면 백업해둔 장소 기준 마커로 돌아온다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RidingStartRecoveryTests {

    // 개수를 서로 다르게 둬서 어느 쪽 기준인지 구분한다
    private static let locationCount = 4   // TestRoute.startTwoWaypointsGoal
    private static let guideCount = 3
    private static let pathCount = 2

    private func guide(_ sequenceNum: Int) -> GuideModel {
        GuideModel(
            sequenceNum: sequenceNum,
            distance: 100,
            duration: 30,
            instructions: "안내\(sequenceNum)",
            locationName: "지점\(sequenceNum)",
            pointIndex: sequenceNum,
            type: 6,
            lon: "129.38",
            lat: "36.0\(sequenceNum)"
        )
    }

    private func makeRepository() -> FakeRouteRepository {
        let repository = FakeRouteRepository()
        // draft 읽기 결과 (비정상 복구에서 "무엇을 POST할지" 알아내는 용도)
        repository.locationNames = TestRoute.startGoal                      // 2
        // POST 응답 — 서버가 방금 만든 경로 전체
        repository.postRoutesResponse = RouteGuideResponse(
            routeSummaryId: 60, isUsed: true, duration: 100, distance: 200,
            guides: [guide(0), guide(1), guide(2)],                         // 3
            paths: [
                RoutePathModel(sequenceNum: 0, lon: "129.38", lat: "36.01"),
                RoutePathModel(sequenceNum: 1, lon: "129.39", lat: "36.02")
            ],                                                              // 2
            locations: TestRoute.startTwoWaypointsGoal                      // 4
        )
        return repository
    }

    private func startRiding(
        _ viewModel: RidingViewModel,
        isNotNormal: Bool?
    ) async throws {
        viewModel.startRidingWithLoading(
            isNotNormal: isNotNormal,
            locationManager: LocationManager(),
            onMarkAbnormalExit: {}
        )
        let task = try #require(viewModel.ridingStartTask)
        await task.value
    }

    // MARK: - 정상 시작

    /// 정상 시작은 POST 한 번으로 끝난다.
    @Test func normalStartPostsThenLoadsGuides() async throws {
        let repository = makeRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.routeLocation = TestRoute.startTwoWaypointsGoal

        try await startRiding(viewModel, isNotNormal: nil)

        #expect(repository.callLog == ["postRoutes"], "POST 응답에 가이드가 들어 있어 추가 조회가 없다")
        #expect(viewModel.guideList.count == Self.guideCount)
    }

    // MARK: - 비정상 종료 복구

    /// draft를 읽어 POST하면 끝이다. 응답에 경로 전체가 들어 있다.
    @Test func abnormalRecoveryReloadsDraftThenRefetchesUsedRoute() async throws {
        let repository = makeRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)

        try await startRiding(viewModel, isNotNormal: true)

        #expect(repository.callLog == [
            "getRoutesLocationName(isUsed: false)",   // draft 읽기 — 무엇을 POST할지 알아야 한다
            "postRoutes"                               // 응답에 paths·locations·guides가 다 들어 있다
        ], "5회 → 2회")
    }

    /// POST는 draft에서 읽어온 내용으로 나간다
    @Test func abnormalRecoveryPostsWhatItJustRead() async throws {
        let repository = makeRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)

        try await startRiding(viewModel, isNotNormal: true)

        let posted = try #require(repository.capturedPostRoutes.first)
        #expect(posted.isUsed == true)
        #expect(posted.locateName.contains("출발지"))
        #expect(posted.locateName.contains("도착지"))
    }

    // MARK: - 백업 후 교체 (가장 중요)

    /// 화면은 안내 기준 마커를 쓰고, 백업에는 장소 기준 마커가 남아 있어야 한다.
    /// 라이딩을 끝내면 장소 기준으로 되돌아온다.
    @Test func backupKeepsLocationMarkersWhileScreenShowsGuideMarkers() async throws {
        let repository = makeRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)

        try await startRiding(viewModel, isNotNormal: true)

        // 라이딩 중 — 안내 기준
        #expect(viewModel.markerCoordinates.count == Self.guideCount,
                "라이딩 중에는 안내(guides) 기준 마커를 쓴다")

        // 라이딩 종료 — 백업해둔 장소 기준으로 복원
        viewModel.restoreOriginalData(isStart: false)

        #expect(viewModel.markerCoordinates.count == Self.locationCount,
                "백업은 장소(locations) 기준이어야 한다 — 백업 후 교체 순서가 깨지면 여기서 잡힌다")
        #expect(viewModel.markerIcons.count == viewModel.markerCoordinates.count)
    }

    /// 경로선도 백업 대상이다
    @Test func backupKeepsPathCoordinates() async throws {
        let repository = makeRepository()
        let viewModel = makeTestRidingViewModel(repository: repository)

        try await startRiding(viewModel, isNotNormal: true)
        viewModel.restoreOriginalData(isStart: false)

        #expect(viewModel.pathCoordinates.count == Self.pathCount)
    }
}
