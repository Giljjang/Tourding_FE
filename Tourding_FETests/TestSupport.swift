//
//  TestSupport.swift
//  Tourding_FETests
//
//  테스트 전용 fake / spy / 픽스처 빌더. 프로덕션 타겟에 넣지 말 것.
//

import Foundation
@testable import Tourding_FE

// MARK: - Fake Repositories

/// 요청을 캡처하는 spy 겸 fake.
/// `MockRouteRepository`는 `postRoutes`의 requestBody를 버리므로 요청 검증에는 쓸 수 없다.
final class FakeRouteRepository: RouteRepositoryProtocol {

    enum FakeError: Error {
        case postFailed
        case notConfigured
    }

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

    func postRoutes(requestBody: RequestRouteModel) async throws {
        postRoutesCancellationStates.append(Task.isCancelled)
        capturedPostRoutes.append(requestBody)
        if let postRoutesError {
            throw postRoutesError
        }
    }

    /// `getRoutesPath`가 받은 (userId, isUsed) — 경로선 재조회가 어떤 경로를 가리키는지 검증용
    private(set) var capturedPathRequests: [(userId: Int, isUsed: Bool)] = []

    func getRoutesPath(userId: Int, isUsed: Bool) async throws -> [RoutePathModel] {
        capturedPathRequests.append((userId: userId, isUsed: isUsed))
        return paths
    }

    func getRoutesLocationName(userId: Int, isUsed: Bool) async throws -> [LocationNameModel] { locationNames }

    func getRoutesGuide(userId: Int, isUsed: Bool) async throws -> [GuideModel] { guides }

    func getRoutes(userId: Int, isUsed: Bool) async throws -> RoutesModel {
        guard let routes else { throw FakeError.notConfigured }
        return routes
    }

    func getRoutesRidingRecommend(pageNum: Int) async throws -> [RouteRidingRecommendModel] { [] }

    func postRoutesByName(requestBody: ReqRoutesByNameModel) async throws -> RoutesModel {
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
    userId: Int = 3
) -> RidingViewModel {
    let viewModel = RidingViewModel(
        routeRepository: repository,
        kakaoRepository: kakaoRepository
    )
    // init이 KeychainHelper.loadUid()를 직접 호출하므로 테스트에서 덮어쓴다.
    // 이건 우회지 이음새가 아니다 — 선행 리팩토링(UserSessionProviding) 대상.
    viewModel.userId = userId
    return viewModel
}
