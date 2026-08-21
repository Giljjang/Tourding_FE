//
//  RouteEditSessionTests.swift
//  Tourding_FETests
//
//  스팟 추가가 **엉뚱한 경로에 저장되던 문제.**
//
//  라이딩 편집 화면은 최근 사용 경로(`isUsed=true`)를 편집할 수도, draft를 편집할 수도 있다.
//  그런데 스팟 추가·상세는 별도 ViewModel이라 그 사실을 모르고 **항상 draft**를 읽고 썼다.
//
//  실측 로그:
//    GET  /routes?userId=49&isUsed=true            ← 편집 화면이 읽는 경로
//    GET  /routes/location-name?userId=49&isUsed=false  ← 스팟 추가가 읽는 경로
//    POST /routes  isUsed:false  경유지 5개          ← draft에 저장
//    GET  /routes?userId=49&isUsed=true → 경유지 2개  ← 추가가 사라짐
//
//  진입 경로가 여럿이라(`DestinationSearchView`를 거치기도 한다) ViewType으로 나르면
//  중간 화면까지 값을 이어야 한다. 대신 편집 세션을 한 곳에 기록해 공유한다 —
//  `RidingProfileStore`와 같은 방식이다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RouteEditSessionTests {

    private var route: [LocationNameModel] {
        [
            TestRoute.location(sequenceNum: 0, name: "출발", type: "Start", lat: "37.0", lon: "127.0"),
            TestRoute.location(sequenceNum: 1, name: "도착", type: "Goal", lat: "37.2", lon: "127.2")
        ]
    }

    private var newSpot: Tourding_FE.SpotData {
        Tourding_FE.SpotData(
            title: "신규", addr1: "", typeCode: "A05", contentid: "9", contenttypeid: "39",
            firstimage: "", firstimage2: "", mapx: "127.9", mapy: "37.9"
        )
    }

    // MARK: - 저장소

    /// 기본값은 draft다 — 홈에서 새 경로를 만드는 흐름이 그렇다
    @Test func defaultsToDraft() {
        #expect(RouteEditSession().isUsed == false)
    }

    @Test func remembersWhichRouteIsBeingEdited() {
        let session = RouteEditSession()

        session.beginEditing(isUsed: true)

        #expect(session.isUsed == true)
    }

    /// 최근 경로를 편집하다 draft로 돌아오면 그대로 따라간다
    @Test func followsTheLatestEntry() {
        let session = RouteEditSession()
        session.beginEditing(isUsed: true)

        session.beginEditing(isUsed: false)

        #expect(session.isUsed == false)
    }

    /// 로그아웃하면 draft로 되돌린다 — 다음 사용자가 남의 최근 경로를 건드리면 안 된다
    @Test func resetGoesBackToDraft() {
        let session = RouteEditSession()
        session.beginEditing(isUsed: true)

        session.reset()

        #expect(session.isUsed == false)
    }

    // MARK: - 라이딩 화면이 세션을 기록한다

    /// 최근 경로로 편집에 들어가면 그 사실이 기록돼야 스팟 추가가 같은 경로를 본다
    @Test func ridingEntryRecordsRecentUsedRoute() {
        let session = RouteEditSession()
        let viewModel = makeTestRidingViewModel(editSession: session)

        viewModel.handleInitialEntry(
            locationManager: LocationManager(),
            isNotNormal: nil,
            isStart: false,
            routeSource: .recentUsed,
            onStartRiding: {}
        )

        #expect(session.isUsed == true)
    }

    @Test func ridingEntryRecordsDraftRoute() {
        let session = RouteEditSession()
        let viewModel = makeTestRidingViewModel(editSession: session)

        viewModel.handleInitialEntry(
            locationManager: LocationManager(),
            isNotNormal: nil,
            isStart: false,
            routeSource: .draft,
            onStartRiding: {}
        )

        #expect(session.isUsed == false)
    }

    // MARK: - 스팟 추가가 같은 경로를 읽고 쓴다

    /// **핵심** — 최근 경로를 편집 중이면 스팟도 거기에 추가된다
    @Test func spotAddWritesToTheRouteBeingEdited() async {
        let session = RouteEditSession()
        session.beginEditing(isUsed: true)
        let repository = FakeRouteRepository()
        let viewModel = SpotAddViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: session
        )

        await viewModel.postRouteAPI(originalData: route, updatedData: newSpot)

        #expect(repository.capturedPostRoutes.last?.isUsed == true)
    }

    /// 읽기도 같은 경로여야 한다 — draft를 읽어 최근 경로에 쓰면 내용이 뒤섞인다
    @Test func spotAddReadsTheRouteBeingEdited() async {
        let session = RouteEditSession()
        session.beginEditing(isUsed: true)
        let repository = FakeRouteRepository()
        repository.locationNames = route
        let viewModel = SpotAddViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: session
        )

        await viewModel.getRouteLocationAPI()

        #expect(repository.capturedLocationNameRequests.last?.isUsed == true)
    }

    /// draft를 편집 중이면 예전과 똑같이 동작한다 (회귀 가드)
    @Test func spotAddStillUsesDraftWhenEditingDraft() async {
        let session = RouteEditSession()
        let repository = FakeRouteRepository()
        let viewModel = SpotAddViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: session
        )

        await viewModel.postRouteAPI(originalData: route, updatedData: newSpot)

        #expect(repository.capturedPostRoutes.last?.isUsed == false)
    }

    // MARK: - 상세 화면도 마찬가지

    @Test func detailAddWritesToTheRouteBeingEdited() async {
        let session = RouteEditSession()
        session.beginEditing(isUsed: true)
        let repository = FakeRouteRepository()
        let viewModel = DetailSpotViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 49),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: session
        )

        await viewModel.postRouteAPI(originalData: route, updatedData: newSpot)

        #expect(repository.capturedPostRoutes.last?.isUsed == true)
    }

    // MARK: - 편집 중인 경로에 적용된 스타일

    /// **최근 경로를 이어서 갈 때는 그 경로에 실제로 적용된 스타일을 보여줘야 한다.**
    ///
    /// 최근 경로는 이미 어떤 스타일로 계산돼 저장돼 있다(`appliedOption`).
    /// 유저 프로필을 보여주면 화면과 실제 경로가 어긋난다 —
    /// 실측 로그에서 경로는 `cycling-electric`인데 화면은 프로필의 `cycling-regular`였다.
    @Test func recordsAppliedOptionOfTheRouteBeingEdited() {
        let session = RouteEditSession()
        let applied = RouteOptionModel(
            cyclingProfile: "cycling-electric", fastRoute: true,
            avoidSteps: true, avoidFords: true, skillLevel: "BEGINNER"
        )

        session.recordAppliedOption(applied)

        #expect(session.appliedOption == applied)
    }

    /// 서버가 안 내려주면 알 수 없다 — 그때는 유저 프로필로 폴백한다
    @Test func appliedOptionStartsEmpty() {
        #expect(RouteEditSession().appliedOption == nil)
    }

    @Test func resetClearsAppliedOption() {
        let session = RouteEditSession()
        session.recordAppliedOption(
            RouteOptionModel(cyclingProfile: "P", fastRoute: true,
                             avoidSteps: true, avoidFords: true, skillLevel: "S")
        )

        session.reset()

        #expect(session.appliedOption == nil)
    }

    /// 경로를 읽을 때마다 기록된다 — 편집 화면이 번들을 반영하는 지점이 유일한 출처다
    @Test func applyingRouteBundleRecordsAppliedOption() {
        let session = RouteEditSession()
        let viewModel = makeTestRidingViewModel(editSession: session)
        let applied = RouteOptionModel(
            cyclingProfile: "cycling-electric", fastRoute: true,
            avoidSteps: true, avoidFords: true, skillLevel: "BEGINNER"
        )
        var bundle = RouteGuideResponse(
            routeSummaryId: 60, isUsed: true, duration: 100, distance: 200,
            guides: [], paths: [], locations: []
        )
        bundle.appliedOption = applied

        viewModel.applyRouteBundle(bundle)

        #expect(session.appliedOption == applied)
    }

    // MARK: - 스타일 화면이 그 값을 보여준다

    /// **핵심** — 편집 중인 경로의 스타일을 보여준다. 유저 프로필이 아니다.
    @Test func styleScreenShowsRouteAppliedOptionNotProfile() async {
        let session = RouteEditSession()
        session.recordAppliedOption(
            RouteOptionModel(cyclingProfile: "cycling-electric", fastRoute: true,
                             avoidSteps: true, avoidFords: true, skillLevel: "BEGINNER")
        )
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = RouteOptionModel(
            cyclingProfile: "cycling-regular", fastRoute: false,
            avoidSteps: false, avoidFords: false, skillLevel: "PRO"
        )
        let viewModel = RidingStyleSettingsViewModel(
            userRepository: userRepository,
            userSession: FakeUserSession(userId: 49),
            profileStore: SpyProfileStore(),
            editSession: session,
            isTemporary: true
        )

        await viewModel.loadRidingProfile()

        #expect(viewModel.selectedBikeType == .electric, "경로에 적용된 값")
        #expect(viewModel.selectedSkillLevel == .beginner)
        #expect(userRepository.getRidingProfileCallCount == 0, "경로 값을 알면 프로필을 묻지 않는다")
    }

    /// 경로에 적용된 값이 없으면(서버가 안 내려줌) 유저 프로필로 폴백한다
    @Test func styleScreenFallsBackToProfileWhenRouteHasNoOption() async {
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = RouteOptionModel(
            cyclingProfile: "cycling-regular", fastRoute: false,
            avoidSteps: false, avoidFords: false, skillLevel: "PRO"
        )
        let viewModel = RidingStyleSettingsViewModel(
            userRepository: userRepository,
            userSession: FakeUserSession(userId: 49),
            profileStore: SpyProfileStore(),
            editSession: RouteEditSession(),
            isTemporary: true
        )

        await viewModel.loadRidingProfile()

        #expect(viewModel.selectedBikeType == .normal)
        #expect(userRepository.getRidingProfileCallCount == 1)
    }

    /// 마이페이지에서 연 화면은 언제나 유저 프로필이다 — 경로와 무관하다
    @Test func myPageStyleScreenAlwaysShowsProfile() async {
        let session = RouteEditSession()
        session.recordAppliedOption(
            RouteOptionModel(cyclingProfile: "cycling-electric", fastRoute: true,
                             avoidSteps: true, avoidFords: true, skillLevel: "BEGINNER")
        )
        let userRepository = FakeUserRepository()
        userRepository.ridingProfile = RouteOptionModel(
            cyclingProfile: "cycling-regular", fastRoute: false,
            avoidSteps: false, avoidFords: false, skillLevel: "PRO"
        )
        let viewModel = RidingStyleSettingsViewModel(
            userRepository: userRepository,
            userSession: FakeUserSession(userId: 49),
            profileStore: SpyProfileStore(),
            editSession: session
        )

        await viewModel.loadRidingProfile()

        #expect(viewModel.selectedBikeType == .normal, "프로필 값")
        #expect(userRepository.getRidingProfileCallCount == 1)
    }
}
