//
//  LoginView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/25/25.
//

import SwiftUI

import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

struct LoginView: View {
    var body: some View {
                
        Button("카카오톡 로그인") {
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                    if let error = error {
                        print("❌ 로그인 실패: \(error)")
                    } else if let token = oauthToken {
                        print("✅ 로그인 성공!")
                        print("accessToken: \(token.accessToken)")
                        saveKakaoToken(token: token)  // ✅ Keychain에 저장
                        // 👉 여기서 로그인 상태로 상태 변경 등 UI 처리 가능
                    }
                }
            } else {
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error = error {
                        print("❌ 로그인 실패: \(error)")
                    } else if let token = oauthToken {
                        print("✅ 로그인 성공!")
                        print("accessToken: \(token.accessToken)")
                    }
                }
            }
        }

        
        
        
    }
}

#Preview {
    LoginView()
}
