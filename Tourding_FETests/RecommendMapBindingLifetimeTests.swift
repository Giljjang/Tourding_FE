//
//  RecommendMapBindingLifetimeTests.swift
//  Tourding_FETests
//
//  RidingViewModel ↔ MapViewController는 P0-2에서 양방향 weak으로 끊었지만
//  추천 코스 쪽은 그대로 남아 있었다.
//
//    RecommendRouteViewModel  --strong-->  RecommendMapViewController
//    RecommendMapViewController --strong-->  RecommendRouteViewModel
//
//  순환이라 화면을 pop해도 둘 다 해제되지 않는다. VC가 들고 있는
//  LocationManager도 함께 살아남아 GPS가 계속 돈다.
//  ViewModel이 화면 수명(@StateObject)이라, 추천 코스 화면에 들어갈 때마다
//  한 세트씩 쌓인다.
//
//  소유자는 화면(Coordinator가 VC를 보유하고 updateUIView가 매번 다시 연결한다).
//  ViewModel은 빌려 쓰기만 해야 한다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RecommendMapBindingLifetimeTests {

    private func makeViewModel() -> RecommendRouteViewModel {
        RecommendRouteViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: FakeRouteRepository(),
            userSession: FakeUserSession(userId: 49)
        )
    }

    /// MapViewController는 ViewModel을 소유하면 안 된다 (역방향 끊기)
    @Test func recommendMapViewControllerDoesNotRetainViewModel() {
        let controller = RecommendMapViewController()
        weak var weakViewModel: RecommendRouteViewModel?

        autoreleasepool {
            let viewModel = makeViewModel()
            weakViewModel = viewModel
            controller.recommendRouteViewModel = viewModel
        }

        #expect(weakViewModel == nil)
    }

    /// ViewModel은 화면 수명 MapViewController를 소유하면 안 된다 (정방향 끊기)
    @Test func recommendViewModelDoesNotRetainMapViewController() {
        let viewModel = makeViewModel()
        weak var weakController: RecommendMapViewController?

        autoreleasepool {
            let controller = RecommendMapViewController()
            weakController = controller
            viewModel.mapViewController = controller
            viewModel.markerManager = controller.markerManager
            viewModel.pathManager = controller.pathManager
        }

        #expect(weakController == nil, "VC가 살아 있으면 그 LocationManager도 함께 남아 GPS가 계속 돈다")
    }

    /// LocationManager도 화면 소유다 — ViewModel이 붙잡으면 GPS가 잔존한다
    @Test func recommendViewModelDoesNotRetainLocationManager() {
        let viewModel = makeViewModel()
        weak var weakManager: LocationManager?

        autoreleasepool {
            let manager = LocationManager()
            weakManager = manager
            viewModel.locationManager = manager
            viewModel.userLocationManager = manager
        }

        #expect(weakManager == nil)
    }
}
