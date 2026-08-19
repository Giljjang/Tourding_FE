//
//  RidingStartZoomTests.swift
//  Tourding_FETests
//
//  라이딩을 시작할 때 카메라를 조금 당긴다.
//
//  처음엔 절대 줌(16.5)을 넣었는데 화면이 그대로였다.
//  편집 화면이 이미 건물 외곽선·지번이 보이는 수준(17~18)이라 16.5는 **축소** 방향이었다.
//  그래서 절대값이 아니라 **현재 줌 기준 상대값**으로 당긴다 — 기준이 뭐든 반드시 확대된다.
//
//  두 가지를 잠근다.
//  ① 값 계산 — 현재 줌에서 얼마나, 최대 줌을 넘지 않게
//  ② 게이트 — "처음 그 화면에 들어갔을 때" 한 번만
//
//  실제 카메라 이동은 NMFMapView가 필요해 테스트하지 않는다.
//

import CoreLocation
import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RidingStartZoomTests {

    /// 측위가 끝난 상태의 매니저. 줌 게이트는 `currentLocation`이 있어야 열린다.
    private func makeLocatedManager() -> LocationManager {
        let locationManager = LocationManager()
        locationManager.currentLocation = CLLocation(latitude: 36.0, longitude: 129.0)
        return locationManager
    }

    // MARK: - 값 계산

    /// 현재 줌에서 그만큼 더 당긴다
    @Test func zoomsInFromWhateverTheCurrentZoomIs() {
        #expect(LocationManager.ridingStartZoom(from: 14, maxZoom: 21)
                == 14 + LocationManager.ridingStartZoomDelta)
        #expect(LocationManager.ridingStartZoom(from: 17.4, maxZoom: 21)
                == 17.4 + LocationManager.ridingStartZoomDelta)
    }

    /// **핵심** — 확대여야 한다. 절대값을 쓰다 축소되는 실수를 했다
    @Test func deltaZoomsInNotOut() {
        #expect(LocationManager.ridingStartZoomDelta > 0)
        #expect(LocationManager.ridingStartZoom(from: 18, maxZoom: 21) > 18)
    }

    /// 지도의 최대 줌을 넘지 않는다
    @Test func doesNotExceedMaxZoom() {
        #expect(LocationManager.ridingStartZoom(from: 20.5, maxZoom: 21) == 21)
        #expect(LocationManager.ridingStartZoom(from: 21, maxZoom: 21) == 21)
    }

    /// 한 번에 너무 많이 당기면 다음 안내가 화면 밖으로 나간다
    @Test func deltaIsModest() {
        #expect(LocationManager.ridingStartZoomDelta <= 3)
    }

    // MARK: - 게이트

    /// 라이딩 한 번에 줌은 **한 번만** 걸린다.
    ///
    /// 시작 경로가 여러 갈래고 서로 연달아 돈다 — `flag` 전이, 라이딩 시작 API,
    /// 비정상 종료 복구. 호출부마다 걸면 주행 중 화면 재진입에서도 다시 걸린다.
    @Test func zoomIsConsumedOnlyOncePerRiding() {
        let locationManager = makeLocatedManager()

        #expect(locationManager.consumeRidingStartZoom() == true)
        #expect(locationManager.consumeRidingStartZoom() == false, "두 번째부터는 현재 줌 유지")
        #expect(locationManager.consumeRidingStartZoom() == false)
    }

    /// 라이딩이 끝나면 다음 시작에 다시 걸린다
    @Test func zoomIsAvailableAgainAfterReset() {
        let locationManager = makeLocatedManager()
        _ = locationManager.consumeRidingStartZoom()

        locationManager.resetRidingStartZoom()

        #expect(locationManager.consumeRidingStartZoom() == true)
    }

    /// 지도를 밀어 추적이 꺼졌다 재개돼도 다시 걸리지 않는다.
    /// `stopNavigationMode`는 주행 중 수시로 불리므로 여기서 리셋하면 안 된다.
    @Test func stoppingNavigationDoesNotRearmZoom() {
        let locationManager = makeLocatedManager()
        _ = locationManager.consumeRidingStartZoom()

        locationManager.stopNavigationMode()

        #expect(locationManager.consumeRidingStartZoom() == false,
                "추적을 껐다 켜는 것으로 줌이 다시 걸리면 주행 중 배율이 날아간다")
    }

    /// 위치가 없으면 카메라를 옮길 수 없으므로 게이트도 열지 않는다.
    /// 열어버리면 줌이 적용되지 않은 채 소진돼 영영 걸리지 않는다.
    @Test func gateStaysClosedWithoutLocation() {
        let locationManager = LocationManager()

        #expect(locationManager.currentLocation == nil, "전제: 아직 측위 전")
        #expect(locationManager.consumeRidingStartZoom() == false)

        locationManager.currentLocation = CLLocation(latitude: 36.0, longitude: 129.0)

        #expect(locationManager.consumeRidingStartZoom() == true, "측위 후 첫 시작에 걸린다")
    }
}
