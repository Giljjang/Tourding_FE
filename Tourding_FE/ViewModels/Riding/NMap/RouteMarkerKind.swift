//
//  RouteMarkerKind.swift
//  Tourding_FE
//
//  경로 마커의 종류와 경유지 순번 — 지도 SDK에 의존하지 않는 순수 값.
//
//  `NMFOverlayImage`는 `numberMarker(1)`과 `numberMarker(2)`를 값으로 구분할 수 없어
//  "경유지 번호는 배열 index가 아니라 WayPoint 순번"이라는 규칙을 테스트로 고정할 수 없었다.
//

import Foundation

enum RouteMarkerKind: Equatable {
    case start
    case goal
    case waypoint(number: Int)
    case unknown
}
