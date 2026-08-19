//
//  PathManagerTests.swift
//  Tourding_FETests
//
//  C1 — 경로선을 매 갱신마다 전부 다시 그리던 문제.
//
//  `MapViewRepresentable.updateUIView`가 `updateMap()`을 무조건 부르고, 그 안에서
//  `setCoordinates`가 좌표 비교 없이 매번 단순화 + 오버레이 detach·재생성·재부착을 했다.
//  라이딩 중에는 위치·가이드·마커가 계속 바뀌므로 `updateUIView`가 반복 호출된다.
//
//  가드를 넣을 때 **개수만 비교하면 안 된다** — 경유지 DnD 재정렬은 개수가 그대로이고
//  순서만 바뀐다. 그러면 드래그해도 경로선이 갱신되지 않는다.
//  그 함정을 여기서 잠근다.
//
//  `PathManager` 자체는 생성에 `NMFMapView`가 필요해 인스턴스를 만들 수 없다.
//  판정만 static으로 떼어내 테스트한다.
//

import Foundation
import NMapsMap
import Testing
@testable import Tourding_FE

struct PathManagerTests {

    private func coords(_ pairs: [(Double, Double)]) -> [NMGLatLng] {
        pairs.map { NMGLatLng(lat: $0.0, lng: $0.1) }
    }

    /// 같은 좌표열이면 다시 그리지 않는다
    @Test func sameSequenceIsRecognized() {
        let a = coords([(36.0, 129.0), (36.1, 129.1), (36.2, 129.2)])
        let b = coords([(36.0, 129.0), (36.1, 129.1), (36.2, 129.2)])

        #expect(PathManager.isSameSequence(a, b))
    }

    /// **핵심** — `NMGLatLng`은 클래스다. 참조가 아니라 값으로 비교해야 한다.
    /// 참조 비교면 매번 새 인스턴스가 오므로 가드가 영원히 발동하지 않는다.
    @Test func differentInstancesWithSameValuesAreSame() {
        let a = [NMGLatLng(lat: 36.0, lng: 129.0)]
        let b = [NMGLatLng(lat: 36.0, lng: 129.0)]

        #expect(a[0] !== b[0], "전제: 서로 다른 인스턴스다")
        #expect(PathManager.isSameSequence(a, b))
    }

    /// **핵심** — 경유지 DnD 재정렬은 개수가 같고 순서만 바뀐다.
    /// 개수만 비교하면 드래그해도 경로선이 갱신되지 않는다.
    @Test func reorderedSequenceIsDifferent() {
        let original = coords([(36.0, 129.0), (36.1, 129.1), (36.2, 129.2)])
        let reordered = coords([(36.0, 129.0), (36.2, 129.2), (36.1, 129.1)])

        #expect(original.count == reordered.count, "전제: 개수는 같다")
        #expect(PathManager.isSameSequence(original, reordered) == false,
                "순서가 바뀌면 다시 그려야 한다")
    }

    @Test func differentCountIsDifferent() {
        let a = coords([(36.0, 129.0), (36.1, 129.1)])
        let b = coords([(36.0, 129.0), (36.1, 129.1), (36.2, 129.2)])

        #expect(PathManager.isSameSequence(a, b) == false)
    }

    @Test func singleChangedValueIsDifferent() {
        let a = coords([(36.0, 129.0), (36.1, 129.1)])
        let b = coords([(36.0, 129.0), (36.1, 129.2)])

        #expect(PathManager.isSameSequence(a, b) == false)
    }

    @Test func emptySequencesAreSame() {
        #expect(PathManager.isSameSequence([], []))
    }

    @Test func emptyAndNonEmptyAreDifferent() {
        #expect(PathManager.isSameSequence([], coords([(36.0, 129.0)])) == false)
    }
}
