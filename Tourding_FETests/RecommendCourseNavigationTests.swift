//
//  RecommendCourseNavigationTests.swift
//  Tourding_FETests
//
//  "추천 코스를 눌렀는데 내가 입력했던 출발지-도착지가 나온다" (간헐)
//
//  추천 코스는 서버에 따로 저장되지 않는다. POST /routes/by-name 이 사용자의
//  draft 슬롯에 덮어쓴다 — 본인이 만든 코스와 같은 자리다(둘 다 routeSummaryId 59).
//  그래서 by-name이 실패하면 draft에 옛 코스가 그대로 남고, 화면은 그걸 읽는다.
//
//  실측 로그:
//    /routes/by-name      status=500
//    /routes/location-name status=200  [흥해읍 → 다무포하얀마을 → 호미곶]  ← 내 코스
//
//  postRouteByNameAPI가 실패를 삼키고 호출부가 무조건 push해서 생긴다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RecommendCourseNavigationTests {

    private func makeViewModel(
        _ repository: FakeRouteRepository,
        userId: Int? = 49
    ) -> HomeViewModel {
        HomeViewModel(
            routeRepository: repository,
            userSession: FakeUserSession(userId: userId),
            profileStore: RidingProfileStore(userRepository: FakeUserRepository())
        )
    }

    /// 저장에 성공해야만 추천 코스 화면으로 넘어갈 자격이 있다
    @Test func reportsSuccessWhenCourseIsSaved() async {
        let repository = FakeRouteRepository()
        repository.routes = RoutesModel(isUsed: false, duration: 1, distance: 1)
        let viewModel = makeViewModel(repository)

        let saved = await viewModel.postRouteByNameAPI(start: "안동댐", goal: "병산서원")

        #expect(saved == true)
        #expect(repository.capturedByNameRequests.count == 1)
    }

    /// 서버가 실패하면 draft에는 옛 코스가 남는다. 넘어가면 그걸 보여주게 된다.
    @Test func reportsFailureWhenServerRejects() async {
        let repository = FakeRouteRepository()
        repository.byNameError = FakeRouteRepository.FakeError.postFailed
        let viewModel = makeViewModel(repository)

        let saved = await viewModel.postRouteByNameAPI(start: "간현", goal: "충주")

        #expect(saved == false, "실패를 삼키면 엉뚱한 코스가 표시된다")
    }

    /// 세션이 아직 없으면 POST 자체가 나가지 않는다 — 이것도 성공이 아니다
    @Test func reportsFailureWhenUserIdIsMissing() async {
        let repository = FakeRouteRepository()
        repository.routes = RoutesModel(isUsed: false, duration: 1, distance: 1)
        let viewModel = makeViewModel(repository, userId: nil)

        let saved = await viewModel.postRouteByNameAPI(start: "안동댐", goal: "병산서원")

        #expect(saved == false)
        #expect(repository.capturedByNameRequests.isEmpty)
    }
}
