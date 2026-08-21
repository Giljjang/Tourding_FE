//
//  RidingEditorLifetimeTests.swift
//  Tourding_FETests
//
//  코스 편집 화면이 **NavigationStack에서 사라졌는가**를 판정한다.
//
//  일시 스타일은 편집 창이 살아 있는 동안 유지되고, 창이 사라지면 걷힌다.
//  그런데 `onDisappear`는 **자식 화면으로 push할 때도 불린다** —
//  스팟 추가나 라이딩 스타일 화면으로 들어갈 때마다 세션이 끝나 버리면
//  "편집 중에는 유지"가 성립하지 않는다.
//
//  스택에 아직 코스 편집이 남아 있는지로 두 경우를 가른다.
//  뒤로가기 버튼과 라이딩 종료에도 직접 걸어 두었지만, 시스템 스와이프 백처럼
//  버튼을 거치지 않는 경로가 있어 스택 판정이 최종 안전망이다.
//

import Foundation
import Testing
@testable import Tourding_FE

@MainActor
struct RidingEditorLifetimeTests {

    private func manager(_ path: [ViewType]) -> NavigationManager {
        let manager = NavigationManager()
        manager.path = path
        return manager
    }

    // MARK: - 케이스 판정

    /// 연관값이 달라도 같은 화면이다 — 진입 방식마다 값이 다르다
    @Test func recognizesRidingViewRegardlessOfArguments() {
        #expect(ViewType.RidingView().isRidingEditor)
        #expect(ViewType.RidingView(routeSource: .recentUsed).isRidingEditor)
        #expect(ViewType.RidingView(isNotNormal: true, isStart: true).isRidingEditor)
    }

    @Test func otherViewsAreNotRidingEditor() {
        #expect(ViewType.HomeView.isRidingEditor == false)
        #expect(ViewType.RidingStyleSettingsView(isTemporary: true).isRidingEditor == false)
        #expect(ViewType.SpotAddView(lat: "1", lon: "2", sessionId: UUID()).isRidingEditor == false)
    }

    // MARK: - 스택 판정

    /// **자식 화면으로 들어간 경우 — 편집 창은 아직 살아 있다.**
    /// 여기서 세션을 끝내면 스타일을 고르러 갔다 올 때마다 초기화된다.
    @Test func editorStaysOnStackWhilePushingChildScreens() {
        #expect(manager([.RidingView(routeSource: .recentUsed),
                         .RidingStyleSettingsView(isTemporary: true)]).holdsRidingEditor)
        #expect(manager([.RidingView(),
                         .SpotAddView(lat: "1", lon: "2", sessionId: UUID())]).holdsRidingEditor)
    }

    /// 편집 화면 자신만 있어도 살아 있는 것이다
    @Test func editorAloneCountsAsAlive() {
        #expect(manager([.RidingView(routeSource: .recentUsed)]).holdsRidingEditor)
    }

    /// **스택에서 빠지면 끝난 것이다** — 뒤로가기·스와이프 백·popToRoot 모두 여기 해당한다
    @Test func editorIsGoneWhenPoppedOffTheStack() {
        #expect(manager([]).holdsRidingEditor == false)
        #expect(manager([.HomeView]).holdsRidingEditor == false)
        #expect(manager([.MyPageView, .RidingStyleSettingsView()]).holdsRidingEditor == false)
    }

    // MARK: - 비정상 종료 복구

    /// **복구는 저장된 라이딩 경로를 이어서 간다 — 라이딩을 끝내도 그대로다.**
    ///
    /// 복구 진입은 `routeSource`가 `.draft`로 들어오고 `flag`로만 라이딩 중이 된다.
    /// 그대로 두면 `endRiding`이 `flag`를 false로 되돌리는 순간
    /// `isUsedRoute`(`flag || routeSource.isUsed`)가 false로 떨어져
    /// **편집 대상이 draft로 바뀐다** — 경로도, 그 경로의 스타일도 딴 것이 뜬다.
    @Test func abnormalRecoveryKeepsUsedRouteAfterEndingRide() async {
        let viewModel = makeTestRidingViewModel()

        viewModel.handleInitialEntry(
            locationManager: LocationManager(),
            isNotNormal: true,
            isStart: true,
            routeSource: .draft,       // 호출부가 기본값으로 넘긴다
            onStartRiding: {}
        )
        #expect(viewModel.isUsedRoute == true, "전제: 복구 직후는 라이딩 중")

        await viewModel.endRiding(isStart: true, locationManager: LocationManager())

        #expect(viewModel.isUsedRoute == true, "라이딩을 끝내도 편집 대상은 그 경로다")
        #expect(viewModel.routeSource == .recentUsed)
    }

    /// 일반 진입은 그대로다 — 홈에서 만든 새 코스는 draft가 맞다
    @Test func normalEntryKeepsDraftSource() {
        let viewModel = makeTestRidingViewModel()

        viewModel.handleInitialEntry(
            locationManager: LocationManager(),
            isNotNormal: nil,
            isStart: false,
            routeSource: .draft,
            onStartRiding: {}
        )

        #expect(viewModel.routeSource == .draft)
        #expect(viewModel.isUsedRoute == false)
    }
}
