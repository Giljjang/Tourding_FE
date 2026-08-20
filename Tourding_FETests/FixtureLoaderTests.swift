//
//  FixtureLoaderTests.swift
//  Tourding_FETests
//

import Testing
@testable import Tourding_FE

struct FixtureLoaderTests {

    @Test func loadsRoutesTotalFixture() throws {
        let routes: RoutesModel = try FixtureLoader.load("routes_total_unused.json")
        #expect(routes.isUsed == false)
        #expect(routes.distance == 12650)
        #expect(routes.duration == 2588.8)
    }

    @Test func loadsLocationNameWithWaypoints() throws {
        let locations: [LocationNameModel] = try FixtureLoader.load("routes_location_name_with_waypoints.json")
        #expect(locations.count == 3)
        #expect(locations[1].type == "WayPoint")
    }

    @Test func loadsRoutePathFixture() throws {
        let paths: [RoutePathModel] = try FixtureLoader.load("routes_path_unused.json")
        #expect(paths.count == 258)
    }

    @Test func mockRouteRepositoryReturnsGuideWithWaypointType() async throws {
        let repository = MockRouteRepository()
        repository.reset(scenario: .withWaypoints)
        repository.simulatedDelayNanoseconds = 0

        let guides = try await repository.getRoutesGuide(userId: 3, isUsed: false)
        #expect(guides.contains { $0.type == 9 })
    }
}
