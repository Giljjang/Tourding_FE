//
//  CameraPivotTests.swift
//  Tourding_FETests
//
//  편집 모드에서 "내 위치로 이동" 버튼이 바텀시트 높이를 반영하지 못하던 문제.
//
//  `cameraPivotY`를 시트 높이에 맞춰 갱신하는 코드가 라이딩 중 분기 안에만 있었다.
//  그래서 편집 모드에서는 시트를 올리든 내리든 기본값 0.3이 그대로 쓰였고,
//  버튼을 누르면 시트가 화면 절반을 덮는데도 마커가 화면 위 30% 지점에 놓였다.
//
//  더 나쁜 건 라이딩을 했다 편집으로 돌아온 경우다 — 그때는 0.6/0.4가 남아 있어
//  같은 버튼이 세션에 따라 다르게 동작했다.
//
//  시트 위치 → 피봇 매핑을 순수 함수로 빼서 여기서 잠근다.
//  (실제 카메라 이동은 NMFMapView가 필요해 테스트하지 않는다.)
//

import CoreGraphics
import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct CameraPivotTests {

    /// 시트가 작을수록 지도가 넓게 보이므로 시점을 더 위로 둔다
    @Test func pivotFollowsSheetPosition() {
        #expect(LocationManager.cameraPivot(for: .small) == 0.6)
        #expect(LocationManager.cameraPivot(for: .medium) == 0.4)
    }

    /// large는 지도가 거의 가려지므로 카메라를 건드리지 않는다
    @Test func largeSheetDoesNotChangePivot() {
        #expect(LocationManager.cameraPivot(for: .large) == nil)
    }

    /// 매핑은 모든 케이스를 다룬다 — 새 시트 위치가 생기면 여기서 걸린다
    @Test func everySheetPositionIsHandled() {
        for position in BottomSheetPosition.allCases {
            let pivot = LocationManager.cameraPivot(for: position)
            if position == .large {
                #expect(pivot == nil)
            } else {
                let value = pivot ?? -1
                #expect(value > 0 && value < 1, "\(position)의 피봇이 화면 밖이다: \(value)")
            }
        }
    }

    /// 기본값은 편집 모드 진입 시점의 값이다 — 시트 동기화 전까지 이 값이 쓰인다
    @Test func defaultPivotIsUnchangedUntilSynced() {
        let locationManager = LocationManager()

        #expect(locationManager.cameraPivotY == 0.3)
    }

    /// 편집 모드에서도 시트 높이가 저장돼야 "내 위치로 이동"이 같은 피봇을 쓴다
    @Test func syncingSheetPositionStoresPivot() {
        let locationManager = LocationManager()

        locationManager.syncCameraPivot(for: .medium)

        #expect(locationManager.cameraPivotY == 0.4)
    }

    /// large는 저장도 하지 않는다 (카메라를 건드리지 않기로 한 위치)
    @Test func syncingLargeKeepsPreviousPivot() {
        let locationManager = LocationManager()
        locationManager.syncCameraPivot(for: .small)

        locationManager.syncCameraPivot(for: .large)

        #expect(locationManager.cameraPivotY == 0.6, "large에서는 직전 값을 유지한다")
    }
}
