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
    /// 값의 근거 — `userMarker.imageset/Group 35465.svg` 실측:
    /// 마커 중심 (28.2119, 28.2801), 화살촉 (35.529, 14.5143), 밑변 중점 (33.4506, 19.2939)
    /// → 화살표 축이 화면 위 기준 시계방향 **23.5도**.
    ///
    /// 이전 값 -45는 근거가 없었다. 주석은 "이미지가 오른쪽 하단(135도)을 가리킨다"고 했지만
    /// 실제 에셋은 23.5도라, 마커가 상시 21.5도 왼쪽으로 틀어져 그려졌다.
    /// 자북→진북 전환으로 9도가 더해져 실기기에서 눈에 띄었다.
    static let markerIconOffset: CLLocationDirection = -23.5

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
