//
//  MockRouteRepository.swift
//  Tourding_FE
//

import Foundation

final class MockRouteRepository: RouteRepositoryProtocol {

    enum RouteScenario {
        case simple
        case withWaypoints
    }

    private(set) var scenario: RouteScenario = .withWaypoints
    var simulatedDelayNanoseconds: UInt64 = 300_000_000

    init() {}

    func reset(scenario: RouteScenario = .withWaypoints) {
        self.scenario = scenario
    }

    func postRoutes(requestBody: RequestRouteModel) async throws {
        try await simulateNetworkDelay()
        scenario = requestBody.wayPoints.isEmpty ? .simple : .withWaypoints
        print("🧪 MockRouteRepository.postRoutes scenario=\(scenario)")
    }

    func getRoutesPath(userId: Int, isUsed: Bool) async throws -> [RoutePathModel] {
        try await simulateNetworkDelay()
        let filename = isUsed ? "routes_path_used.json" : "routes_path_unused.json"
        return try FixtureLoader.load(filename)
    }

    func getRoutesLocationName(userId: Int, isUsed: Bool) async throws -> [LocationNameModel] {
        try await simulateNetworkDelay()
        let filename = locationNameFixtureName()
        return try FixtureLoader.load(filename)
    }

    func getRoutesGuide(userId: Int, isUsed: Bool) async throws -> [GuideModel] {
        try await simulateNetworkDelay()
        let filename = guideFixtureName()
        return try FixtureLoader.load(filename)
    }

    func getRoutes(userId: Int, isUsed: Bool) async throws -> RoutesModel {
        try await simulateNetworkDelay()
        let filename = isUsed ? "routes_total_used.json" : "routes_total_unused.json"
        return try FixtureLoader.load(filename)
    }

    func getRoutesRidingRecommend(pageNum: Int) async throws -> [RouteRidingRecommendModel] {
        try await simulateNetworkDelay()
        return try FixtureLoader.load("routes_riding_recommend_page1.json")
    }

    func postRoutesByName(requestBody: ReqRoutesByNameModel) async throws -> RoutesModel {
        try await simulateNetworkDelay()
        return try FixtureLoader.load("post_routes_home_response.json")
    }

    private func locationNameFixtureName() -> String {
        switch scenario {
        case .simple:
            return "routes_location_name_simple.json"
        case .withWaypoints:
            return "routes_location_name_with_waypoints.json"
        }
    }

    private func guideFixtureName() -> String {
        switch scenario {
        case .simple:
            return "routes_guide_simple.json"
        case .withWaypoints:
            return "routes_guide_with_waypoints.json"
        }
    }

    private func simulateNetworkDelay() async throws {
        guard simulatedDelayNanoseconds > 0 else { return }
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
    }
}
