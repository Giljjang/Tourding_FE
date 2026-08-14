//
//  RouteDeleteRequestTests.swift
//  Tourding_FETests
//
//  버그 재현 — 추천 코스에서 경유지 삭제가 되지 않는다.
//
//  postRouteDeleteAPI가 contentId·contentTypeId·locateName을 **값 비교**로 걸러낸다.
//  경유지들이 같은 값을 공유하면(추천 코스는 contentTypeId가 전부 빈 문자열)
//  선택하지 않은 항목까지 함께 사라져 요청 배열의 길이가 어긋나고,
//  서버가 그 경로를 저장한 뒤 GET /routes/location-name에서 500을 반환한다.
//  앱은 3회 재시도 후 목록 갱신에 실패하므로 화면상 "삭제되지 않은" 것으로 보인다.
//

import Testing
@testable import Tourding_FE

@MainActor
struct RouteDeleteRequestTests {

    /// "a,b,c" → ["a","b","c"] / "" → []
    private func fields(_ raw: String, separator: String = ",") -> [String] {
        raw.isEmpty ? [] : raw.components(separatedBy: separator)
    }

    /// 실제 장애 재현: 추천 코스(경유지 3개, contentTypeId 전부 빈 문자열)에서 경유지 하나 삭제
    @Test func deleteFromRecommendedCourseKeepsEveryListAligned() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository, userId: 14)
        let route = TestRoute.recommendedCourseWithThreeWaypoints

        // 경유지 "양섬" 삭제 → 경유지 2개가 남아야 한다
        await viewModel.postRouteDeleteAPI(originalData: route, selectedData: route[2])

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다")
            return
        }

        #expect(fields(body.wayPoints, separator: "|").count == 2)
        #expect(fields(body.typeCode).count == 2)
        #expect(fields(body.contentId).count == 2)
        #expect(fields(body.contentTypeId).count == 2)
        #expect(fields(body.locateName).count == 4)
    }

    /// 삭제 대상만 빠져야 한다 — 남은 항목의 식별자가 그대로인지
    @Test func deleteRemovesOnlySelectedWaypoint() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository, userId: 14)
        let route = TestRoute.recommendedCourseWithThreeWaypoints

        await viewModel.postRouteDeleteAPI(originalData: route, selectedData: route[2])

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다")
            return
        }

        #expect(fields(body.contentId) == ["630741", "1687491"])
        #expect(fields(body.locateName) == ["아라한강갑문", "경안천 습지생태공원", "수룡폭포", "충주댐"])
    }

    /// 서버가 만든 경로는 contentId까지 비어 있을 수 있다 (routes_location_name_with_waypoints.json 형태).
    ///
    /// 경유지가 3개여야 결함이 드러난다 — 남는 경유지가 1개뿐이면 `[""]`을 join한 결과와
    /// `[]`를 join한 결과가 모두 `""`라 값 비교 필터의 오작동이 전선(wire)에서 구분되지 않는다.
    @Test func deleteKeepsAlignmentWhenContentIdsAreAllEmpty() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository, userId: 14)
        let route = [
            TestRoute.location(sequenceNum: 0, name: "출발", type: "Start", lat: "37.0", lon: "127.0",
                               typeCode: "", contentId: "", contentTypeId: ""),
            TestRoute.location(sequenceNum: 1, name: "경유1", type: "WayPoint", lat: "37.1", lon: "127.1",
                               typeCode: "", contentId: "", contentTypeId: ""),
            TestRoute.location(sequenceNum: 2, name: "경유2", type: "WayPoint", lat: "37.2", lon: "127.2",
                               typeCode: "", contentId: "", contentTypeId: ""),
            TestRoute.location(sequenceNum: 3, name: "경유3", type: "WayPoint", lat: "37.3", lon: "127.3",
                               typeCode: "", contentId: "", contentTypeId: ""),
            TestRoute.location(sequenceNum: 4, name: "도착", type: "Goal", lat: "37.4", lon: "127.4",
                               typeCode: "", contentId: "", contentTypeId: "")
        ]

        await viewModel.postRouteDeleteAPI(originalData: route, selectedData: route[2])

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다")
            return
        }

        // 경유지 2개가 남았으므로 메타데이터도 2칸이어야 한다 (빈 값이어도 자리는 유지)
        #expect(fields(body.wayPoints, separator: "|").count == 2)
        #expect(fields(body.contentId).count == 2)
        #expect(fields(body.contentTypeId).count == 2)
        #expect(fields(body.typeCode).count == 2)
    }

    /// 이름이 같은 스팟이 두 개 있어도 선택한 하나만 빠져야 한다
    @Test func deleteWithDuplicateNamesRemovesOnlySelected() async {
        let repository = FakeRouteRepository()
        let viewModel = makeTestRidingViewModel(repository: repository, userId: 14)
        let route = [
            TestRoute.location(sequenceNum: 0, name: "출발", type: "Start", lat: "37.0", lon: "127.0"),
            TestRoute.location(sequenceNum: 1, name: "편의점", type: "WayPoint", lat: "37.1", lon: "127.1"),
            TestRoute.location(sequenceNum: 2, name: "편의점", type: "WayPoint", lat: "37.2", lon: "127.2"),
            TestRoute.location(sequenceNum: 3, name: "도착", type: "Goal", lat: "37.3", lon: "127.3")
        ]

        await viewModel.postRouteDeleteAPI(originalData: route, selectedData: route[1])

        guard let body = repository.capturedPostRoutes.last else {
            Issue.record("POST /routes가 전송되지 않았다")
            return
        }

        #expect(fields(body.locateName) == ["출발", "편의점", "도착"])
        #expect(fields(body.wayPoints, separator: "|").count == 1)
    }
}
