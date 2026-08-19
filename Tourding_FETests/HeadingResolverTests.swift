//
//  HeadingResolverTests.swift
//  Tourding_FETests
//
//  B6 — 방위(heading) 판정을 한 곳으로 모은다.
//
//  두 가지가 섞여 있었다.
//
//  ① 지도 카메라에 `magneticHeading`(자북)을 그대로 넣었다. NMap의 heading은 진북 기준이라
//     한국에서 편각만큼(서울 약 9도) 지도가 틀어져 회전했다. `trueHeading`은 Core Location이
//     편각을 반영해 주므로 편각 상수 없이 해소된다.
//
//  ② 같은 `locationOverlay.heading`에 두 경로가 서로 다른 기준으로 썼다 —
//     LocationManager는 자북에서, MapViewController는 진북 우선에서 각각 -45를 뺐다.
//
//  `CLHeading`은 공개 이니셜라이저가 없어 테스트에서 만들 수 없다. 그래서 판정을
//  원시값을 받는 순수 함수로 분리하고, 여기서 그 계약을 잠근다.
//  (실제 나침반 값과 화면 회전은 시뮬레이터로 검증할 수 없다.)
//

import CoreLocation
import Foundation
import Testing
@testable import Tourding_FE

struct HeadingResolverTests {

    // MARK: - 유효성

    /// headingAccuracy가 음수면 방위를 못 구한 것이다 — 써서는 안 된다
    @Test func rejectsHeadingWithNegativeAccuracy() {
        #expect(HeadingResolver.mapHeading(trueHeading: 90, magneticHeading: 99, accuracy: -1) == nil)
        #expect(HeadingResolver.markerHeading(trueHeading: 90, magneticHeading: 99, accuracy: -1) == nil)
    }

    // MARK: - 진북 / 자북

    /// 진북 값이 유효하면 그걸 쓴다 — 이게 편각(한국 약 9도)을 없애는 지점이다
    @Test func prefersTrueHeadingOverMagnetic() {
        let resolved = HeadingResolver.mapHeading(trueHeading: 90, magneticHeading: 99, accuracy: 5)

        #expect(resolved == 90, "자북(99)이 아니라 진북(90)을 써야 한다")
    }

    /// 진북을 못 구하면(음수) 자북으로 떨어진다 — 방향이 아예 없는 것보다는 낫다
    @Test func fallsBackToMagneticWhenTrueHeadingIsUnavailable() {
        let resolved = HeadingResolver.mapHeading(trueHeading: -1, magneticHeading: 99, accuracy: 5)

        #expect(resolved == 99)
    }

    /// trueHeading 무효값이 정확히 -1이라는 보장은 없다. 계약은 "음수"까지다
    @Test func treatsAnyNegativeTrueHeadingAsUnavailable() {
        let resolved = HeadingResolver.mapHeading(trueHeading: -180, magneticHeading: 42, accuracy: 5)

        #expect(resolved == 42)
    }

    // MARK: - 정규화

    @Test func normalizesToZeroUpToThreeSixty() {
        #expect(HeadingResolver.normalized(370) == 10)
        #expect(HeadingResolver.normalized(-35) == 325)
        #expect(HeadingResolver.normalized(0) == 0)
        #expect(HeadingResolver.normalized(359.5) == 359.5)
        #expect(HeadingResolver.normalized(720) == 0)
    }

    // MARK: - 마커 아이콘 오프셋

    /// 오프셋 값은 **에셋 실측치**다. 아이콘을 교체하면 이 테스트가 먼저 깨져야 한다.
    ///
    /// `userMarker.imageset/Group 35465.svg`의 화살표는 정북이 아니라 우상단을 가리킨다.
    /// 마커 중심 (28.2119, 28.2801), 화살촉 (35.529, 14.5143),
    /// 밑변 중점 (33.4506, 19.2939) → 화살표 자체 축이 화면 위 기준 시계방향 23.5도.
    ///
    /// 이전 값 -45는 근거가 없었다. 주석은 "이미지가 오른쪽 하단(135도)을 가리킨다"고 했지만
    /// 실제 에셋은 23.5도라, 마커가 상시 21.5도 왼쪽으로 틀어져 그려졌다.
    @Test func markerIconOffsetMatchesAssetMeasurement() {
        #expect(HeadingResolver.markerIconOffset == -23.5)
    }

    /// 마커는 아이콘 오프셋을 뺀 값을 쓴다
    @Test func markerHeadingAppliesIconOffset() {
        let resolved = HeadingResolver.markerHeading(trueHeading: 90, magneticHeading: 99, accuracy: 5)

        #expect(resolved == 66.5, "진북 90에서 아이콘 보정 23.5를 뺀 값")
    }

    /// 오프셋을 빼서 음수가 되면 정규화한다 — 예전에는 -35 같은 값이 그대로 들어갔다
    @Test func markerHeadingNormalizesNegativeResult() {
        let resolved = HeadingResolver.markerHeading(trueHeading: 10, magneticHeading: 10, accuracy: 5)

        #expect(resolved == 346.5, "10 - 23.5 = -13.5 → 346.5로 정규화되어야 한다")
    }

    /// 마커와 카메라는 **같은 원본**에서 나와야 한다.
    /// 두 경로가 서로 다른 북쪽 기준을 쓰던 것이 이 버그의 절반이었다.
    @Test func markerAndMapHeadingComeFromTheSameSource() throws {
        let mapValue = try #require(
            HeadingResolver.mapHeading(trueHeading: 200, magneticHeading: 191, accuracy: 5)
        )
        let markerValue = try #require(
            HeadingResolver.markerHeading(trueHeading: 200, magneticHeading: 191, accuracy: 5)
        )

        #expect(HeadingResolver.normalized(markerValue - HeadingResolver.markerIconOffset) == mapValue,
                "마커 방위에서 아이콘 오프셋을 되돌리면 지도 방위와 같아야 한다")
    }
}
