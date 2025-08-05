//
//  MyPageView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct MyPageView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel  // ✅ 글로벌 로그인 상태 ViewModel
    @EnvironmentObject var myPageViewModel: MyPageViewModel  // ✅ 마이페이지 ViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("내 정보")

            Button(action: {
                myPageViewModel.logout(globalLoginViewModel: loginViewModel)
            }) {
                Text("로그아웃")
            }

            Button(action: {
                myPageViewModel.withdraw(globalLoginViewModel: loginViewModel)
            }) {
                Text("회원탈퇴")
            }

            Spacer()
        }
    }
}

#Preview {
    MyPageView()
        .environmentObject(LoginViewModel())
        .environmentObject(MyPageViewModel())
}
