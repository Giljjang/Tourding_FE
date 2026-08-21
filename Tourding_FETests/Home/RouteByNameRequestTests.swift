//
//  RouteByNameRequestTests.swift
//  Tourding_FETests
//
//  변경된 서버 명세 정합.
//  POST /routes/by-name 은 이제 isUsed를 받아 "코스 라이딩 / 단순 검색" 저장 흐름을 가른다.
//  앱이 안 보내면 어느 버킷에 저장될지가 서버 기본값에 맡겨진다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RouteByNameRequestTests {

    /// 추천 코스는 편집 가능한 draft로 저장돼야 한다 (RidingView가 .draft로 진입한다)
    @Test func recommendedCourseRequestSavesAsDraft() async {
        let repository = FakeRouteRepository()
        repository.routes = RoutesModel(isUsed: false, duration: 1, distance: 1)
        let viewModel = HomeViewModel(
            routeRepository: repository,
            userSession: FakeUserSession(userId: 7),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository())
        )

        await viewModel.postRouteByNameAPI(start: "팔당대교", goal: "충주탄금대")

        let request = repository.capturedByNameRequests.last
        #expect(request?.isUsed == false, "추천 코스는 draft로 저장돼야 편집이 같은 경로를 읽는다")
        #expect(request?.userId == 7)
        #expect(request?.start == "팔당대교")
        #expect(request?.goal == "충주탄금대")
    }
}

/// 변경된 응답의 새 요약 필드들 — 오르막·고도·취향 점수는 AI 경로 재설정에서 쓰인다
struct RoutesModelFieldTests {

    @Test func decodesNewSummaryFieldsFromCurrentPayload() throws {
        let routes: RoutesModel = try FixtureLoader.load("routes_guide_response.json")

        #expect(routes.distance == 49457.3)
        #expect(routes.routeSummaryId == 59)
        #expect(routes.ascent == 654.7)
        #expect(routes.descent == 691.7)
        #expect(routes.uphillLevel == "HIGH")
        #expect(routes.preferenceScore == 0.7841)
        #expect(routes.appliedOption?.cyclingProfile == "cycling-regular")
        #expect(routes.appliedOption?.skillLevel == "BEGINNER")
    }

    /// 옛 응답(요약 3필드만)도 계속 읽혀야 한다 — 새 필드는 전부 옵셔널
    @Test func stillDecodesLegacySummaryOnlyPayload() throws {
        let routes: RoutesModel = try FixtureLoader.load("routes_total_unused.json")

        #expect(routes.isUsed == false)
        #expect(routes.ascent == nil)
        #expect(routes.appliedOption == nil)
    }
}
