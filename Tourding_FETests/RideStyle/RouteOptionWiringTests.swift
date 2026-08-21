//
//  RouteOptionWiringTests.swift
//  Tourding_FETests
//
//  경로를 만드는 **모든** 호출부가 라이딩 스타일을 싣는지 잠근다.
//
//  서버는 `routeOption`이 없으면 디폴트로 계산한다 — 저장된 프로필을 꺼내 쓰지 않는다.
//  그래서 한 곳이라도 빠지면 그 화면에서 만든 경로만 사용자 설정이 무시된다.
//  실제로 스팟추가·상세·홈(routes)·홈(by-name) 네 곳이 그 상태였다.
//
//  값은 `RidingProfileStore` 하나에서 온다. 화면마다 GET을 때리지 않는다.
//

import Foundation
import Testing
@testable import Tourding_FE

/// `update(_:)` 호출을 관측하는 spy. 저장(PUT) 성공이 캐시에 반영되는지 본다.
@MainActor
final class SpyProfileStore: RidingProfileProviding {
    private(set) var updatedOptions: [RouteOptionModel] = []
    private(set) var clearCallCount = 0
    var stubbedOption: RouteOptionModel?

    init(stubbedOption: RouteOptionModel? = nil) {
        self.stubbedOption = stubbedOption
    }

    private(set) var sessionOverrides: [RouteOptionModel?] = []
    private(set) var sessionOverride: RouteOptionModel?

    func currentOption(userId: Int) async -> RouteOptionModel? { stubbedOption }
    func update(_ option: RouteOptionModel, userId: Int) { updatedOptions.append(option) }
    func setSessionOverride(_ option: RouteOptionModel?) {
        sessionOverrides.append(option)
        sessionOverride = option
    }
    func invalidate() {}
    func clear() { clearCallCount += 1 }
}

@MainActor
struct RouteOptionWiringTests {

    private let road = RouteOptionModel(
        cyclingProfile: "ROAD", fastRoute: true,
        avoidSteps: true, avoidFords: false, skillLevel: "INTERMEDIATE"
    )
    private let mtb = RouteOptionModel(
        cyclingProfile: "MTB", fastRoute: false,
        avoidSteps: false, avoidFords: true, skillLevel: "BEGINNER"
    )

    private var route: [LocationNameModel] {
        [
            TestRoute.location(sequenceNum: 0, name: "출발", type: "Start", lat: "37.0", lon: "127.0"),
            TestRoute.location(sequenceNum: 1, name: "경유", type: "WayPoint", lat: "37.1", lon: "127.1"),
            TestRoute.location(sequenceNum: 2, name: "도착", type: "Goal", lat: "37.2", lon: "127.2")
        ]
    }

    private var newSpot: Tourding_FE.SpotData {
        Tourding_FE.SpotData(
            title: "신규스팟", addr1: "경북 포항시",
            typeCode: "A05", contentid: "999", contenttypeid: "39",
            firstimage: "", firstimage2: "",
            mapx: "127.9", mapy: "37.9"
        )
    }

    /// 서버에서 한 번 읽어 캐시된 상태의 저장소
    private func loadedStore(_ option: RouteOptionModel) -> RidingProfileStore {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = option
        return RidingProfileStore(userRepository: userRepository)
    }

    // MARK: - 스팟 추가 (POST /routes)

    @Test func spotAddCarriesRouteOption() async {
        let repository = FakeRouteRepository()
        let viewModel = SpotAddViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49),
            profileStore: loadedStore(road),
            editSession: RouteEditSession()
        )

        await viewModel.postRouteAPI(originalData: route, updatedData: newSpot)

        #expect(repository.capturedPostRoutes.last?.routeOption == road)
    }

    // MARK: - 상세에서 추가 (POST /routes)

    @Test func detailAddCarriesRouteOption() async {
        let repository = FakeRouteRepository()
        let viewModel = DetailSpotViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49),
            profileStore: loadedStore(road),
            editSession: RouteEditSession()
        )

        await viewModel.postRouteAPI(originalData: route, updatedData: newSpot)

        #expect(repository.capturedPostRoutes.last?.routeOption == road)
    }

    // MARK: - 홈 (POST /routes)

    @Test func homeRouteCarriesRouteOption() async {
        let repository = FakeRouteRepository()
        let viewModel = HomeViewModel(
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49),
            profileStore: loadedStore(road)
        )

        await viewModel.postRouteAPI(
            start: LocationData(name: "출발", latitude: 37.0, longitude: 127.0),
            end: LocationData(name: "도착", latitude: 37.2, longitude: 127.2)
        )

        #expect(repository.capturedPostRoutes.last?.routeOption == road)
    }

    // MARK: - 홈, 추천 코스 (POST /routes/by-name)

    /// 추천 코스를 고르면 이 요청으로 경로가 만들어진다. 여기가 빠지면
    /// 추천 코스만 디폴트 스타일로 계산된다.
    @Test func homeByNameCarriesRouteOption() async {
        let repository = FakeRouteRepository()
        repository.routes = RoutesModel(isUsed: false, duration: 0, distance: 0, routeSummaryId: 1)
        let viewModel = HomeViewModel(
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49),
            profileStore: loadedStore(road)
        )

        _ = await viewModel.postRouteByNameAPI(start: "신매대교", goal: "춘천애니메이션센터")

        #expect(repository.capturedByNameRequests.last?.routeOption == road)
    }

    // MARK: - 저장이 캐시에 반영되는가

    /// 설정 화면에서 저장하면 다음 경로 요청이 곧바로 새 스타일을 쓴다.
    /// 서버에 다시 묻지 않고 저장한 값을 그대로 캐시에 넣는다.
    @Test func savingStyleUpdatesSharedProfile() async {
        let store = SpyProfileStore()
        let viewModel = RidingStyleSettingsViewModel(
            userRepository: FakeUserRepository(),
            userSession: FakeUserSession(userId: 777_501),
            profileStore: store
        )
        viewModel.selectedBikeType = .road
        viewModel.selectedSkillLevel = .skilled

        let saved = await viewModel.saveRidingProfile()

        #expect(saved == true)
        #expect(store.updatedOptions.count == 1)
        #expect(store.updatedOptions.first?.cyclingProfile == BikeType.road.apiValue)
    }

    /// **저장에 실패했으면 캐시를 건드리지 않는다.**
    /// 서버는 옛 값인데 앱만 새 값을 실어 보내면 둘이 어긋난다.
    @Test func failedSaveDoesNotUpdateSharedProfile() async {
        let userRepository = FakeUserRepository()
        userRepository.updateRidingProfileError = FakeUserRepository.FakeError.notConfigured
        let store = SpyProfileStore()
        let viewModel = RidingStyleSettingsViewModel(
            userRepository: userRepository,
            userSession: FakeUserSession(userId: 777_502),
            profileStore: store
        )
        viewModel.selectedBikeType = .road
        viewModel.selectedSkillLevel = .skilled

        let saved = await viewModel.saveRidingProfile()

        #expect(saved == false)
        #expect(store.updatedOptions.isEmpty)
    }

    /// 온보딩에서 처음 고른 스타일도 첫 경로부터 적용돼야 한다
    @Test func onboardingSubmitUpdatesSharedProfile() async {
        let store = SpyProfileStore()
        let viewModel = OnboardingSurveyViewModel(
            userRepository: FakeUserRepository(),
            userSession: FakeUserSession(userId: 777_503),
            profileStore: store
        )
        viewModel.selectedBikeType = .mountain
        viewModel.selectedSkillLevel = .beginner

        let submitted = await viewModel.submitRidingProfile()

        #expect(submitted == true)
        #expect(store.updatedOptions.first?.cyclingProfile == BikeType.mountain.apiValue)
    }

    // MARK: - 통합 시나리오

    /// **이 기능의 목적 그 자체** —
    /// 코스 편집에서 라이딩 스타일을 바꾸고 돌아오면, 그 스타일로 라이딩이 시작돼야 한다.
    @Test func changedStyleReachesNextRidingStart() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = road
        let store = RidingProfileStore(userRepository: userRepository)
        let repository = FakeRouteRepository()
        let riding = makeTestRidingViewModel(
            repository: repository, profileStore: store, userId: 49
        )

        // 코스 편집 진입 — 저장된 스타일(road)을 읽는다
        await riding.loadRidingProfile()
        #expect(riding.routeOption == road)

        // 라이딩 스타일 화면에서 MTB로 저장
        store.update(mtb, userId: 49)

        // 편집 화면으로 복귀 후 라이딩 시작
        await riding.loadRidingProfile()
        _ = await riding.postRidingStartAPI(locationData: route)

        #expect(repository.capturedPostRoutes.last?.routeOption == mtb)
        #expect(userRepository.getRidingProfileCallCount == 1, "저장한 값을 알고 있으므로 다시 읽지 않는다")
    }

    /// 화면 넷이 같은 저장소를 보므로 GET은 한 번이다
    @Test func everyScreenSharesASingleProfileRequest() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = road
        let store = RidingProfileStore(userRepository: userRepository)
        let repository = FakeRouteRepository()

        let spotAdd = SpotAddViewModel(
            tourRepository: FakeTourRepository(), routeRepository: repository,
            userSession: FakeUserSession(userId: 49), profileStore: store,
            editSession: RouteEditSession()
        )
        let detail = DetailSpotViewModel(
            tourRepository: FakeTourRepository(), routeRepository: repository,
            userSession: FakeUserSession(userId: 49), profileStore: store,
            editSession: RouteEditSession()
        )
        let home = HomeViewModel(
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49), profileStore: store
        )

        await spotAdd.postRouteAPI(originalData: route, updatedData: newSpot)
        await detail.postRouteAPI(originalData: route, updatedData: newSpot)
        await home.postRouteAPI(
            start: LocationData(name: "출발", latitude: 37.0, longitude: 127.0),
            end: LocationData(name: "도착", latitude: 37.2, longitude: 127.2)
        )

        #expect(userRepository.getRidingProfileCallCount == 1)
        #expect(repository.capturedPostRoutes.allSatisfy { $0.routeOption == road })
        #expect(repository.capturedPostRoutes.count == 3)
    }

    // MARK: - 세션 정리

    /// **로그아웃하면 스타일 캐시도 버린다.**
    ///
    /// 온보딩은 저장(PUT)만 하고 조회는 하지 않는다 — 그 값이 메모리에 남은 채
    /// 다른 계정이 로그인하면 남의 스타일로 경로가 계산될 수 있다.
    /// Keychain 세션을 지우는 곳과 같은 지점에서 비운다.
    @Test func logoutClearsRidingProfileCache() {
        let store = SpyProfileStore()
        let viewModel = LoginViewModel(userRepository: FakeUserRepository(), profileStore: store)

        viewModel.logout()

        #expect(store.clearCallCount == 1)
    }

    // MARK: - 감사에서 확정된 결함

    /// **설정 화면이 서버에서 읽은 값을 공용 저장소에도 반영해야 한다.**
    ///
    /// 이 화면은 스토어를 우회해 직접 GET한다(편집기라 서버 진실을 봐야 한다).
    /// 그런데 받은 값을 스토어에 되먹이지 않으면, 화면에 보이는 스타일과
    /// 실제 경로 요청에 실리는 스타일이 갈린 채 세션 내내 유지된다.
    /// (`invalidate()` 는 프로덕션 호출부가 없어 캐시가 스스로 낡지 않는다.)
    @Test func loadingStyleScreenSyncsSharedProfile() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = mtb
        let store = SpyProfileStore()
        let viewModel = RidingStyleSettingsViewModel(
            userRepository: userRepository,
            userSession: FakeUserSession(userId: 777_504),
            profileStore: store
        )

        await viewModel.loadRidingProfile()

        #expect(store.updatedOptions.last == mtb,
                "화면이 읽은 서버 값이 경로 요청에도 쓰여야 한다")
    }

    /// **진입 때 조회에 실패했어도 POST 시점에 다시 시도해야 한다.**
    ///
    /// 라이딩 화면의 세 POST 만 진입·복귀에서 갱신되는 스냅샷을 썼다.
    /// 나머지 네 곳(홈 2·스팟추가·상세)은 POST 직전에 저장소를 읽어
    /// 앞선 실패를 만회하는데, 라이딩만 세션 내내 nil 로 남아
    /// 같은 세션에서 화면마다 다른 스타일로 계산된 경로가 섞였다.
    @Test func ridingStartRetriesProfileAfterEarlierFailure() async {
        let userRepository = FakeUserRepository()
        userRepository.getRidingProfileError = FakeUserRepository.FakeError.notConfigured
        let store = RidingProfileStore(userRepository: userRepository)
        let repository = FakeRouteRepository()
        let riding = makeTestRidingViewModel(
            repository: repository, profileStore: store, userId: 49
        )

        // 진입 시 조회 실패 — 폴백할 값도 없다
        await riding.loadRidingProfile()

        // 네트워크 복구
        userRepository.getRidingProfileError = nil
        userRepository.ridingProfile = road

        _ = await riding.postRidingStartAPI(locationData: route)

        #expect(repository.capturedPostRoutes.last?.routeOption == road,
                "POST 시점에 다시 읽어야 한다")
    }
}
