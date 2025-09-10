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
    @EnvironmentObject var viewModel: LoginViewModel
    @State private var currentPage = 0
    
    
    var body: some View {
        ZStack{
            VStack(spacing: 0){
                TabView(selection: $currentPage) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(index: index, page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))  // 기본 인디케이터 숨기기
                .overlay(            // 커스텀 인디케이터 Overlay
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(currentPage == index ? Color.gray5 : Color.gray2)
                                .frame(width: currentPage == index ? 12 : 8, height: currentPage == index ? 12 : 8)  // 크기 차이 줌
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                        .edgesIgnoringSafeArea(.all)
                        .padding(.bottom, 66),
                    alignment: .bottom
                )
                
                Button(action: {
                    viewModel.loginWithKakao()
                }) {
                    HStack {
                        Image("kakao")  // 카카오 로고 이미지를 프로젝트에 추가했을 때!
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        Text("카카오로 로그인")
                            .font(.pretendardMedium(size: 16))
                            .foregroundColor(.black)
                    }
                    .ignoresSafeArea()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellowkakao)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)  // 양쪽 여백
                    .padding(.bottom, 14)
                }
                //애플 로그인 구현하기...
                Button(action: {
                    viewModel.loginWithApple()
                }) {
                    HStack() {
                        Image("apple")  // 카카오 로고 이미지를 프로젝트에 추가했을 때!
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        Text("Apple로 로그인")
                            .font(.pretendardMedium(size: 16))
                            .foregroundColor(.white)
                    }
                    .ignoresSafeArea()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)  // 양쪽 여백
                    .padding(.bottom/*, 106*/)
                }
            }
        } //Zstack
//        .ignoresSafeArea(edges: .bottom)  // SafeArea 무시하고 아래에 붙임
    }
}

#Preview {
    LoginView()
        .environmentObject(LoginViewModel())  // ✅ ViewModel을 주입
}
