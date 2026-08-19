//
//  RidingStartZoomTests.swift
//  Tourding_FETests
//
//  라이딩을 시작할 때 카메라 줌을 맞춘다.
//
//  줌을 설정하는 코드가 저장소 어디에도 없어 NMap 기본값을 그대로 썼다.
//  편집 모드는 경로 전체를 보느라 멀리 있는데, 라이딩 중에는 앞의 길이 보여야 한다.
//
//  **추적 재개에는 적용하면 안 된다.** "경로 안내 재개" 버튼이나 3m 자동 재개는
//  주행 중에 일어나는데, 그때 줌을 덮으면 사용자가 조정해 둔 배율이 날아간다.
//  그 구분이 이 테스트의 핵심이다.
//
//  실제 카메라 이동은 NMFMapView가 필요해 테스트하지 않는다. 정책만 잠근다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RidingStartZoomTests {

    /// 라이딩 시작에는 줌을 맞춘다
    @Test func ridingStartHasZoomLevel() {
        #expect(LocationManager.zoomLevel(for: .ridingStart) == LocationManager.ridingStartZoom)
    }

    /// **핵심** — 추적 재개에는 줌을 건드리지 않는다.
    /// 주행 중에 사용자가 맞춰 둔 배율을 덮으면 안 된다.
    @Test func resumingTrackingKeepsCurrentZoom() {
        #expect(LocationManager.zoomLevel(for: .resumeTracking) == nil)
    }

    /// 값이 지도에서 쓸 수 있는 범위여야 한다.
    /// NMap 줌은 0(세계) ~ 21(건물) 범위이고, 내비게이션은 거리 수준이다.
    @Test func ridingStartZoomIsAStreetLevelValue() {
        #expect(LocationManager.ridingStartZoom > 14, "너무 멀면 앞의 길이 안 보인다")
        #expect(LocationManager.ridingStartZoom < 19, "너무 가까우면 다음 안내가 화면 밖으로 나간다")
    }
}
