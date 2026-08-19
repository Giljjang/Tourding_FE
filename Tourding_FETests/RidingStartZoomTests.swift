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

import CoreLocation
import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RidingStartZoomTests {

    /// 측위가 끝난 상태의 매니저. 줌 소비는 `currentLocation`이 있어야 일어난다.
    private func makeLocatedManager() -> LocationManager {
        let locationManager = LocationManager()
        locationManager.currentLocation = CLLocation(latitude: 36.0, longitude: 129.0)
        return locationManager
    }

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

    // MARK: - 한 번만 적용

    /// 라이딩 한 번에 줌은 **한 번만** 걸린다.
    ///
    /// 시작 경로가 여러 갈래다 — `flag` 전이(activateRidingLocationTracking),
    /// 라이딩 시작 API(startRidingAPIProcess), 비정상 종료 복구(onAppear).
    /// 정상 시작과 비정상 복구 모두 둘 이상이 연달아 돌기 때문에,
    /// 호출부마다 줌을 넘기면 주행 중 화면 재진입에서도 다시 줌이 걸린다.
    @Test func zoomIsConsumedOnlyOncePerRiding() {
        let locationManager = makeLocatedManager()

        #expect(locationManager.consumeRidingStartZoom() == LocationManager.ridingStartZoom)
        #expect(locationManager.consumeRidingStartZoom() == nil, "두 번째부터는 현재 줌을 유지한다")
        #expect(locationManager.consumeRidingStartZoom() == nil)
    }

    /// 라이딩이 끝나면 다음 시작에 다시 걸린다
    @Test func zoomIsAvailableAgainAfterReset() {
        let locationManager = makeLocatedManager()
        _ = locationManager.consumeRidingStartZoom()

        locationManager.resetRidingStartZoom()

        #expect(locationManager.consumeRidingStartZoom() == LocationManager.ridingStartZoom)
    }

    /// 지도를 밀어 추적이 꺼졌다 재개돼도 줌은 다시 걸리지 않는다.
    /// `stopNavigationMode`는 주행 중에 수시로 불리므로 여기서 리셋하면 안 된다.
    @Test func stoppingNavigationDoesNotRearmZoom() {
        let locationManager = makeLocatedManager()
        _ = locationManager.consumeRidingStartZoom()

        locationManager.stopNavigationMode()

        #expect(locationManager.consumeRidingStartZoom() == nil,
                "추적을 껐다 켜는 것으로 줌이 다시 걸리면 주행 중 배율이 날아간다")
    }

    // MARK: - 적용할 수 없으면 소비하지 않는다

    /// **위치가 없으면 카메라를 옮길 수 없으므로 줌도 소비하면 안 된다.**
    ///
    /// `startNavigationMode`는 `currentLocation`이 있을 때만 카메라를 옮긴다.
    /// 그런데 게이트가 호출부에서 먼저 열리면, GPS 첫 측위 전에 시작 경로가 돌 때
    /// 줌이 적용되지 않은 채 소비돼 영영 걸리지 않는다.
    /// 시작 경로가 셋이라 그중 하나만 위치 없이 먼저 돌아도 잃는다.
    @Test func zoomIsNotConsumedWithoutLocation() {
        let locationManager = LocationManager()

        #expect(locationManager.currentLocation == nil, "전제: 아직 측위 전")
        #expect(locationManager.consumeRidingStartZoom() == nil, "적용할 수 없으면 소비도 안 한다")

        locationManager.currentLocation = CLLocation(latitude: 36.0, longitude: 129.0)

        #expect(locationManager.consumeRidingStartZoom() == LocationManager.ridingStartZoom,
                "측위 후 첫 시작에 줌이 걸려야 한다")
    }
}
