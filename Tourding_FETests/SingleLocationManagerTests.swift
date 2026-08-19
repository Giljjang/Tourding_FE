//
//  SingleLocationManagerTests.swift
//  Tourding_FETests
//
//  D2 — LocationManager가 두 벌 돌던 문제.
//
//  MapViewController가 자체 `LocationManager`를 강하게 소유했고, RidingView는 `@StateObject`로
//  또 하나를 들었다. `LocationManager`는 생성만으로 GPS가 켜진다 —
//  setupLocationManager가 delegate + 권한 요청을 걸고, 권한 콜백이 startUpdatingLocation을 부른다.
//
//  MapViewController 쪽 인스턴스는 용도가 마커 방위 갱신 하나뿐인데도, 정지가 deinit에서만
//  일어나 화면이 살아 있는 동안 편집·라이딩과 무관하게 계속 돌았다.
//
//  구조 변경(저장 프로퍼티 삭제) 자체는 유닛테스트로 잡을 수 없다.
//  여기서 잠그는 것은 관측 가능한 계약 둘이다 —
//  ① ViewModel이 보는 두 참조가 같은 객체다  ② MapViewController가 하나도 소유하지 않는다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct SingleLocationManagerTests {

    /// ViewModel의 지도용 참조와 위치용 참조는 같은 인스턴스여야 한다.
    /// 서로 다른 객체를 가리키면 GPS·나침반 스트림이 두 벌 돈다.
    @Test func viewModelSharesOneLocationManager() {
        let viewModel = makeTestRidingViewModel()
        let manager = LocationManager()

        viewModel.configureLocationManager(manager)

        #expect(viewModel.userLocationManager === manager)
        #expect(viewModel.locationManager === manager,
                "지도용 참조가 별도 인스턴스를 가리키면 GPS가 두 벌 돈다")
    }

    /// MapViewController는 LocationManager를 **소유하지 않는다**. 주입만 받는다.
    ///
    /// 저장 프로퍼티를 다시 추가하는 회귀를 잡기 위해 Mirror로 직접 확인한다.
    /// (`userLocationManager`는 weak 옵셔널이고 이 테스트에서는 주입하지 않으므로 nil이다.)
    @Test func mapViewControllerOwnsNoLocationManager() {
        let controller = MapViewController()

        let owned = Mirror(reflecting: controller).children.contains { $0.value is LocationManager }

        #expect(owned == false,
                "MapViewController가 자체 LocationManager를 가지면 GPS가 두 벌 돈다")
    }

    // MARK: - 추천 코스 화면

    /// 추천 코스 화면도 같은 구조였다. 그쪽 자체 인스턴스는 콜백조차 없이
    /// `startLocationUpdates()`만 불러 — 아무 일도 하지 않으면서 GPS만 켰다.
    @Test func recommendMapViewControllerOwnsNoLocationManager() {
        let controller = RecommendMapViewController()

        let owned = Mirror(reflecting: controller).children.contains { $0.value is LocationManager }

        #expect(owned == false,
                "추천 코스 화면이 자체 LocationManager를 가지면 GPS가 두 벌 돈다")
    }

    /// 추천 코스 ViewModel도 두 참조가 같은 인스턴스를 가리켜야 한다
    @Test func recommendViewModelSharesOneLocationManager() {
        let viewModel = RecommendRouteViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: FakeRouteRepository(),
            userSession: FakeUserSession(userId: 49)
        )
        let manager = LocationManager()

        viewModel.configureLocationManager(manager)

        #expect(viewModel.userLocationManager === manager)
        #expect(viewModel.locationManager === manager)
    }
}
