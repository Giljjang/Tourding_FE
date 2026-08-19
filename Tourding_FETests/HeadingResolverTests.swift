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

    /// 에셋 화살표가 정북을 가리키므로 보정이 필요 없다.
    ///
    /// 예전에는 화살표가 비스듬히 그려져 있어 보정값을 눈으로 맞췄고, 일곱 번 걸렸다.
    /// 마지막에 에셋 자체를 38.5도 회전시켜 보정을 없앴다.
    /// 아이콘을 교체해 다시 보정이 필요해지면 이 테스트가 먼저 깨진다.
    @Test func markerNeedsNoOffsetWhenAssetPointsNorth() {
        #expect(HeadingResolver.markerIconOffset == 0)
    }

    /// 마커는 아이콘 오프셋을 뺀 값을 쓴다
    @Test func markerHeadingAppliesIconOffset() {
        let resolved = HeadingResolver.markerHeading(trueHeading: 90, magneticHeading: 99, accuracy: 5)

        #expect(resolved == 90, "보정이 0이므로 진북 방위를 그대로 쓴다")
    }

    /// 범위를 벗어난 입력은 정규화한다 (보정이 0이 아니게 되면 음수도 나올 수 있다)
    @Test func markerHeadingNormalizesOutOfRangeInput() {
        #expect(HeadingResolver.markerHeading(trueHeading: 370, magneticHeading: 370, accuracy: 5) == 10)
        #expect(HeadingResolver.markerHeading(trueHeading: -1, magneticHeading: 365, accuracy: 5) == 5)
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

    // MARK: - 카메라 방위 보정

    /// **마커가 제대로 맞으면 카메라 보정은 0이어야 한다.**
    ///
    /// 헤딩-업에서 마커 화살표는 화면 위를 향해야 한다. 그러려면
    /// 카메라 방위 = 마커가 가리키는 실제 방위여야 하고,
    /// 마커가 실제 방위를 맞게 가리키고 있다면 카메라는 원본 방위를 그대로 쓰면 된다.
    ///
    /// 한때 -20을 넣었지만 그건 **마커가 아직 틀렸을 때** 눈으로 맞춘 값이었다.
    /// 마커를 바로잡은 뒤에는 카메라 보정이 불필요해진다.
    /// 손잡이는 남겨두되, 0이 아닌 값이 필요하다면 마커부터 의심할 것.
    @Test func cameraNeedsNoOffsetWhenMarkerIsCalibrated() {
        #expect(HeadingResolver.cameraHeadingOffset == 0)
    }

    @Test func cameraHeadingUsesResolvedHeadingAsIs() {
        #expect(HeadingResolver.cameraHeading(from: 90) == 90)
    }

    /// 입력이 범위를 벗어나도 정규화한다
    @Test func cameraHeadingNormalizesOutOfRangeInput() {
        #expect(HeadingResolver.cameraHeading(from: 370) == 10)
        #expect(HeadingResolver.cameraHeading(from: -5) == 355)
    }

    /// 카메라와 마커는 같은 원본에서 나오되 보정만 다르다
    @Test func cameraAndMarkerDifferOnlyByTheirOffsets() throws {
        let source = try #require(
            HeadingResolver.mapHeading(trueHeading: 200, magneticHeading: 191, accuracy: 5)
        )
        let camera = HeadingResolver.cameraHeading(from: source)
        let marker = try #require(
            HeadingResolver.markerHeading(trueHeading: 200, magneticHeading: 191, accuracy: 5)
        )

        let delta = HeadingResolver.normalized(marker - camera)
        let expected = HeadingResolver.normalized(
            HeadingResolver.markerIconOffset - HeadingResolver.cameraHeadingOffset
        )

        #expect(delta == expected, "두 값의 차이는 보정값 차이여야 한다")
    }
}
