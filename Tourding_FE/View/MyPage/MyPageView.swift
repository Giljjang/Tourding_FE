//
//  MyPageView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI
import KakaoSDKUser

struct MyPageView: View {
    var body: some View {
        VStack(spacing:0){
            
            Spacer()
            
            Text("MyPageView")
            
            
            Button(action: {
                UserApi.shared.logout { error in
                    if let error = error {
                        print("❌ 로그아웃 실패: \(error)")
                    } else {
                        print("✅ 로그아웃 성공")
                        clearKakaoTokens()  // Keychain에서 토큰 삭제
                        // 로그아웃 후 화면 전환, 상태 초기화 등 추가 작업
                    }
                }
            }) {
                Text("로그아웃")
            }
            
            Button(action: {
                UserApi.shared.unlink { error in
                    if let error = error {
                        print("❌ 회원탈퇴 실패: \(error)")
                    } else {
                        print("✅ 회원탈퇴 성공")
                        clearKakaoTokens()  // Keychain에서 토큰 삭제
                        // 로그아웃 후 화면 전환, 상태 초기화 등 추가 작업
                    }
                }
            }) {
                Text("회원탍쾨")
            }
                
            
            Spacer()
        } // VStack
        .frame(width:.infinity)
    }
}

#Preview {
    MyPageView()
}
