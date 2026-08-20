//
//  MarkerPassingTests.swift
//  Tourding_FETests
//
//  라이딩 중 마커 통과 판정 — "안내가 가끔 건너뛰어진다"의 재현.
//
//  checkAndRemovePassedMarkers는 임계값(30m) 안에 든 마커 중 **가장 가까운 것**을 찾아
//  0...그 인덱스를 한꺼번에 제거한다. 그래서 30m 안에 마커가 둘 이상 들어오거나
//  GPS가 튀면 중간 안내가 화면에 한 번도 뜨지 않고 사라진다.
//
//  실제 GPS 없이 좌표를 직접 주입해 검증한다.
//  mapView·markerManager가 nil이면 지도 갱신은 guard로 빠지므로 헤드리스로 완주한다.
//

import Foundation
import Testing
@testable import Tourding_FE
import NMapsMap

@MainActor
struct MarkerPassingTests {

    // 위도 1도 ≈ 111,195m (앱의 calculateDistance가 쓰는 R = 6,371,000 기준)
    private static let metersPerDegreeLatitude = 111_195.0
    private static let baseLat = 36.0
    private static let baseLng = 129.38

    /// 기준점에서 북쪽으로 `meters` 떨어진 좌표
    private func point(_ meters: Double) -> NMGLatLng {
        NMGLatLng(lat: Self.baseLat + meters / Self.metersPerDegreeLatitude, lng: Self.baseLng)
    }

    private func guide(sequenceNum: Int, type: Int, meters: Double) -> GuideModel {
        let coordinate = point(meters)
        return GuideModel(
            sequenceNum: sequenceNum,
            distance: 100,
            duration: 30,
            instructions: "안내\(sequenceNum)",
            locationName: "지점\(sequenceNum)",
            pointIndex: sequenceNum,
            type: type,
            lon: String(coordinate.lng),
            lat: String(coordinate.lat)
        )
    }

    /// 라이딩 중 상태를 구성한다. 마커는 `metersFromBase` 위치에 순서대로 놓인다.
    private func makeRidingViewModel(markersAt metersFromBase: [Double],
                                     types: [Int]? = nil) -> RidingViewModel {
        let viewModel = makeTestRidingViewModel()
        viewModel.flag = true

        let guideTypes = types ?? Array(repeating: 6, count: metersFromBase.count)   // 6 = 직진
        viewModel.guideList = metersFromBase.enumerated().map { index, meters in
            guide(sequenceNum: index, type: guideTypes[index], meters: meters)
        }
        viewModel.markerCoordinates = metersFromBase.map { point($0) }
        viewModel.markerIcons = metersFromBase.map { _ in MarkerIcons.straightMarker }
        return viewModel
    }

    // MARK: - 기준 동작 (현재도 맞아야 하는 것)

    @Test func consumesNothingWhenNoMarkerIsWithinThreshold() async {
        let viewModel = makeRidingViewModel(markersAt: [0, 200, 400])

        // 모든 마커에서 100m 이상 떨어진 지점
        await viewModel.updateUserLocationAndCheckMarkers(point(-100))

        #expect(viewModel.guideList.count == 3)
        #expect(viewModel.markerCoordinates.count == 3)
    }

    @Test func consumesOneWhenSingleMarkerIsWithinThreshold() async {
        let viewModel = makeRidingViewModel(markersAt: [0, 200, 400])

        // 마커0에서 10m — 마커1은 190m라 임계값 밖
        await viewModel.updateUserLocationAndCheckMarkers(point(10))

        #expect(viewModel.guideList.count == 2)
        #expect(viewModel.guideList.first?.sequenceNum == 1)
    }

    // MARK: - 재현: 안내 건너뛰기

    /// 한 번의 위치 갱신은 안내를 **한 칸만** 소비해야 한다.
    /// 두 칸 이상 사라지면 그 사이 안내는 화면에 한 번도 뜨지 않는다.
    @Test func consumesAtMostOneGuidancePerLocationUpdate() async {
        // 마커0·마커1이 25m 간격 — 실제 fixture에도 20m대 구간이 있다
        let viewModel = makeRidingViewModel(markersAt: [0, 25, 300])

        // 마커0에서 20m, 마커1에서 5m — 둘 다 임계값 30m 안
        await viewModel.updateUserLocationAndCheckMarkers(point(20))

        #expect(viewModel.guideList.count == 2, "한 번에 한 칸만 소비해야 한다")
        #expect(viewModel.guideList.first?.sequenceNum == 1, "마커1 안내가 지금 표시될 차례다")
    }

    /// GPS가 튀거나 끊겼다 이어져도 중간 경유지 안내가 소리 없이 사라지면 안 된다
    @Test func doesNotSilentlyConsumeWaypointGuidanceOnGpsJump() async {
        // 20m 간격으로 4개, 인덱스 1·2가 경유지(type 9)
        let viewModel = makeRidingViewModel(markersAt: [0, 20, 40, 60],
                                            types: [6, 9, 9, 10])

        // 마커3 근처로 점프 (마커2는 15m, 마커3은 5m — 둘 다 임계값 안)
        await viewModel.updateUserLocationAndCheckMarkers(point(55))

        let remainingWaypoints = viewModel.guideList.filter { $0.type == 9 }
        #expect(remainingWaypoints.isEmpty == false, "경유지 안내가 표시 없이 사라지면 안 된다")
    }

    // MARK: - 배열 정합성

    @Test func keepsGuideAndMarkerArraysAlignedAfterConsumption() async {
        let viewModel = makeRidingViewModel(markersAt: [0, 200, 400])

        await viewModel.updateUserLocationAndCheckMarkers(point(10))

        #expect(viewModel.markerCoordinates.count == viewModel.markerIcons.count)
        #expect(viewModel.markerCoordinates.count == viewModel.guideList.count)
    }

    /// 라이딩 중이 아니면 아무것도 소비하지 않는다
    @Test func consumesNothingWhenNotRiding() async {
        let viewModel = makeRidingViewModel(markersAt: [0, 200, 400])
        viewModel.flag = false

        await viewModel.updateUserLocationAndCheckMarkers(point(10))

        #expect(viewModel.guideList.count == 3)
    }
}
