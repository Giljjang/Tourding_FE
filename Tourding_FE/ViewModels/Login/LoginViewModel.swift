//
//  LoginViewModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/4/25.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth

class LoginViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userNickname: String? = nil
    @Published var userEmail: String? = nil

    func loginWithKakao() {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                self.handleLoginResult(oauthToken: oauthToken, error: error)
            }
        } else {
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                self.handleLoginResult(oauthToken: oauthToken, error: error)
            }
        }
    }

    private func handleLoginResult(oauthToken: OAuthToken?, error: Error?) {
        if let error = error {
            print("❌ 로그인 실패: \(error)")
        } else if let token = oauthToken {
            print("✅ 로그인 성공!")
            print("accessToken: \(token.accessToken)")
            saveKakaoToken(token: token)
            self.isLoggedIn = true
            self.fetchUserInfo()
        }
    }

    func fetchUserInfo() {
        UserApi.shared.me { user, error in
            if let error = error {
                print("❌ 사용자 정보 요청 실패: \(error)")
            } else if let user = user {
                self.userNickname = user.kakaoAccount?.profile?.nickname
                self.userEmail = user.kakaoAccount?.email
                print("✅ 사용자 정보 요청 성공")
                print("닉네임: \(String(describing: self.userNickname))")
                print("이메일: \(String(describing: self.userEmail))")
            }
        }
    }
}
