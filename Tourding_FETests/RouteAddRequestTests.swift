//
//  RouteAddRequestTests.swift
//  Tourding_FETests
//
//  경로에 스팟을 추가할 때 만드는 POST /routes 본문 검증.
//
//  SpotAddView와 DetailSpotView가 같은 일을 하는 복붙 코드라 결과가 달랐다.
//  - typeCode만 `insert(at: count-1)`이라 경유지와 카테고리가 어긋남 (두 파일 모두)
//  - Detail은 contentTypeId 자리에 contentId를 넣음
//

import Testing
@testable import Tourding_FE

@MainActor
struct RouteAddRequestTests {

    private func fields(_ raw: String, separator: String = ",") -> [String] {
        raw.isEmpty ? [] : raw.components(separatedBy: separator)
    }

    /// [출발, 경유A, 경유B, 도착] — 각 항목의 typeCode/contentId/contentTypeId를 서로 다르게 두어
    /// 자리가 어긋나면 즉시 드러나게 한다
    private var routeWithTwoWaypoints: [LocationNameModel] {
        [
            TestRoute.location(sequenceNum: 0, name: "출발", type: "Start", lat: "37.0", lon: "127.0",
                               typeCode: "A01", contentId: "100", contentTypeId: "12"),
            TestRoute.location(sequenceNum: 1, name: "경유A", type: "WayPoint", lat: "37.1", lon: "127.1",
                               typeCode: "A02", contentId: "200", contentTypeId: "14"),
            TestRoute.location(sequenceNum: 2, name: "경유B", type: "WayPoint", lat: "37.2", lon: "127.2",
                               typeCode: "A03", contentId: "300", contentTypeId: "28"),
            TestRoute.location(sequenceNum: 3, name: "도착", type: "Goal", lat: "37.3", lon: "127.3",
                               typeCode: "A04", contentId: "400", contentTypeId: "32")
        ]
    }

    private var routeWithOneWaypoint: [LocationNameModel] {
        [
            TestRoute.location(sequenceNum: 0, name: "출발", type: "Start", lat: "37.0", lon: "127.0",
                               typeCode: "A01", contentId: "100", contentTypeId: "12"),
            TestRoute.location(sequenceNum: 1, name: "경유A", type: "WayPoint", lat: "37.1", lon: "127.1",
                               typeCode: "A02", contentId: "200", contentTypeId: "14"),
            TestRoute.location(sequenceNum: 2, name: "도착", type: "Goal", lat: "37.2", lon: "127.2",
                               typeCode: "A04", contentId: "400", contentTypeId: "32")
        ]
    }

    private var newSpot: Tourding_FE.SpotData {
        Tourding_FE.SpotData(
            title: "신규스팟",
            addr1: "경북 포항시",
            typeCode: "A05",
            contentid: "999",
            contenttypeid: "39",
            firstimage: "",
            firstimage2: "",
            mapx: "127.9",
            mapy: "37.9"
        )
    }

    private func makeSpotAddViewModel(_ repository: FakeRouteRepository) -> SpotAddViewModel {
        SpotAddViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 14),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: RouteEditSession()
        )
    }

    private func makeDetailViewModel(_ repository: FakeRouteRepository) -> DetailSpotViewModel {
        DetailSpotViewModel(
            tourRepository: FakeTourRepository(),
            routeRepository: repository,
            userSession: FakeUserSession(userId: 14),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository()),
            editSession: RouteEditSession()
        )
    }

    // MARK: - 오류 1 — 새 스팟의 typeCode가 끝에 붙어야 한다

    @Test func spotAddAppendsNewTypeCodeAtEnd() async {
        let repository = FakeRouteRepository()

        await makeSpotAddViewModel(repository)
            .postRouteAPI(originalData: routeWithTwoWaypoints, updatedData: newSpot)

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다"); return
        }
        #expect(fields(body.typeCode) == ["A02", "A03", "A05"])
    }

    @Test func detailAddAppendsNewTypeCodeAtEnd() async {
        let repository = FakeRouteRepository()

        await makeDetailViewModel(repository)
            .postRouteAPI(originalData: routeWithTwoWaypoints, updatedData: newSpot)

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다"); return
        }
        #expect(fields(body.typeCode) == ["A02", "A03", "A05"])
    }

    /// 경유지가 1개면 삽입 위치가 0이 되어 기존 경유지와 완전히 뒤바뀐다
    @Test func spotAddKeepsAlignmentWithSingleExistingWaypoint() async {
        let repository = FakeRouteRepository()

        await makeSpotAddViewModel(repository)
            .postRouteAPI(originalData: routeWithOneWaypoint, updatedData: newSpot)

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다"); return
        }
        #expect(fields(body.wayPoints, separator: "|") == ["127.1,37.1", "127.9,37.9"])
        #expect(fields(body.typeCode) == ["A02", "A05"])
        #expect(fields(body.contentId) == ["200", "999"])
    }

    // MARK: - 오류 2 — contentTypeId에 관광타입이 들어가야 한다

    @Test func detailAddSendsContentTypeIdNotContentId() async {
        let repository = FakeRouteRepository()

        await makeDetailViewModel(repository)
            .postRouteAPI(originalData: routeWithTwoWaypoints, updatedData: newSpot)

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다"); return
        }
        #expect(fields(body.contentId) == ["200", "300", "999"])
        #expect(fields(body.contentTypeId) == ["14", "28", "39"])
    }

    /// 회귀 가드 — SpotAdd 경로는 원래 정상이었다
    @Test func spotAddSendsContentTypeIdNotContentId() async {
        let repository = FakeRouteRepository()

        await makeSpotAddViewModel(repository)
            .postRouteAPI(originalData: routeWithTwoWaypoints, updatedData: newSpot)

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다"); return
        }
        #expect(fields(body.contentId) == ["200", "300", "999"])
        #expect(fields(body.contentTypeId) == ["14", "28", "39"])
    }

    /// 두 화면이 같은 본문을 만들어야 한다 — 진입 경로에 따라 결과가 달라지면 안 된다.
    ///
    /// **필드를 나열하지 않고 본문 전체를 비교한다.** 예전엔 5개만 봐서
    /// `start`·`goal`·`userId`·`isUsed`가 어긋나도 통과했다.
    /// 전체 비교면 새 필드(`routeOption` 등)가 늘어도 자동으로 잠긴다 —
    /// 조립부가 두 곳에 복붙돼 있는 한 이 테스트가 유일한 동치 보장이다.
    @Test func bothEntryPointsProduceIdenticalRequestBody() async {
        let spotAddRepo = FakeRouteRepository()
        let detailRepo = FakeRouteRepository()

        await makeSpotAddViewModel(spotAddRepo)
            .postRouteAPI(originalData: routeWithTwoWaypoints, updatedData: newSpot)
        await makeDetailViewModel(detailRepo)
            .postRouteAPI(originalData: routeWithTwoWaypoints, updatedData: newSpot)

        guard let fromSpotAdd = spotAddRepo.capturedPostRoutes.last,
              let fromDetail = detailRepo.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다"); return
        }
        #expect(fromSpotAdd == fromDetail)
    }

    // MARK: - 오류 3 — 좌표 규약 고정

    /// `RequestRouteModel`의 좌표는 **경도,위도** 순이다.
    /// (`LocationManager.getCurrentLocationString()`의 위도,경도와 반대이므로 반드시 고정한다)
    @Test func sendsRouteCoordinatesAsLongitudeThenLatitude() async {
        let repository = FakeRouteRepository()

        await makeSpotAddViewModel(repository)
            .postRouteAPI(originalData: routeWithTwoWaypoints, updatedData: newSpot)

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다"); return
        }
        #expect(body.start == "127.0,37.0")
        #expect(body.goal == "127.3,37.3")
        #expect(fields(body.wayPoints, separator: "|") == ["127.1,37.1", "127.2,37.2", "127.9,37.9"])
    }

    // MARK: - 회귀 가드 — 새 스팟 이름은 도착지 앞에 들어간다

    @Test func insertsNewSpotNameBeforeGoal() async {
        let repository = FakeRouteRepository()

        await makeSpotAddViewModel(repository)
            .postRouteAPI(originalData: routeWithTwoWaypoints, updatedData: newSpot)

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다"); return
        }
        #expect(fields(body.locateName) == ["출발", "경유A", "경유B", "신규스팟", "도착"])
    }
}
