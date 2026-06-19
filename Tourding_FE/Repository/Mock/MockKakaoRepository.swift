//
//  MockKakaoRepository.swift
//  Tourding_FE
//

import Foundation

final class MockKakaoRepository: KakaoRepositoryProtocol {
    static let shared = MockKakaoRepository()

    var simulatedDelayNanoseconds: UInt64 = 300_000_000

    private init() {}

    func postRouteToilet(requestBody: ReqFacilityInfoModel) async throws -> [FacilityInfoModel] {
        try await simulateNetworkDelay()
        return try FixtureLoader.load("routes_toilet.json")
    }

    func postRouteConvenienceStore(requestBody: ReqFacilityInfoModel) async throws -> [FacilityInfoModel] {
        try await simulateNetworkDelay()
        return try FixtureLoader.load("routes_convenience_store.json")
    }

    private func simulateNetworkDelay() async throws {
        guard simulatedDelayNanoseconds > 0 else { return }
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
    }
}
