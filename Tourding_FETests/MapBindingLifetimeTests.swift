//
//  MapBindingLifetimeTests.swift
//  Tourding_FETests
//
//  P0-2 — RidingViewModel ↔ MapViewController 강한 순환 참조로 GPS가 화면 이탈 후에도 잔존
//  P0-3 — setupUserLocationManager 콜백이 LocationManager 자신을 강하게 캡처
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct MapBindingLifetimeTests {

    // MARK: - P0-2

    /// MapViewController는 ViewModel을 소유하면 안 된다.
    /// 소유하면 앱 수명 ViewModel ↔ 화면 수명 Controller 사이에 순환이 생긴다.
    @Test func mapViewControllerDoesNotRetainViewModel() {
        let controller = MapViewController()
        weak var weakViewModel: RidingViewModel?

        autoreleasepool {
            let viewModel = makeTestRidingViewModel()
            weakViewModel = viewModel
            controller.ridingViewModel = viewModel
        }

        #expect(weakViewModel == nil)
    }

    /// 앱 수명 ViewModel은 화면 수명 MapViewController를 소유하면 안 된다.
    /// 소유하면 화면을 떠난 뒤에도 VC와 그 CLLocationManager가 살아남는다.
    @Test func viewModelDoesNotRetainMapViewController() {
        let viewModel = makeTestRidingViewModel()
        weak var weakController: MapViewController?

        autoreleasepool {
            let controller = MapViewController()
            weakController = controller
            viewModel.mapViewController = controller
            viewModel.markerManager = controller.markerManager
            viewModel.pathManager = controller.pathManager
        }

        #expect(weakController == nil)
        #expect(viewModel.mapViewController == nil)
    }

    /// ViewModel이 화면의 LocationManager를 소유하면 화면을 떠나도 GPS가 계속 돈다.
    @Test func viewModelDoesNotRetainLocationManager() {
        let viewModel = makeTestRidingViewModel()
        weak var weakLocationManager: LocationManager?

        autoreleasepool {
            let locationManager = LocationManager()
            weakLocationManager = locationManager
            viewModel.configureLocationManager(locationManager)
            viewModel.locationManager = locationManager
        }

        #expect(weakLocationManager == nil)
    }

    // MARK: - P0-3

    /// 콜백이 LocationManager 자신을 강하게 캡처하면 자기 참조 순환이 되어 절대 해제되지 않는다.
    @Test func setupUserLocationManagerDoesNotRetainLocationManager() {
        let controller = MapViewController()
        weak var weakLocationManager: LocationManager?

        autoreleasepool {
            let locationManager = LocationManager()
            weakLocationManager = locationManager
            controller.setupUserLocationManager(locationManager)
            controller.userLocationManager = nil
        }

        #expect(weakLocationManager == nil)
    }
}
