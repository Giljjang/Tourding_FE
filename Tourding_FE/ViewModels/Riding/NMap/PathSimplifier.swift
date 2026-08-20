//
//  PathSimplifier.swift
//  Tourding_FE
//
//  경로선 좌표 단순화 (Douglas-Peucker).
//
//  `PathManager`의 private 메서드였던 것을 떼어냈다. 지도 렌더링은 테스트 대상이 아니지만
//  좌표를 줄이는 계산은 순수 함수이고 전부 결정적이다.
//  계약은 `PathSimplifierTests`가 잠근다 — 실제 fixture 258좌표 → 239개를 포함한다.
//
//  실측: 258좌표(12.65km) 기준 7.4% 감소, 버려진 점의 최대 이탈 0.87m.
//  실효가 크지 않다. tolerance를 10배 키우면 72% 줄지만 이탈이 10m대라 자전거 경로엔 못 쓴다.
//

import Foundation
import NMapsMap

enum PathSimplifier {

    /// 위경도 **도(degree)** 단위 허용 오차. 위도 0.00001도 ≈ 1.1m.
    ///
    /// 주의: 경도 1도의 실거리는 위도에 따라 달라지므로(북위 36도에서 위도의 약 0.81배)
    /// 이 값은 방향에 따라 조금 다른 실거리를 뜻한다. 지금 규모에서는 무시할 수준이다.
    static let defaultTolerance: Double = 0.00001

    static func simplify(
        _ coordinates: [NMGLatLng],
        tolerance: Double = defaultTolerance
    ) -> [NMGLatLng] {
        guard coordinates.count > 2 else { return coordinates }
        return douglasPeucker(coordinates, tolerance: tolerance)
    }

    // MARK: - Private

    private static func douglasPeucker(
        _ points: [NMGLatLng],
        tolerance: Double
    ) -> [NMGLatLng] {
        // 교과서 구현과 다르다 — 3점짜리는 완전한 직선이어도 줄이지 않는다.
        // 옮기면서 동작을 바꾸지 않기 위해 그대로 뒀다 (PathSimplifierTests가 고정).
        if points.count <= 3 { return points }

        var maxDistance = 0.0
        var maxIndex = 0

        let firstPoint = points[0]
        let lastPoint = points[points.count - 1]

        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(points[i], lineStart: firstPoint, lineEnd: lastPoint)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }

        guard maxDistance > tolerance else {
            return [firstPoint, lastPoint]
        }

        let left = douglasPeucker(Array(points[0...maxIndex]), tolerance: tolerance)
        let right = douglasPeucker(Array(points[maxIndex..<points.count]), tolerance: tolerance)

        // 분할점이 양쪽에 중복으로 들어가므로 오른쪽의 첫 점을 버린다
        return left + right.dropFirst()
    }

    /// 점과 선분 사이의 수직 거리. 위경도를 평면 좌표로 취급한다.
    private static func perpendicularDistance(
        _ point: NMGLatLng,
        lineStart: NMGLatLng,
        lineEnd: NMGLatLng
    ) -> Double {
        let A = point.lat - lineStart.lat
        let B = point.lng - lineStart.lng
        let C = lineEnd.lat - lineStart.lat
        let D = lineEnd.lng - lineStart.lng

        let dot = A * C + B * D
        let lenSq = C * C + D * D

        if lenSq == 0 {
            return sqrt(A * A + B * B)
        }

        let param = dot / lenSq

        let xx: Double
        let yy: Double
        if param < 0 {
            xx = lineStart.lat
            yy = lineStart.lng
        } else if param > 1 {
            xx = lineEnd.lat
            yy = lineEnd.lng
        } else {
            xx = lineStart.lat + param * C
            yy = lineStart.lng + param * D
        }

        return sqrt(pow(point.lat - xx, 2) + pow(point.lng - yy, 2))
    }
}

/// 단순화가 실제로 얼마나 줄였는지.
struct PathSimplificationMetrics {
    let originalCount: Int
    let simplifiedCount: Int

    var removedCount: Int { originalCount - simplifiedCount }

    /// 감소율(%). 원본이 비어 있으면 0.
    var reductionRate: Double {
        guard originalCount > 0 else { return 0 }
        return Double(removedCount) / Double(originalCount) * 100
    }
}
