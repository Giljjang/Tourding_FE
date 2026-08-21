//
//  MapGestureDetectionTests.swift
//  Tourding_FETests
//
//  B3 — 지도를 미는 첫 제스처가 추적만 끄고 지도는 밀리지 않던 문제.
//
//  예전에는 라이딩 중 지도 위에 투명 레이어를 얹어 터치를 감지했다.
//  그 레이어는 ZStack에서 `NMapView`의 **형제이자 위**라, 터치가 레이어로 가고
//  `NMFMapView`는 아예 받지 못했다(UIKit 제스처는 히트테스트된 뷰와 그 조상에게만 간다).
//  레이어가 사라지는 순간 진행 중이던 터치는 지도로 넘어가지 않고 취소되므로,
//  사용자는 **두 번 밀어야** 지도가 움직였다.
//
//  SDK가 이걸 위한 콜백을 준다 — `NMFMapViewCameraDelegate`의
//  `cameraWillChangeByReason:`가 `NMFMapChangedByGesture`로 알려준다.
//  레이어 없이 지도가 정상적으로 터치를 받고, 우리는 원인만 듣는다.
//
//  여기서 잠그는 것은 **원인 판정**이다. 델리게이트 등록과 실제 제스처는
//  NMFMapView가 필요해 테스트하지 않는다.
//

import Foundation
import NMapsMap
import Testing
@testable import Tourding_FE

@MainActor
struct MapGestureDetectionTests {

    /// 사용자가 지도를 직접 움직인 경우에만 추적을 끈다
    @Test func userGestureStopsTracking() {
        #expect(LocationManager.isUserGesture(cameraChangeReason: NMFMapChangedByGesture))
    }

    /// **핵심** — 우리 코드가 옮긴 카메라를 사용자 조작으로 오인하면 안 된다.
    ///
    /// `followUser`는 위치 갱신마다(3m) 카메라를 옮긴다. 이걸 제스처로 착각하면
    /// 추적이 켜지자마자 스스로 꺼진다. `reason`이 그 둘을 갈라준다.
    @Test func developerMoveDoesNotStopTracking() {
        #expect(LocationManager.isUserGesture(cameraChangeReason: NMFMapChangedByDeveloper) == false)
    }

    /// 위치 갱신으로 인한 이동도 사용자 조작이 아니다
    @Test func locationDrivenMoveDoesNotStopTracking() {
        #expect(LocationManager.isUserGesture(cameraChangeReason: NMFMapChangedByLocation) == false)
    }

    /// 콘텐츠 패딩(바텀시트 피봇 조정) 변경도 아니다
    @Test func contentPaddingChangeDoesNotStopTracking() {
        #expect(LocationManager.isUserGesture(cameraChangeReason: NMFMapChangedByContentPadding) == false)
    }

    /// 지도 컨트롤(줌 버튼·나침반)은 추적을 끄지 않는다.
    ///
    /// 판단: 줌을 조정하는 것은 "다른 곳을 보겠다"가 아니라 "지금 보는 곳을 더 크게"에 가깝다.
    /// 끄고 싶다면 이 테스트부터 바꿔야 한다 — 조용히 동작만 바뀌지 않도록 여기 고정한다.
    @Test func mapControlDoesNotStopTracking() {
        #expect(LocationManager.isUserGesture(cameraChangeReason: NMFMapChangedByControl) == false)
    }
}
