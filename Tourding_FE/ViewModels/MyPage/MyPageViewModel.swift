//
//  MyPageViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation
import KakaoSDKUser
import SwiftUI

class MyPageViewModel: ObservableObject {
    @Published var logoutCompleted: Bool = false  // 로그아웃 완료 상태
    
    func logout(globalLoginViewModel: LoginViewModel) {
        UserApi.shared.logout { error in
            if let error = error {
                print("❌ 로그아웃 실패: \(error)")
            } else {
                print("✅ 로그아웃 성공")
                clearKakaoTokens()
                DispatchQueue.main.async {
                    globalLoginViewModel.isLoggedIn = false  // 로그인 상태 초기화 (로그아웃)
                    self.logoutCompleted = true
                }
            }
        }
    }

    func withdraw(globalLoginViewModel: LoginViewModel) {
        UserApi.shared.unlink { error in
            if let error = error {
                print("❌ 회원탈퇴 실패: \(error)")
            } else {
                print("✅ 회원탈퇴 성공")
                clearKakaoTokens()
                DispatchQueue.main.async {
                    globalLoginViewModel.isLoggedIn = false  // 로그인 상태 초기화 (탈퇴)
                    self.logoutCompleted = true
                }
            }
        }
    }
}
