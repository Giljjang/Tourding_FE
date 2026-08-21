//
//  RouteRequestBuilderTests.swift
//  Tourding_FETests
//
//  D1 — POST /routes 본문 조립이 5곳에 복붙돼 있다.
//
//  SpotAdd·Detail·라이딩시작·경유지삭제·경유지DnD가 전부 같은 규칙을 각자 구현했다.
//  실제로 이 복붙에서 버그가 세 건 나왔다 —
//  typeCode만 `insert(at: count-1)`이라 카테고리가 어긋났고(두 파일 모두),
//  Detail은 contentTypeId 자리에 contentId를 넣었다.
//
//  규칙은 하나다:
//    start/goal = 첫·마지막 (경도,위도)
//    wayPoints·typeCode·contentId·contentTypeId = 중간만
//    locateName = 출발·도착 포함 전체
//
//  **스팟 추가도 같은 규칙이다** — "도착지 앞에 끼워 넣은 뒤 그대로 조립"과 결과가 같다.
//  그래서 빌더는 조립 하나 + 삽입 하나로 끝난다.
//

import Testing
@testable import Tourding_FE

struct RouteRequestBuilderTests {

    private func fields(_ raw: String, separator: String = ",") -> [String] {
        raw.isEmpty ? [] : raw.components(separatedBy: separator)
    }

    /// [출발, 경유A, 경유B, 도착] — 항목마다 값을 다르게 두어 자리가 어긋나면 드러나게 한다
    private var route: [LocationNameModel] {
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

    private var newSpot: Tourding_FE.SpotData {
        Tourding_FE.SpotData(
            title: "신규스팟", addr1: "경북 포항시",
            typeCode: "A05", contentid: "999", contenttypeid: "39",
            firstimage: "", firstimage2: "",
            mapx: "127.9", mapy: "37.9"
        )
    }

    // MARK: - 조립

    /// **좌표는 경도,위도 순이다.** `getCurrentLocationString()`의 위도,경도와 반대다
    @Test func usesFirstAndLastAsEndpointsInLongitudeLatitudeOrder() throws {
        let body = try #require(RouteRequestBuilder.make(from: route, userId: 14, isUsed: false))

        #expect(body.start == "127.0,37.0")
        #expect(body.goal == "127.3,37.3")
    }

    /// 경유지 목록 넷은 **중간만** 담고 개수가 서로 같아야 한다
    @Test func middleLocationsFillEveryWaypointList() throws {
        let body = try #require(RouteRequestBuilder.make(from: route, userId: 14, isUsed: false))

        #expect(fields(body.wayPoints, separator: "|") == ["127.1,37.1", "127.2,37.2"])
        #expect(fields(body.typeCode) == ["A02", "A03"])
        #expect(fields(body.contentId) == ["200", "300"])
        #expect(fields(body.contentTypeId) == ["14", "28"])
    }

    /// locateName만 출발·도착을 포함한다
    @Test func locateNameIncludesEndpoints() throws {
        let body = try #require(RouteRequestBuilder.make(from: route, userId: 14, isUsed: false))

        #expect(fields(body.locateName) == ["출발", "경유A", "경유B", "도착"])
    }

    /// 경유지가 없어도 조립된다 — 출발·도착만 있는 경로
    @Test func buildsRouteWithoutWaypoints() throws {
        let twoPoints = [route[0], route[3]]

        let body = try #require(RouteRequestBuilder.make(from: twoPoints, userId: 14, isUsed: false))

        #expect(body.wayPoints.isEmpty)
        #expect(body.typeCode.isEmpty)
        #expect(fields(body.locateName) == ["출발", "도착"])
    }

    /// 경로가 없으면 본문을 만들지 않는다 — 호출부가 POST를 걸러야 한다
    @Test func returnsNilForEmptyRoute() {
        #expect(RouteRequestBuilder.make(from: [], userId: 14, isUsed: false) == nil)
    }

    @Test func carriesUserIdAndIsUsed() throws {
        let body = try #require(RouteRequestBuilder.make(from: route, userId: 49, isUsed: true))

        #expect(body.userId == 49)
        #expect(body.isUsed == true)
    }

    /// 라이딩 스타일은 그대로 실린다. 주지 않으면 nil이라 키가 빠진다
    @Test func carriesRouteOption() throws {
        let option = RouteOptionModel(
            cyclingProfile: "ROAD", fastRoute: true,
            avoidSteps: true, avoidFords: false, skillLevel: "INTERMEDIATE"
        )

        let withOption = try #require(
            RouteRequestBuilder.make(from: route, userId: 14, isUsed: false, routeOption: option)
        )
        let without = try #require(RouteRequestBuilder.make(from: route, userId: 14, isUsed: false))

        #expect(withOption.routeOption == option)
        #expect(without.routeOption == nil)
    }

    // MARK: - 스팟 삽입

    /// 새 스팟은 **도착지 앞**에 들어간다 — 도착지는 도착지로 남아야 한다
    @Test func insertsSpotBeforeGoal() {
        let inserted = RouteRequestBuilder.insertingSpotBeforeGoal(newSpot, into: route)

        #expect(inserted.map { $0.name } == ["출발", "경유A", "경유B", "신규스팟", "도착"])
    }

    /// 삽입된 항목이 스팟의 값을 그대로 가져야 한다.
    /// typeCode만 다른 자리에 넣어 카테고리가 뒤바뀐 버그가 여기서 났다.
    @Test func insertedSpotCarriesItsOwnFields() throws {
        let inserted = RouteRequestBuilder.insertingSpotBeforeGoal(newSpot, into: route)
        let spot = try #require(inserted.first { $0.name == "신규스팟" })

        #expect(spot.typeCode == "A05")
        #expect(spot.contentId == "999")
        #expect(spot.contentTypeId == "39")
        #expect(spot.lon == "127.9")
        #expect(spot.lat == "37.9")
    }

    /// **핵심** — 삽입 후 그냥 조립하면 스팟 추가 본문이 나온다.
    /// 두 화면의 복붙 조립부가 이 한 줄로 대체된다.
    @Test func insertThenBuildProducesSpotAddBody() throws {
        let inserted = RouteRequestBuilder.insertingSpotBeforeGoal(newSpot, into: route)

        let body = try #require(RouteRequestBuilder.make(from: inserted, userId: 14, isUsed: false))

        #expect(fields(body.wayPoints, separator: "|") == ["127.1,37.1", "127.2,37.2", "127.9,37.9"])
        #expect(fields(body.typeCode) == ["A02", "A03", "A05"])
        #expect(fields(body.contentId) == ["200", "300", "999"])
        #expect(fields(body.contentTypeId) == ["14", "28", "39"])
        #expect(fields(body.locateName) == ["출발", "경유A", "경유B", "신규스팟", "도착"])
        #expect(body.goal == "127.3,37.3", "도착지는 그대로다")
    }

    /// 경유지가 없는 경로에 처음 스팟을 넣는 경우
    @Test func insertsIntoRouteWithoutWaypoints() throws {
        let twoPoints = [route[0], route[3]]

        let inserted = RouteRequestBuilder.insertingSpotBeforeGoal(newSpot, into: twoPoints)
        let body = try #require(RouteRequestBuilder.make(from: inserted, userId: 14, isUsed: false))

        #expect(fields(body.wayPoints, separator: "|") == ["127.9,37.9"])
        #expect(fields(body.locateName) == ["출발", "신규스팟", "도착"])
    }
}
