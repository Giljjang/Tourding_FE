//
//  SessionScopedState.swift
//  Tourding_FE
//
//  로그인한 사용자에게 종속된 화면 상태.
//
//  로그아웃·회원탈퇴 시 Keychain만 지우면 ViewModel의 @Published 값은 그대로 남는다.
//  ViewModel은 앱 수명(AppContainer)이므로 화면을 다시 열어도 직전 계정 데이터가 보인다.
//

import Foundation

protocol SessionScopedState: AnyObject {
    /// 세션이 끝났을 때 비워야 하는 상태만 지운다.
    /// 로그인과 무관한 공개 데이터(추천 코스 등)는 유지한다.
    func clearSessionState()
}

extension HomeViewModel: SessionScopedState {
    func clearSessionState() {
        userId = nil
        routeLocation = []
        // routeRecommendList는 로그인 없이도 조회되는 공개 데이터라 유지한다
    }
}

extension RecentSearchViewModel: SessionScopedState {
    func clearSessionState() {
        clear()
    }
}
