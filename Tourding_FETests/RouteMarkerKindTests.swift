//
//  RouteMarkerKindTests.swift
//  Tourding_FETests
//
//  CLAUDE.md 규칙 — "경유지 마커 번호는 배열 index가 아니라 WayPoint 순번(1, 2, 3…)".
//  이전에는 makeMarkerIcons가 NMFOverlayImage를 반환해 1번과 2번을 값으로 구분할 수 없어
//  이 규칙을 테스트로 고정할 방법이 없었다.
//

import Testing
@testable import Tourding_FE

struct RouteMarkerKindTests {

    @Test func numbersWaypointsSequentially() {
        let kinds = RidingViewModel.markerKinds(for: TestRoute.startTwoWaypointsGoal)

        #expect(kinds == [.start, .waypoint(number: 1), .waypoint(number: 2), .goal])
    }

    /// 출발·도착이 배열 양끝이 아니어도 경유지 순번은 1부터 연속이어야 한다
    @Test func waypointNumberIgnoresArrayIndex() {
        let route = [
            TestRoute.location(sequenceNum: 0, name: "경유A", type: "WayPoint", lat: "37.1", lon: "127.1"),
            TestRoute.location(sequenceNum: 1, name: "출발", type: "Start", lat: "37.0", lon: "127.0"),
            TestRoute.location(sequenceNum: 2, name: "경유B", type: "WayPoint", lat: "37.2", lon: "127.2")
        ]

        let kinds = RidingViewModel.markerKinds(for: route)

        #expect(kinds == [.waypoint(number: 1), .start, .waypoint(number: 2)])
    }

    @Test func mapsUnrecognizedTypeToUnknown() {
        let route = [
            TestRoute.location(sequenceNum: 0, name: "정체불명", type: "Something", lat: "37.0", lon: "127.0")
        ]

        #expect(RidingViewModel.markerKinds(for: route) == [.unknown])
    }

    @Test func emptyRouteProducesNoKinds() {
        #expect(RidingViewModel.markerKinds(for: []).isEmpty)
    }

    /// 아이콘 배열은 종류 배열에서 파생되므로 개수가 항상 같아야 한다
    @MainActor
    @Test func iconCountMatchesKindCount() {
        let route = TestRoute.recommendedCourseWithThreeWaypoints

        #expect(RidingViewModel.makeMarkerIcons(for: route).count
                == RidingViewModel.markerKinds(for: route).count)
    }
}
