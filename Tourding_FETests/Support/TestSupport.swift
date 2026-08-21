//
//  TestSupport.swift
//  Tourding_FETests
//
//  테스트 전용 fake / spy / 픽스처 빌더. 프로덕션 타겟에 넣지 말 것.
//

import Foundation
@testable import Tourding_FE

// MARK: - Fake Repositories

/// 라이딩 스타일(riding-profile) 조회/저장을 관측하는 fake.
final class FakeUserRepository: UserRepositoryProtocol {

    enum FakeError: Error { case notConfigured }

    /// `getRidingProfile` 호출 횟수 — 진입·복귀에서 몇 번 다시 읽는지 관측한다
    private(set) var getRidingProfileCallCount = 0
    private(set) var capturedProfileUserIds: [Int] = []

    /// nil이 아니면 `getRidingProfile`이 이 에러를 던진다
    var getRidingProfileError: Error?

    /// `getRidingProfile`이 돌려줄 옵션
    var ridingProfile = RouteOptionModel(
        cyclingProfile: "ROAD", fastRoute: true,
        avoidSteps: true, avoidFords: false, skillLevel: "INTERMEDIATE"
    )

    /// 응답이 도착하기 전에 다른 호출자를 끼워 넣는 훅.
    /// 동시 호출이 하나의 요청으로 합쳐지는지 결정적으로 재현한다.
    var beforeGetRidingProfile: (() async -> Void)?

    func getRidingProfile(userId: Int) async throws -> UserRidingProfileResponse {
        getRidingProfileCallCount += 1
        capturedProfileUserIds.append(userId)
        await beforeGetRidingProfile?()
        if let getRidingProfileError { throw getRidingProfileError }
        return UserRidingProfileResponse(userId: userId, routeOption: ridingProfile)
    }

    /// nil이 아니면 `updateRidingProfile`이 이 에러를 던진다
    var updateRidingProfileError: Error?

    /// PUT 호출 횟수 — 일시 옵션은 서버에 저장하지 않아야 한다
    private(set) var updateRidingProfileCallCount = 0

    func updateRidingProfile(userId: Int, request: UpdateRidingProfileRequest) async throws -> UserRidingProfileResponse {
        updateRidingProfileCallCount += 1
        if let updateRidingProfileError { throw updateRidingProfileError }
        ridingProfile = request.routeOption
        return UserRidingProfileResponse(userId: userId, routeOption: request.routeOption)
    }

    func createUser(_ request: CreateUserRequest) async throws -> CreateUserResponse {
        throw FakeError.notConfigured
    }
    func deleteUser(id: Int) async throws {}
    func revokeUser(userId: Int, authorizationCode: String) async throws {}
}


/// 요청을 캡처하는 spy 겸 fake.
/// `MockRouteRepository`는 `postRoutes`의 requestBody를 버리므로 요청 검증에는 쓸 수 없다.
final class FakeRouteRepository: RouteRepositoryProtocol {

    enum FakeError: Error {
        case postFailed
        case notConfigured
    }

    /// 메서드 호출 순서를 그대로 기록한다. 여러 API에 걸친 순서 계약 검증용.
    private(set) var callLog: [String] = []

    /// nil이 아니면 `postRoutes`가 이 에러를 던진다.
    var postRoutesError: Error?

    /// `postRoutes`가 받은 요청 본문 (호출 순서대로)
    private(set) var capturedPostRoutes: [RequestRouteModel] = []

    /// `postRoutes` 호출 시점의 `Task.isCancelled` 값.
    /// URLSession의 async API는 취소된 Task에서 즉시 실패하므로, 실제 네트워크 없이도
    /// "취소된 Task 안에서 POST가 실행됐는지"를 이 값으로 관측한다.
    private(set) var postRoutesCancellationStates: [Bool] = []

    var locationNames: [LocationNameModel] = []
    var paths: [RoutePathModel] = []
    var guides: [GuideModel] = []
    var routes: RoutesModel?

    /// `postRoutes`가 돌려줄 응답. 기본은 빈 번들이라 관심 없는 테스트는 설정하지 않아도 된다.
    var postRoutesResponse = RouteGuideResponse(
        routeSummaryId: 0, isUsed: false, duration: 0, distance: 0,
        guides: [], paths: [], locations: []
    )

    /// `postRoutes`가 실행되는 순간 호출된다.
    /// 응답이 도착하는 타이밍에 취소를 끼워 넣어 "뒤늦게 끝난 시작"을 결정적으로 재현하는 훅.
    var onPostRoutes: (() -> Void)?

    @discardableResult
    func postRoutes(requestBody: RequestRouteModel) async throws -> RouteGuideResponse {
        callLog.append("postRoutes")
        onPostRoutes?()
        postRoutesCancellationStates.append(Task.isCancelled)
        capturedPostRoutes.append(requestBody)
        if let postRoutesError {
            throw postRoutesError
        }
        return postRoutesResponse
    }

    /// `getRoutesPath`가 받은 (userId, isUsed) — 경로선 재조회가 어떤 경로를 가리키는지 검증용
    private(set) var capturedPathRequests: [(userId: Int, isUsed: Bool)] = []

    /// nil이 아니면 GET 계열이 이 에러를 던진다 (재시도 정책 검증용)
    var getRoutesError: Error?

    func getRoutesPath(userId: Int, isUsed: Bool) async throws -> [RoutePathModel] {
        callLog.append("getRoutesPath(isUsed: \(isUsed))")
        capturedPathRequests.append((userId: userId, isUsed: isUsed))
        if let getRoutesError { throw getRoutesError }
        return paths
    }

    /// 재조회가 어느 경로(draft / 사용 완료)를 읽었는지 검증용
    private(set) var capturedLocationNameRequests: [(userId: Int, isUsed: Bool)] = []
    private(set) var capturedRoutesRequests: [(userId: Int, isUsed: Bool)] = []

    func getRoutesLocationName(userId: Int, isUsed: Bool) async throws -> [LocationNameModel] {
        callLog.append("getRoutesLocationName(isUsed: \(isUsed))")
        capturedLocationNameRequests.append((userId: userId, isUsed: isUsed))
        if let getRoutesError { throw getRoutesError }
        return locationNames
    }

    var bundle: RouteGuideResponse?
    private(set) var capturedBundleRequests: [(userId: Int, isUsed: Bool)] = []

    /// nil이 아니면 `getRouteBundle`이 이 에러를 던진다
    var bundleError: Error?

    func getRouteBundle(userId: Int, isUsed: Bool) async throws -> RouteGuideResponse {
        capturedBundleRequests.append((userId: userId, isUsed: isUsed))
        if let bundleError { throw bundleError }
        guard let bundle else { throw FakeError.notConfigured }
        return bundle
    }

    /// `getRoutesGuide`가 실행되는 순간 호출된다.
    /// 응답이 도착하는 타이밍에 취소를 끼워 넣어 "뒤늦게 끝난 가이드"를 결정적으로 재현하는 훅.
    var onGetRoutesGuide: (() -> Void)?

    func getRoutesGuide(userId: Int, isUsed: Bool) async throws -> [GuideModel] {
        callLog.append("getRoutesGuide(isUsed: \(isUsed))")
        onGetRoutesGuide?()
        if let getRoutesError { throw getRoutesError }
        return guides
    }

    func getRoutes(userId: Int, isUsed: Bool) async throws -> RoutesModel {
        capturedRoutesRequests.append((userId: userId, isUsed: isUsed))
        guard let routes else { throw FakeError.notConfigured }
        return routes
    }

    func getRoutesRidingRecommend(pageNum: Int) async throws -> [RouteRidingRecommendModel] { [] }

    private(set) var capturedByNameRequests: [ReqRoutesByNameModel] = []

    /// nil이 아니면 `postRoutesByName`이 이 에러를 던진다 (서버 500 재현용)
    var byNameError: Error?

    func postRoutesByName(requestBody: ReqRoutesByNameModel) async throws -> RoutesModel {
        capturedByNameRequests.append(requestBody)
        if let byNameError { throw byNameError }
        guard let routes else { throw FakeError.notConfigured }
        return routes
    }
}

/// 주의: `Model/Search/SpotSearchModels.swift`는 `membershipExceptions`로 테스트 타겟에도 컴파일된다.
/// 따라서 `SpotData`를 한정 없이 쓰면 테스트 모듈 타입으로 해석되어 프로토콜 준수가 깨진다.
/// 반드시 `Tourding_FE.SpotData`로 한정할 것.
final class FakeTourRepository: TourRepositoryProtocol {
    enum FakeError: Error { case notConfigured }

    var spots: [Tourding_FE.SpotData] = []
    var detail: ContentDetailModel?

    func searchLocationSpots(pageNum: Int, mapX: String, mapY: String, radius: String, typeCode: String) async throws -> [Tourding_FE.SpotData] { spots }

    func searchByKeyword(keyword: String, pageNum: Int, typeCode: String, areaCode: Int) async throws -> [Tourding_FE.SpotData] { spots }

    func getTourAreaDetail(requestBody: ReqDetailModel) async throws -> ContentDetailModel {
        guard let detail else { throw FakeError.notConfigured }
        return detail
    }
}

final class FakeKakaoRepository: KakaoRepositoryProtocol {
    var toilets: [FacilityInfoModel] = []
    var stores: [FacilityInfoModel] = []

    func postRouteToilet(requestBody: ReqFacilityInfoModel) async throws -> [FacilityInfoModel] { toilets }

    func postRouteConvenienceStore(requestBody: ReqFacilityInfoModel) async throws -> [FacilityInfoModel] { stores }
}

// MARK: - Fake Session

struct FakeUserSession: UserSessionProviding {
    let userId: Int?
}

// MARK: - Fixture Builders

enum TestRoute {

    static func location(
        sequenceNum: Int,
        name: String,
        type: String,
        lat: String,
        lon: String,
        typeCode: String = "A01",
        contentId: String? = nil,
        contentTypeId: String = "12"
    ) -> LocationNameModel {
        LocationNameModel(
            sequenceNum: sequenceNum,
            name: name,
            type: type,
            typeCode: typeCode,
            contentId: contentId ?? "c\(sequenceNum)",
            contentTypeId: contentTypeId,
            lon: lon,
            lat: lat
        )
    }

    /// 추천 코스를 선택해 만들어진 경로의 실제 형태.
    /// 서버가 경유지 메타데이터를 비워서 돌려주기 때문에 `contentTypeId`가 전부 같은 값(빈 문자열)이다.
    /// 실제 로그: typeCode "경유지,경유지,경유지", contentTypeId ""
    static var recommendedCourseWithThreeWaypoints: [LocationNameModel] {
        [
            location(sequenceNum: 0, name: "아라한강갑문", type: "Start", lat: "37.60000734237715", lon: "126.79970313779297",
                     typeCode: "", contentId: "", contentTypeId: ""),
            location(sequenceNum: 1, name: "경안천 습지생태공원", type: "WayPoint", lat: "37.4573533357", lon: "127.3032168104",
                     typeCode: "경유지", contentId: "630741", contentTypeId: ""),
            location(sequenceNum: 2, name: "양섬", type: "WayPoint", lat: "37.3054405896", lon: "127.6200230151",
                     typeCode: "경유지", contentId: "2766859", contentTypeId: ""),
            location(sequenceNum: 3, name: "수룡폭포", type: "WayPoint", lat: "37.0634495189", lon: "127.7958196484",
                     typeCode: "경유지", contentId: "1687491", contentTypeId: ""),
            location(sequenceNum: 4, name: "충주댐", type: "Goal", lat: "37.01274225635733", lon: "127.91673091230659",
                     typeCode: "", contentId: "", contentTypeId: "")
        ]
    }

    /// Start → Goal
    static var startGoal: [LocationNameModel] {
        [
            location(sequenceNum: 0, name: "출발지", type: "Start", lat: "36.0190", lon: "129.3435"),
            location(sequenceNum: 1, name: "도착지", type: "Goal", lat: "36.0600", lon: "129.3800")
        ]
    }

    /// Start → WayPoint1 → WayPoint2 → Goal
    static var startTwoWaypointsGoal: [LocationNameModel] {
        [
            location(sequenceNum: 0, name: "출발지", type: "Start", lat: "36.0190", lon: "129.3435"),
            location(sequenceNum: 1, name: "경유지1", type: "WayPoint", lat: "36.0300", lon: "129.3500"),
            location(sequenceNum: 2, name: "경유지2", type: "WayPoint", lat: "36.0400", lon: "129.3600"),
            location(sequenceNum: 3, name: "도착지", type: "Goal", lat: "36.0600", lon: "129.3800")
        ]
    }
}

enum TestSpot {
    static var sample: Tourding_FE.SpotData {
        Tourding_FE.SpotData(
            title: "추가 스팟",
            addr1: "경북 포항시",
            typeCode: "A01",
            contentid: "999",
            contenttypeid: "12",
            firstimage: "",
            firstimage2: "",
            mapx: "129.3700",
            mapy: "36.0500"
        )
    }
}

// MARK: - ViewModel Builder

@MainActor
func makeTestRidingViewModel(
    repository: FakeRouteRepository = FakeRouteRepository(),
    kakaoRepository: FakeKakaoRepository = FakeKakaoRepository(),
    profileStore: RidingProfileProviding? = nil,
    editSession: RouteEditSessionProviding? = nil,
    userId: Int = 3
) -> RidingViewModel {
    // 기본 인자에서 만들면 nonisolated 컨텍스트라 @MainActor 타입을 생성할 수 없다
    let store = profileStore ?? RidingProfileStore(userRepository: FakeUserRepository())
    let viewModel = RidingViewModel(
        routeRepository: repository,
        kakaoRepository: kakaoRepository,
        profileStore: store,
        editSession: editSession ?? RouteEditSession(),
        userSession: FakeUserSession(userId: userId)
    )
    return viewModel
}

// MARK: - 동시성 게이트

/// 여러 Task를 한 지점에 세워 두었다가 함께 풀어 주는 테스트용 게이트.
/// `Task.sleep`으로 타이밍을 맞추면 느리고 불안정하다 — 여기서는 결정적이다.
@MainActor
final class TestGate {
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume() }
    }
}
