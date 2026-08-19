//
//  CameraFollowTests.swift
//  Tourding_FETests
//
//  카메라가 사용자를 따라갈지 판정하는 **단일 지점**.
//
//  라이딩 중 지도를 밀어놔도 다음 GPS 갱신(3m)에 카메라가 도로 사용자 위치로 스냅됐다.
//  카메라를 옮기는 세 곳(MapViewController.updateUserLocation,
//  RidingViewModel.updateCameraToUserLocation, RidingView 바텀시트)이
//  "추적 중인가"(isNavigationMode)가 아니라 "라이딩 중인가"(flag)로 판정했기 때문이다.
//
//  판정을 세 번 복붙하다 세 번 다 빠뜨린 형태라, 판정 자체를 한 곳으로 모으고 여기서 잠근다.
//

import Foundation
import CoreLocation
import Testing
@testable import Tourding_FE

@MainActor
struct CameraFollowTests {

    /// 추적을 시작하기 전에는 따라가지 않는다.
    ///
    /// `isLocationTrackingEnabled`는 초기값이 `true`라 이 값을 기준으로 삼으면 여기서 깨진다.
    /// 두 플래그는 한 번이라도 전이가 일어난 뒤에만 같아진다 — 초기 상태에서는 다르다.
    @Test func doesNotFollowBeforeNavigationModeStarts() {
        let locationManager = LocationManager()

        #expect(locationManager.isLocationTrackingEnabled == true, "전제: 초기값이 true다")
        #expect(locationManager.isNavigationMode == false, "전제: 초기값이 false다")
        #expect(locationManager.shouldFollowUser == false)
    }

    /// 추적 중이면 따라간다
    @Test func followsWhileNavigationModeIsOn() {
        let locationManager = LocationManager()
        locationManager.isNavigationMode = true

        #expect(locationManager.shouldFollowUser == true)
    }

    /// 지도를 밀면 더 이상 따라가지 않는다 — 보고된 증상의 핵심
    @Test func screenTouchStopsFollowing() {
        let locationManager = LocationManager()
        locationManager.isNavigationMode = true
        #expect(locationManager.shouldFollowUser == true, "전제: 추적 중")

        locationManager.handleScreenTouch()

        #expect(locationManager.shouldFollowUser == false,
                "지도를 민 뒤에는 GPS가 갱신돼도 카메라가 따라가면 안 된다")
    }

    /// 라이딩 종료 경로에서도 꺼진다
    @Test func stopNavigationModeStopsFollowing() {
        let locationManager = LocationManager()
        locationManager.isNavigationMode = true
        #expect(locationManager.shouldFollowUser == true, "전제: 추적 중")

        locationManager.stopNavigationMode()

        #expect(locationManager.shouldFollowUser == false)
    }

    // MARK: - "경로 안내 재개" 버튼

    /// 지도를 밀어 추적을 끈 뒤 재개 버튼을 누르면 다시 따라가야 한다.
    ///
    /// `toggleLocationTracking`이 `getCurrentMapView()`(= `currentMapView`)에 의존했는데,
    /// 이 참조는 `configureLocationManager`가 `onAppear`에서 **한 번만**, 그것도
    /// `if let mapView` 가드 뒤에서 설정한다. `updateUIView`보다 `onAppear`가 먼저 돌면
    /// 영영 nil로 남아 재개 버튼이 상태를 켜지 못한다.
    @Test func resumingTrackingWorksWithoutMapViewReference() {
        let locationManager = LocationManager()
        locationManager.isNavigationMode = true
        locationManager.handleScreenTouch()
        #expect(locationManager.shouldFollowUser == false, "전제: 지도를 밀어 추적이 꺼진 상태")

        locationManager.toggleLocationTracking()

        #expect(locationManager.shouldFollowUser == true,
                "mapView 참조가 없어도 재개 버튼은 추적을 켜야 한다")
    }

    /// 재개 버튼은 토글이다 — 한 번 더 누르면 꺼진다
    @Test func togglingAgainStopsFollowing() {
        let locationManager = LocationManager()

        locationManager.toggleLocationTracking()
        #expect(locationManager.shouldFollowUser == true, "전제: 추적이 켜진 상태")

        locationManager.toggleLocationTracking()

        #expect(locationManager.shouldFollowUser == false)
    }
}
