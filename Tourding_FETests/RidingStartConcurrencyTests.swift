//
//  RidingStartConcurrencyTests.swift
//  Tourding_FETests
//
//  비동기 A — 라이딩 시작 Task 추적 + 편집 모드 총계 갱신 디바운스
//
//  ① startRidingAPIProcess가 자식 Task를 띄우고 즉시 반환해 "완료"로 표시했다.
//     그 Task는 저장되지 않아 취소할 수 없었고, 라이딩을 끝낸 뒤 뒤늦게 완료되면
//     편집 모드 화면을 가이드 마커로 덮었다.
//  ② routeLocation 변경마다 총계 API가 발사되고 로딩 오버레이가 떠 드래그 제스처를 끊었다.
//

import Foundation
import Combine
import Testing
@testable import Tourding_FE

/// 클로저가 Task 자신을 참조해야 하는데 생성 시점과 사용 시점이 어긋날 때 쓰는 상자
private final class TaskBox: @unchecked Sendable {
    var task: Task<Void, Never>?
}

@MainActor
struct RidingStartConcurrencyTests {

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

    private func makeViewModel(_ repository: FakeRouteRepository) -> RidingViewModel {
        let viewModel = makeTestRidingViewModel(repository: repository)
        viewModel.routeLocation = TestRoute.startTwoWaypointsGoal
        return viewModel
    }

    // MARK: - ① 라이딩 시작

    /// 로딩 표시는 가이드 로드가 **실제로 끝난 뒤** 내려가야 한다.
    /// 이전에는 자식 Task를 띄우고 바로 "완료"로 처리했다.
    @Test func startRidingCompletesOnlyAfterGuidesAreLoaded() async throws {
        let repository = FakeRouteRepository()
        repository.guides = [guide(0), guide(1)]
        let viewModel = makeViewModel(repository)

        viewModel.startRidingWithLoading(
            isNotNormal: nil,
            locationManager: LocationManager(),
            onMarkAbnormalExit: {}
        )
        let task = try #require(viewModel.ridingStartTask)
        await task.value

        #expect(viewModel.guideList.count == 2)
        #expect(viewModel.isStartingRiding == false)
    }

    /// 라이딩을 끝냈으면 뒤늦게 끝난 가이드가 편집 모드 화면을 덮으면 안 된다
    @Test func endRidingCancelsRidingStartBeforeGuidesApply() async throws {
        let repository = FakeRouteRepository()
        repository.guides = [guide(0), guide(1)]
        let viewModel = makeViewModel(repository)

        viewModel.startRidingWithLoading(
            isNotNormal: nil,
            locationManager: LocationManager(),
            onMarkAbnormalExit: {}
        )
        let task = try #require(viewModel.ridingStartTask)

        await viewModel.endRiding(isStart: false, locationManager: LocationManager())
        await task.value

        #expect(viewModel.guideList.isEmpty, "취소된 가이드 로드가 편집 모드를 덮으면 안 된다")
        #expect(viewModel.flag == false)
    }

    /// ②와 달리 취소가 **요청 도중**에 들어온다 — 보고된 증상("라이딩을 끝냈는데 잠시 뒤
    /// 편집 화면이 가이드 마커로 덮인다")은 이쪽이다. 시작 전 취소만 막아서는 재발한다.
    @Test func guidesArrivingAfterCancellationDoNotOverwriteEditMode() async throws {
        let repository = FakeRouteRepository()
        repository.guides = [guide(0), guide(1)]
        let viewModel = makeViewModel(repository)

        // 가이드 응답이 도착하는 순간 라이딩 시작 Task를 취소한다
        let box = TaskBox()
        repository.onGetRoutesGuide = { box.task?.cancel() }

        viewModel.startRidingWithLoading(
            isNotNormal: nil,
            locationManager: LocationManager(),
            onMarkAbnormalExit: {}
        )
        let task = try #require(viewModel.ridingStartTask)
        box.task = task
        await task.value

        #expect(viewModel.guideList.isEmpty, "취소 후 도착한 가이드가 편집 모드를 덮으면 안 된다")
        #expect(viewModel.isStartingRiding == false)
    }

    /// 취소되더라도 로딩 오버레이는 반드시 내려가야 한다 (화면 잠김 방지)
    @Test func cancelledRidingStartStillClearsLoadingOverlay() async throws {
        let repository = FakeRouteRepository()
        repository.guides = [guide(0)]
        let viewModel = makeViewModel(repository)

        viewModel.startRidingWithLoading(
            isNotNormal: nil,
            locationManager: LocationManager(),
            onMarkAbnormalExit: {}
        )
        let task = try #require(viewModel.ridingStartTask)
        task.cancel()
        await task.value

        #expect(viewModel.isStartingRiding == false)
    }

    // MARK: - ② 총계 갱신 디바운스

    /// 드래그 중 routeLocation이 여러 번 바뀌어도 총계 조회는 한 번만 나가야 한다
    @Test func rapidRouteLocationChangesIssueSingleTotalRequest() async throws {
        let repository = FakeRouteRepository()
        repository.routes = RoutesModel(isUsed: false, duration: 100, distance: 200)
        let viewModel = makeViewModel(repository)
        viewModel.flag = false

        viewModel.handleRouteLocationChangedInEditMode()
        viewModel.handleRouteLocationChangedInEditMode()
        viewModel.handleRouteLocationChangedInEditMode()

        let task = try #require(viewModel.routeTotalRefreshTask)
        await task.value

        #expect(repository.capturedRoutesRequests.count == 1)
    }

    /// 총계 갱신이 전체 로딩 오버레이를 띄우면 드래그 제스처가 끊긴다.
    /// 끝난 뒤의 `isLoading`이 아니라 **도는 동안 한 번이라도 켜졌는지**를 본다 —
    /// 증상은 오버레이가 깜빡이는 것이지 끝나고 남는 게 아니다.
    @Test func routeTotalRefreshDoesNotRaiseLoadingOverlay() async throws {
        let repository = FakeRouteRepository()
        repository.routes = RoutesModel(isUsed: false, duration: 100, distance: 200)
        let viewModel = makeViewModel(repository)
        viewModel.flag = false

        var observedLoading: [Bool] = []
        let subscription = viewModel.$isLoading.sink { observedLoading.append($0) }
        defer { subscription.cancel() }

        viewModel.handleRouteLocationChangedInEditMode()
        let task = try #require(viewModel.routeTotalRefreshTask)
        await task.value

        #expect(observedLoading.contains(true) == false,
                "총계 갱신 중 로딩 오버레이가 떠 드래그가 끊긴다: \(observedLoading)")
        #expect(viewModel.routeTotal?.distance == 200)
    }
}
