//
//  RideStyleResolver.swift
//  Tourding_FE
//
//  "이번 경로에 쓸 라이딩 스타일"의 우선순위. **판정은 여기 한 곳뿐이다.**
//
//  두 군데로 갈려 있던 적이 있다 — 스타일 화면은 경로에 적용된 값을 보여주는데
//  변경 감지는 유저 프로필과 비교했다. 실측 로그에서 경로는 `cycling-road`인데
//  앱이 든 값은 `cycling-regular`였고, 그 상태로는 아무것도 바꾸지 않아도
//  "변경됨"으로 판정된다.
//
//  회귀 방지 테스트: `RideStyleResolverTests`
//

import Foundation

enum RideStyleResolver {

    /// 이번 경로에 실을 스타일.
    ///
    /// - `sessionOverride`: 코스 편집에서 방금 고른 일시 옵션. 서버에 저장하지 않는다
    /// - `appliedToRoute`: 지금 편집 중인 경로에 서버가 실제로 적용한 스타일
    /// - `isContinuingRoute`: 이어서 가는 경로인가 (최근 경로·비정상 복구)
    /// - `savedProfile`: 마이페이지에 저장된 프로필
    ///
    /// 우선순위는 "얼마나 이 경로에 가까운 값인가"다 —
    /// 방금 고른 값 > 이 경로에 적용된 값 > 계정 기본값.
    /// 새로 만드는 경로(홈·추천)는 `appliedToRoute`가 남아 있어도 이 경로의 값이
    /// 아니므로 건너뛴다.
    static func effectiveOption(
        sessionOverride: RouteOptionModel?,
        appliedToRoute: RouteOptionModel?,
        isContinuingRoute: Bool,
        savedProfile: RouteOptionModel?
    ) -> RouteOptionModel? {
        if let sessionOverride { return sessionOverride }
        if isContinuingRoute, let appliedToRoute { return appliedToRoute }
        return savedProfile
    }
}
