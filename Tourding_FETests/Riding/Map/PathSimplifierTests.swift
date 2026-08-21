//
//  PathSimplifierTests.swift
//  Tourding_FETests
//
//  E4 + C2 — 경로선 단순화를 `PathManager`에서 떼어내 테스트 가능하게 만든다.
//
//  단순화 로직은 `PathManager`의 private 메서드였고, `PathManager`는 생성에 `NMFMapView`가
//  필요해 테스트를 붙일 수 없었다. 지도 렌더링은 테스트 대상이 아니지만
//  **좌표를 줄이는 계산은 순수 함수**이고 전부 결정적이다.
//
//  아래 테스트 중 상당수는 **특성화 테스트**다 — 지금 동작이 옳다고 주장하는 게 아니라,
//  추출하면서 동작이 바뀌지 않았음을 보장하기 위해 현재 동작을 그대로 고정한다.
//  특히 `count <= 3`을 그대로 반환하는 것은 교과서 Douglas-Peucker와 다르다.
//

import Foundation
import NMapsMap
import Testing
@testable import Tourding_FE

struct PathSimplifierTests {

    private func coords(_ pairs: [(Double, Double)]) -> [NMGLatLng] {
        pairs.map { NMGLatLng(lat: $0.0, lng: $0.1) }
    }

    private func fixturePath() throws -> [NMGLatLng] {
        let paths: [RoutePathModel] = try FixtureLoader.load("routes_path_unused.json")
        return paths.compactMap {
            guard let lat = Double($0.lat), let lon = Double($0.lon) else { return nil }
            return NMGLatLng(lat: lat, lng: lon)
        }
    }

    // MARK: - 경계

    @Test func emptyInputStaysEmpty() {
        #expect(PathSimplifier.simplify([]).isEmpty)
    }

    @Test func twoPointsAreKept() {
        let input = coords([(36.0, 129.0), (36.1, 129.1)])

        #expect(PathSimplifier.simplify(input).count == 2)
    }

    /// **특성화** — 현재 구현은 3점짜리를 절대 줄이지 않는다.
    /// 교과서 Douglas-Peucker라면 완전한 직선 위의 가운데 점은 제거된다.
    /// 옳다고 주장하는 게 아니라 추출 전후가 같음을 보장하려고 고정한다.
    @Test func threePointsAreKeptEvenWhenCollinear() {
        let input = coords([(36.0, 129.0), (36.1, 129.0), (36.2, 129.0)])

        #expect(PathSimplifier.simplify(input).count == 3)
    }

    // MARK: - 단순화

    /// 직선 위에 놓인 중간점들은 제거된다 (4점 이상)
    @Test func collinearMidPointsAreRemoved() {
        let input = coords([
            (36.0, 129.0), (36.1, 129.0), (36.2, 129.0), (36.3, 129.0), (36.4, 129.0)
        ])

        let result = PathSimplifier.simplify(input)

        #expect(result.count == 2, "완전한 직선이면 양 끝만 남는다")
    }

    /// 허용 오차보다 크게 벗어난 점은 보존된다
    @Test func pointBeyondToleranceIsKept() {
        // 가운데 점이 경도로 0.001도(약 90m) 튀어나와 있다
        let input = coords([
            (36.0, 129.0), (36.1, 129.0), (36.2, 129.001), (36.3, 129.0), (36.4, 129.0)
        ])

        let result = PathSimplifier.simplify(input)

        #expect(result.count > 2, "튀어나온 점이 지워지면 경로 모양이 달라진다")
        #expect(result.contains { $0.lng == 129.001 })
    }

    /// 첫 점과 끝 점은 어떤 경우에도 보존된다
    @Test func endpointsArePreserved() throws {
        let input = coords([
            (36.0, 129.0), (36.1, 129.0), (36.2, 129.0), (36.3, 129.0), (36.4, 129.5)
        ])

        let result = PathSimplifier.simplify(input)
        let first = try #require(result.first)
        let last = try #require(result.last)

        #expect(first.lat == 36.0 && first.lng == 129.0)
        #expect(last.lat == 36.4 && last.lng == 129.5)
    }

    /// 순서가 뒤집히거나 섞이면 경로선이 엉킨다
    @Test func orderIsPreserved() {
        let input = coords([
            (36.0, 129.0), (36.1, 129.01), (36.2, 129.0), (36.3, 129.01), (36.4, 129.0)
        ])

        let result = PathSimplifier.simplify(input)
        let lats = result.map(\.lat)

        #expect(lats == lats.sorted(), "입력이 위도 오름차순이면 결과도 그래야 한다")
    }

    /// 허용 오차를 키우면 더 많이 지워진다
    @Test func largerToleranceRemovesMore() throws {
        let input = try fixturePath()

        let tight = PathSimplifier.simplify(input, tolerance: 0.000001)
        let loose = PathSimplifier.simplify(input, tolerance: 0.0001)

        #expect(loose.count < tight.count)
    }

    // MARK: - 실제 경로 (특성화)

    /// **특성화** — 실제 서버 응답 258좌표에서 현재 구현이 만드는 결과를 그대로 고정한다.
    /// 추출·리팩토링으로 이 숫자가 바뀌면 지도에 그려지는 경로선 모양이 달라진 것이다.
    @Test func realRouteIsSimplifiedToKnownCount() throws {
        let input = try fixturePath()

        #expect(input.count == 258, "전제: fixture가 258좌표다")
        #expect(PathSimplifier.simplify(input).count == 239)
    }

    // MARK: - 계측

    @Test func metricsReportReductionOfRealRoute() throws {
        let input = try fixturePath()

        let metrics = PathSimplificationMetrics(
            originalCount: input.count,
            simplifiedCount: PathSimplifier.simplify(input).count
        )

        #expect(metrics.removedCount == 19)
        #expect(abs(metrics.reductionRate - 7.36) < 0.05, "약 7.4% 감소")
    }

    /// 원본이 비어 있으면 0으로 나누지 않는다
    @Test func metricsHandleEmptyInput() {
        let metrics = PathSimplificationMetrics(originalCount: 0, simplifiedCount: 0)

        #expect(metrics.reductionRate == 0)
        #expect(metrics.removedCount == 0)
    }
}
