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

    /// 마커 아이콘 보정각. **에셋이 정북을 가리키므로 0이다.**
    ///
    /// 예전에는 `userMarker` 에셋의 화살표가 비스듬히 그려져 있어 그만큼 되돌려야 했다.
    /// 그 값을 눈으로 맞추는 데 일곱 번 걸렸다 — SVG 좌표로 계산한 값이 실기기와
    /// 두 번 어긋났기 때문이다. 그래서 마지막에 **에셋 자체를 38.5도 회전시켜**
    /// 화살표를 정북으로 맞추고 보정을 없앴다.
    ///
    /// 손잡이는 남겨둔다 — 아이콘을 교체하면 다시 필요할 수 있고,
    /// 그때 `HeadingResolverTests`가 먼저 깨져 알려준다.
    /// **값을 SVG 좌표로 계산해서 넣지 마라. 실기기에서 확인할 것.**
    static let markerIconOffset: CLLocationDirection = 0

    /// 지도 카메라 방위 보정각. **`markerIconOffset`과 별개 손잡이다.**
    ///
    /// 마커 보정은 아이콘 그림이 정북을 안 가리켜서 되돌리는 값이고,
    /// 이건 지도 자체를 돌린다. 원인이 다르므로 한 값으로 묶지 말 것.
    ///
    /// **마커가 제대로 맞으면 이 값은 0이다.**
    ///
    /// 헤딩-업에서 마커 화살표는 화면 위를 향해야 한다. 그러려면
    /// 카메라 방위 = 마커가 가리키는 실제 방위여야 하는데, 마커가 실제 방위를 맞게
    /// 가리키고 있다면 카메라는 `mapHeading`이 고른 원본을 그대로 쓰면 된다.
    ///
    /// 한때 -20을 넣었지만 그건 **마커가 아직 틀렸을 때** 눈으로 맞춘 값이었다.
    /// 마커를 바로잡으면서 불필요해졌다. 손잡이는 남겨두되,
    /// 0이 아닌 값이 필요해 보이면 **마커 보정부터 의심할 것**.
    ///
    /// 부호 규약: `heading`은 "카메라가 바라보는 방위"라 값이 **커지면 지도 내용물이
    /// 반시계(왼쪽)로** 돈다.
    static let cameraHeadingOffset: CLLocationDirection = 0

    /// 지도 카메라에 넣을 최종 방위. `mapHeading`이 고른 진북 기준 값에 카메라 보정만 더한다.
    static func cameraHeading(from resolved: CLLocationDirection) -> CLLocationDirection {
        normalized(resolved + cameraHeadingOffset)
    }

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
