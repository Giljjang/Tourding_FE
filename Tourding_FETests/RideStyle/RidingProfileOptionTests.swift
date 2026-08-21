//
//  RidingProfileOptionTests.swift
//  Tourding_FETests
//
//  라이딩 스타일(riding-profile)을 경로 요청에 싣는다.
//
//  서버가 POST /routes 에 `routeOption`을 받아 경로 계산에 반영하도록 바뀌었다.
//  앱은 GET /user/{id}/riding-profile 로 읽은 값을 그대로 실어 보낸다.
//
//  **언제 다시 읽는가가 이 기능의 핵심이다.**
//  코스 편집 화면에서 라이딩 스타일을 바꾸고 뒤로 오면, 그 다음 라이딩은
//  바뀐 스타일로 시작해야 한다. 진입 때 한 번만 읽으면 옛 스타일로 경로가 나온다.
//
//  값은 **POST 직전에** `RidingProfileStore`에서 읽는다 — 진입 때의 스냅샷이 아니다.
//  스냅샷만 쓰면 진입 조회가 실패했을 때 세션 내내 nil로 남는다.
//  실패해도 저장소가 마지막 성공값으로 폴백하므로
//  라이딩은 막히지 않는다 — nil로 떨어지면 서버가 **디폴트로** 계산해
//  사용자 설정이 조용히 무시되기 때문이다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RidingProfileOptionTests {

    private let sampleOption = RouteOptionModel(
        cyclingProfile: "ROAD", fastRoute: true,
        avoidSteps: true, avoidFords: false, skillLevel: "INTERMEDIATE"
    )

    /// fake 기본값과 **다른** 값. 같은 값을 쓰면 배선이 끊겨도 통과한다.
    private let distinctOption = RouteOptionModel(
        cyclingProfile: "MTB", fastRoute: false,
        avoidSteps: false, avoidFords: true, skillLevel: "BEGINNER"
    )

    private func storeReturning(_ option: RouteOptionModel) -> RidingProfileStore {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = option
        return RidingProfileStore(userRepository: userRepository)
    }

    private var route: [LocationNameModel] {
        [
            TestRoute.location(sequenceNum: 0, name: "출발", type: "Start", lat: "37.0", lon: "127.0"),
            TestRoute.location(sequenceNum: 1, name: "경유", type: "WayPoint", lat: "37.1", lon: "127.1"),
            TestRoute.location(sequenceNum: 2, name: "도착", type: "Goal", lat: "37.2", lon: "127.2")
        ]
    }

    // MARK: - 조회

    /// 조회한 스타일을 ViewModel이 들고 있어야 POST에 실을 수 있다
    @Test func loadsRidingProfileIntoViewModel() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = sampleOption
        let viewModel = makeTestRidingViewModel(
            profileStore: RidingProfileStore(userRepository: userRepository), userId: 49
        )

        await viewModel.loadRidingProfile()

        #expect(viewModel.routeOption == sampleOption)
        #expect(userRepository.capturedProfileUserIds == [49])
    }

    /// 한 번도 못 읽었고 조회까지 실패하면 줄 값이 없다.
    /// 이때만 nil이고, 그 경로는 서버 디폴트로 계산된다.
    @Test func keepsOptionNilWhenProfileLoadFails() async {
        let userRepository = FakeUserRepository()
        userRepository.getRidingProfileError = FakeUserRepository.FakeError.notConfigured
        let viewModel = makeTestRidingViewModel(
            profileStore: RidingProfileStore(userRepository: userRepository)
        )

        await viewModel.loadRidingProfile()

        #expect(viewModel.routeOption == nil)
    }

    /// 조회에 실패해도 직전 값을 지우지는 않는다 —
    /// 스타일을 바꾸지 않고 돌아왔는데 네트워크가 끊기면 옛 값이라도 쓰는 편이 낫다
    @Test func failedReloadKeepsPreviousOption() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = sampleOption
        let viewModel = makeTestRidingViewModel(
            profileStore: RidingProfileStore(userRepository: userRepository)
        )
        await viewModel.loadRidingProfile()

        userRepository.getRidingProfileError = FakeUserRepository.FakeError.notConfigured
        await viewModel.loadRidingProfile()

        #expect(viewModel.routeOption == sampleOption)
    }

    // MARK: - 다시 읽는 시점

    /// **핵심** — 라이딩 스타일 화면에서 돌아오면 다시 읽는다.
    /// 진입 때 한 번만 읽으면 방금 바꾼 스타일이 반영되지 않는다.
    @Test func reloadsProfileWhenReturningFromChildScreen() async {
        let userRepository = FakeUserRepository()
        let viewModel = makeTestRidingViewModel(
            profileStore: RidingProfileStore(userRepository: userRepository)
        )
        let locationManager = LocationManager()

        viewModel.handleReturnFromChild(locationManager: locationManager, routeSource: .draft)
        await viewModel.pendingProfileLoad?.value

        #expect(userRepository.getRidingProfileCallCount == 1)
    }

    /// 라이딩 중에는 다시 읽지 않는다 — 주행 중 경로를 바꿀 일이 없다
    @Test func doesNotReloadProfileWhileRiding() async {
        let userRepository = FakeUserRepository()
        let viewModel = makeTestRidingViewModel(
            profileStore: RidingProfileStore(userRepository: userRepository)
        )
        viewModel.flag = true

        viewModel.handleReturnFromChild(locationManager: LocationManager(), routeSource: .draft)
        await viewModel.pendingProfileLoad?.value

        #expect(userRepository.getRidingProfileCallCount == 0)
    }

    // MARK: - 요청에 싣기

    /// 라이딩 시작 POST가 스타일을 싣는다 — 실제로 경로 계산에 반영되는 지점이다
    @Test func ridingStartCarriesRouteOption() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(
            repository: repository, profileStore: storeReturning(distinctOption)
        )

        _ = await viewModel.postRidingStartAPI(locationData: route)

        #expect(repository.capturedPostRoutes.last?.routeOption == distinctOption)
    }

    /// 경유지 드래그앤드롭 재정렬도 같은 스타일로 다시 계산돼야 한다
    @Test func dragAndDropReorderCarriesRouteOption() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(
            repository: repository, profileStore: storeReturning(distinctOption)
        )

        await viewModel.postRouteDragNDropAPI(locationData: route)

        #expect(repository.capturedPostRoutes.last?.routeOption == distinctOption)
    }

    /// 경유지 삭제도 마찬가지다
    @Test func waypointDeleteCarriesRouteOption() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(
            repository: repository, profileStore: storeReturning(distinctOption)
        )

        await viewModel.postRouteDeleteAPI(originalData: route, selectedData: route[1])

        #expect(repository.capturedPostRoutes.last?.routeOption == distinctOption)
    }

    /// 스타일을 한 번도 못 읽었으면 `null` 대신 키를 빼고 보낸다.
    /// 이 경로는 서버 디폴트로 계산된다 — 피할 수 없는 마지막 수단이다.
    @Test func omitsRouteOptionWhenProfileUnavailable() async {
        let repository = FakeRouteRepository()
        let userRepository = FakeUserRepository()
        userRepository.getRidingProfileError = FakeUserRepository.FakeError.notConfigured
        let viewModel = makeTestRidingViewModel(
            repository: repository,
            profileStore: RidingProfileStore(userRepository: userRepository)
        )

        _ = await viewModel.postRidingStartAPI(locationData: route)

        #expect(repository.capturedPostRoutes.last?.routeOption == nil)
    }
}
