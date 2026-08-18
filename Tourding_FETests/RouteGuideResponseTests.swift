//
//  RouteGuideResponseTests.swift
//  Tourding_FETests
//
//  버그 3 재현 — "코스 편집 후 라이딩 시작하기를 했을 때 가이드 메시지가 보이지 않는다"
//
//  서버가 GET /routes/guide 응답을 [GuideModel] 배열에서 RouteGuideRespDto 객체로 바꿨다.
//  앱은 여전히 배열로 디코딩해 typeMismatch로 실패하고, 재시도 3회가 전부 같은 이유로 실패한 뒤
//  guideList가 빈 채로 남는다. 실패는 print로만 남아 화면에는 아무 표시가 없다.
//

import Foundation
import Testing
@testable import Tourding_FE

struct RouteGuideResponseTests {

    private static let fixture = "routes_guide_response.json"

    /// 지금 서버가 주는 형태에서 가이드를 꺼낼 수 있어야 한다
    @Test func decodesGuidesFromCurrentServerPayload() throws {
        let response: RouteGuideResponse = try FixtureLoader.load(Self.fixture)

        #expect(response.guides.count == 4)
        #expect(response.guides.first?.instructions == "출발지")
        #expect(response.guides.contains { $0.type == 9 }, "경유지 안내(type 9)가 있어야 한다")
    }

    /// 요약·경로선·장소도 같은 응답에 들어 있다 — 호출 통합 시 쓸 수 있어야 한다
    @Test func decodesSummaryAndCollectionsFromSamePayload() throws {
        let response: RouteGuideResponse = try FixtureLoader.load(Self.fixture)

        #expect(response.routeSummaryId == 59)
        #expect(response.distance == 49457.3)
        #expect(response.duration == 9967.4)
        #expect(response.locations.count == 3)
        #expect(response.paths.count == 2)
    }

    /// 버그의 이유를 고정한다 — 옛 방식(배열)으로는 지금 응답을 못 읽는다.
    /// 이 테스트는 현재 동작을 특성화한 것이라 처음부터 통과한다.
    @Test func legacyArrayDecodingFailsOnCurrentServerPayload() throws {
        #expect(throws: (any Error).self) {
            let _: [GuideModel] = try FixtureLoader.load(Self.fixture)
        }
    }
}
