//
//  MyPageViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation
import SwiftUI

/// 세션 관련 동작(로그아웃·회원탈퇴)은 `LoginViewModel`이 전담한다.
///
/// 이전에는 여기에 두 번째 구현(`logout` / `AppleLogout` / `withdraw`)이 있었고,
/// `AppleLogout`이 플래그만 내리고 Keychain을 남겨 앱 재실행 시 자동 재로그인이 됐다.
/// 세션 정리 지점이 둘로 갈리면 한쪽이 빠져도 드러나지 않으므로 다시 추가하지 말 것.
final class MyPageViewModel: ObservableObject {
    @Published var logoutCompleted: Bool = false  // 로그아웃 완료 상태
}
