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
    /// 조정 이력: -45 → -23.5 → -3.5 → +16.5 → +6.5 → -8.5 → **-38.5**.
    ///
    /// 마지막 값은 실기기 스크린샷 두 장을 비교해 역산했다.
    /// 화면상 화살표 각도 = 아이콘그림각 A + `markerIconOffset` - `cameraHeadingOffset`
    /// 이므로, 두 스크린샷의 보정값 차이와 화살표 이동량에서 A ≈ 38.5도가 나온다.
    /// 화살표가 화면 위를 향하려면 보정값 = -A.
    /// SVG 기하로는 화살표가 우상단 23.5~29.3도를 가리키는 것으로 계산됐지만 실기기와 맞지 않았다.
    /// **렌더된 아이콘의 실제 방향이 SVG 좌표 계산과 다르다** — 어디서 어긋나는지는 미규명이다.
    /// 그래서 이 값은 계산으로 유도하지 말고, 바꿀 일이 생기면 실기기에서 확인할 것.
    ///
    /// (중간에 "오프셋을 옮겨도 티가 안 난다"는 보고가 있었으나, 최종적으로 화면에
    /// 반영되는 것이 확인됐다. 20도 안팎은 21pt 아이콘에서 눈에 잘 띄지 않을 뿐이다.)
    static let markerIconOffset: CLLocationDirection = -38.5

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
