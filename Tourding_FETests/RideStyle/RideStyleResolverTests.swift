//
//  RideStyleResolverTests.swift
//  Tourding_FETests
//
//  "이번 경로에 쓸 스타일"의 우선순위를 한 곳에 모은다.
//
//  판정이 두 군데로 갈려 있었다 —
//    스타일 화면은 경로에 적용된 값(`appliedOption`)을 보여주는데,
//    변경 감지는 유저 프로필과 비교했다.
//  실측 로그에서 경로는 `cycling-road`인데 앱이 든 값은 `cycling-regular`였다.
//  그 상태로는 아무것도 바꾸지 않아도 "변경됨"이 되고, 판정이 뒤집힐 수 있다.
//

import Foundation
import Testing
@testable import Tourding_FE

struct RideStyleResolverTests {

    private let override = RouteOptionModel(
        cyclingProfile: "cycling-mountain", fastRoute: false,
        avoidSteps: false, avoidFords: false, skillLevel: "PRO"
    )
    private let applied = RouteOptionModel(
        cyclingProfile: "cycling-road", fastRoute: true,
        avoidSteps: true, avoidFords: true, skillLevel: "BEGINNER"
    )
    private let profile = RouteOptionModel(
        cyclingProfile: "cycling-regular", fastRoute: true,
        avoidSteps: true, avoidFords: true, skillLevel: "BEGINNER"
    )

    /// **1순위 — 방금 고른 일시 옵션.** 사용자가 화면에서 막 정한 값이다
    @Test func sessionOverrideWinsOverEverything() {
        #expect(
            RideStyleResolver.effectiveOption(
                sessionOverride: override,
                appliedToRoute: applied,
                isContinuingRoute: true,
                savedProfile: profile
            ) == override
        )
    }

    /// **2순위 — 이어서 가는 경로에 적용된 스타일.**
    /// 최근 경로·비정상 복구는 이미 그 스타일로 계산돼 저장돼 있다.
    @Test func appliedOptionWinsWhenContinuingRoute() {
        #expect(
            RideStyleResolver.effectiveOption(
                sessionOverride: nil,
                appliedToRoute: applied,
                isContinuingRoute: true,
                savedProfile: profile
            ) == applied
        )
    }

    /// **3순위 — 저장된 프로필.** 홈·추천에서 새로 만드는 경로가 여기 해당한다.
    /// draft에는 `appliedOption`이 남아 있어도 이 경로의 값이 아니다.
    @Test func profileWinsForNewRoute() {
        #expect(
            RideStyleResolver.effectiveOption(
                sessionOverride: nil,
                appliedToRoute: applied,
                isContinuingRoute: false,
                savedProfile: profile
            ) == profile
        )
    }

    /// 이어서 가는 경로인데 서버가 적용값을 안 내려줬으면 프로필로 내려간다
    @Test func fallsBackToProfileWhenRouteHasNoAppliedOption() {
        #expect(
            RideStyleResolver.effectiveOption(
                sessionOverride: nil,
                appliedToRoute: nil,
                isContinuingRoute: true,
                savedProfile: profile
            ) == profile
        )
    }

    /// 아무것도 없으면 nil — 이때만 서버가 디폴트로 계산한다
    @Test func returnsNilWhenNothingKnown() {
        #expect(
            RideStyleResolver.effectiveOption(
                sessionOverride: nil,
                appliedToRoute: nil,
                isContinuingRoute: true,
                savedProfile: nil
            ) == nil
        )
    }

    /// 일시 옵션은 새 경로(draft)에도 적용된다 —
    /// 사용자가 방금 고른 값이므로 경로 종류와 무관하다
    @Test func sessionOverrideAppliesToNewRouteToo() {
        #expect(
            RideStyleResolver.effectiveOption(
                sessionOverride: override,
                appliedToRoute: nil,
                isContinuingRoute: false,
                savedProfile: profile
            ) == override
        )
    }
}
