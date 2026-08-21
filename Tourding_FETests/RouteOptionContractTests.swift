//
//  RouteOptionContractTests.swift
//  Tourding_FETests
//
//  서버가 라이딩 옵션(`routeOption`)을 경로 계산에 반영하도록 바뀌었다.
//
//  요청: POST /routes · POST /routes/by-name 이 `routeOption`을 받는다.
//  응답: 서버가 실제로 적용한 옵션을 `appliedOption`으로,
//        그 밖에 ascent·descent·uphillLevel·preferenceScore를 돌려준다.
//
//  **요청의 `routeOption`은 옵셔널이지만, 실무상 항상 실어야 한다.**
//  서버는 이 값이 없으면 디폴트로 계산한다 — 저장된 프로필을 꺼내 쓰지 않는다.
//  여기서 잠그는 것은 인코딩 계약이다: nil일 때 `null`이 아니라 **키가 통째로 빠져야** 한다.
//  실제로 어느 화면이 값을 싣는지는 `RouteOptionWiringTests`가 잠근다.
//
//  **응답의 새 필드는 전부 옵셔널이다.** 필드 하나 때문에 응답 전체가 폐기되는 실패를
//  두 번 겪었다(/routes/guide 형태 변경, 상세의 분류 필드 누락).
//

import Foundation
import Testing
@testable import Tourding_FE

struct RouteOptionContractTests {

    private let sampleOption = RouteOptionModel(
        cyclingProfile: "ROAD",
        fastRoute: true,
        avoidSteps: true,
        avoidFords: false,
        skillLevel: "INTERMEDIATE"
    )

    private func encodedKeys(_ value: some Encodable) throws -> Set<String> {
        let data = try JSONEncoder().encode(value)
        let object = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        return Set(object.keys)
    }

    // MARK: - 요청 (POST /routes)

    @Test func routeRequestCarriesRouteOption() throws {
        let body = RequestRouteModel(
            userId: 49, start: "129.0,36.0", goal: "129.5,36.5",
            wayPoints: "", locateName: "출발,도착",
            typeCode: "", contentId: "", contentTypeId: "",
            isUsed: false, routeOption: sampleOption
        )

        let data = try JSONEncoder().encode(body)
        let decoded = try JSONDecoder().decode(RequestRouteModel.self, from: data)

        #expect(decoded.routeOption == sampleOption)
    }

    /// **nil이면 키 자체가 빠져야 한다.** null을 보내면 서버가 "옵션 없음"으로 볼 수 있다
    @Test func routeRequestOmitsRouteOptionWhenAbsent() throws {
        let body = RequestRouteModel(
            userId: 49, start: "129.0,36.0", goal: "129.5,36.5",
            wayPoints: "", locateName: "출발,도착",
            typeCode: "", contentId: "", contentTypeId: "",
            isUsed: false
        )

        #expect(try encodedKeys(body).contains("routeOption") == false)
    }

    // MARK: - 요청 (POST /routes/by-name)

    @Test func byNameRequestCarriesRouteOption() throws {
        let body = ReqRoutesByNameModel(
            userId: 49, start: "신매대교", goal: "춘천애니메이션센터",
            isUsed: false, routeOption: sampleOption
        )

        let data = try JSONEncoder().encode(body)
        let decoded = try JSONDecoder().decode(ReqRoutesByNameModel.self, from: data)

        #expect(decoded.routeOption == sampleOption)
    }

    @Test func byNameRequestOmitsRouteOptionWhenAbsent() throws {
        let body = ReqRoutesByNameModel(
            userId: 49, start: "신매대교", goal: "춘천애니메이션센터", isUsed: false
        )

        #expect(try encodedKeys(body).contains("routeOption") == false)
    }

    // MARK: - 응답 (RouteGuideResponse)

    @Test func responseCarriesAppliedOptionAndElevation() throws {
        let json = """
        {
          "routeSummaryId": 60, "isUsed": true, "duration": 100, "distance": 200,
          "ascent": 120.5, "descent": 98.25, "uphillLevel": "MEDIUM", "preferenceScore": 0.82,
          "appliedOption": {
            "cyclingProfile": "ROAD", "fastRoute": true,
            "avoidSteps": true, "avoidFords": false, "skillLevel": "INTERMEDIATE"
          },
          "guides": [], "paths": [], "locations": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RouteGuideResponse.self, from: json)

        #expect(response.ascent == 120.5)
        #expect(response.descent == 98.25)
        #expect(response.uphillLevel == "MEDIUM")
        #expect(response.preferenceScore == 0.82)
        #expect(response.appliedOption == sampleOption)
    }

    /// **핵심** — 새 필드가 없는 응답도 그대로 살아야 한다.
    /// 필드 하나 때문에 응답 전체가 폐기되는 실패를 두 번 겪었다.
    @Test func responseSurvivesWithoutNewFields() throws {
        let json = """
        {
          "routeSummaryId": 60, "isUsed": true, "duration": 100, "distance": 200,
          "guides": [], "paths": [], "locations": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RouteGuideResponse.self, from: json)

        #expect(response.routeSummaryId == 60)
        #expect(response.appliedOption == nil)
        #expect(response.ascent == nil)
    }

    /// 서버가 아직 모르는 필드(`extraInfo` 등)를 보내도 디코딩이 깨지면 안 된다
    @Test func responseIgnoresUnknownFields() throws {
        let json = """
        {
          "routeSummaryId": 60, "isUsed": true, "duration": 100, "distance": 200,
          "guides": [], "paths": [], "locations": [],
          "extraInfo": { "somethingNew": { "a": 1 } }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RouteGuideResponse.self, from: json)

        #expect(response.routeSummaryId == 60)
    }
}
