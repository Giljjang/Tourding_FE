//
//  HeadingResolver.swift
//  Tourding_FE
//
//  방위(heading) 판정 단일 지점.
//
//  카메라와 사용자 마커가 **같은 원본**을 쓰도록 강제한다.
//  이전에는 LocationManager가 자북에서, MapViewController가 진북 우선에서 각각 -45를 빼
//  같은 `locationOverlay.heading`에 서로 다른 기준의 값을 썼다.
//
//  `CLHeading`은 공개 이니셜라이저가 없어 테스트에서 만들 수 없다.
//  그래서 원시값을 받는 순수 함수로 두고 `HeadingResolverTests`가 계약을 잠근다.
//

import CoreLocation
import Foundation

enum HeadingResolver {

    /// 마커 아이콘 화살표가 정북을 가리키지 않아 더해주는 보정각.
    ///
    /// 편각(자북↔진북) 보정이 **아니다**. 순수하게 에셋이 그려진 방향을 되돌리는 값이므로,
    /// 아이콘을 교체하면 이 값도 같이 바뀌어야 한다 (`HeadingResolverTests`가 먼저 깨진다).
    ///
    /// 값의 근거는 **실기기 관측**이다. SVG 좌표 계산이 아니다.
    ///
    /// SVG 기하로는 화살표가 우상단 23.5~29.3도를 가리키는 것으로 나와 -23.5를 먼저 썼지만,
    /// 실기기에서는 그 값으로도 마커가 왼쪽으로 치우쳐 보였다. 관측에 맞춰 -3.5로 조정했다.
    /// **렌더된 아이콘의 실제 방향이 SVG 좌표 계산과 다르다** — 어디서 어긋나는지는 미규명.
    ///
    /// 이 값이 0에 가깝다는 건 보정이 거의 불필요하다는 뜻이다.
    /// 에셋 화살표를 정북으로 맞추면 이 상수를 지울 수 있다 (별건).
    static let markerIconOffset: CLLocationDirection = -3.5

    /// 지도 카메라에 넣을 방위. **진북 기준**이다.
    ///
    /// NMap의 heading은 진북 기준인데 `magneticHeading`을 그대로 넣으면
    /// 편각만큼(서울 약 9도) 지도가 틀어져 회전한다. `trueHeading`은 Core Location이
    /// 편각을 이미 반영해 주므로 편각 상수를 들고 있을 필요가 없다.
    ///
    /// `trueHeading`은 같은 매니저에서 위치 업데이트가 켜져 있어야 유효하고,
    /// 구하지 못하면 **음수**를 준다(정확히 -1이라는 보장은 없다).
    ///
    /// - Returns: 방위를 구하지 못했으면 `nil`
    static func mapHeading(
        trueHeading: CLLocationDirection,
        magneticHeading: CLLocationDirection,
        accuracy: CLLocationDirection
    ) -> CLLocationDirection? {
        guard accuracy >= 0 else { return nil }

        let source = trueHeading >= 0 ? trueHeading : magneticHeading
        return normalized(source)
    }

    /// 사용자 마커 오버레이에 넣을 방위. 지도와 같은 원본에 아이콘 보정만 더한다.
    static func markerHeading(
        trueHeading: CLLocationDirection,
        magneticHeading: CLLocationDirection,
        accuracy: CLLocationDirection
    ) -> CLLocationDirection? {
        guard let base = mapHeading(
            trueHeading: trueHeading,
            magneticHeading: magneticHeading,
            accuracy: accuracy
        ) else { return nil }

        return normalized(base + markerIconOffset)
    }

    /// `0 ..< 360`으로 접는다. 보정을 빼면 음수가 나올 수 있다.
    static func normalized(_ degrees: CLLocationDirection) -> CLLocationDirection {
        let wrapped = degrees.truncatingRemainder(dividingBy: 360)
        return wrapped < 0 ? wrapped + 360 : wrapped
    }
}

// MARK: - CLHeading 어댑터

extension HeadingResolver {

    /// `CLHeading`은 공개 이니셜라이저가 없어 테스트에서 만들 수 없다.
    /// 그래서 필드 추출만 하는 얇은 어댑터로 두고, 판정 자체는 위 순수 함수가 갖는다.
    static func mapHeading(from heading: CLHeading) -> CLLocationDirection? {
        mapHeading(
            trueHeading: heading.trueHeading,
            magneticHeading: heading.magneticHeading,
            accuracy: heading.headingAccuracy
        )
    }

    static func markerHeading(from heading: CLHeading) -> CLLocationDirection? {
        markerHeading(
            trueHeading: heading.trueHeading,
            magneticHeading: heading.magneticHeading,
            accuracy: heading.headingAccuracy
        )
    }
}
