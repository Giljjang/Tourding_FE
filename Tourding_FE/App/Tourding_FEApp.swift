//
//  Tourding_FEApp.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

@main
struct Tourding_FEApp: App {
    @StateObject private var navigationManager = NavigationManager()
    @State private var showSplash = true
    @State private var isLoggedIn = false  // ✅ 로그인 상태 관리
    
    init() {
        // kakao sdk 초기화
        let kakaoNativeAppKey = (Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String) ?? ""
        KakaoSDK.initSDK(appKey: kakaoNativeAppKey)
        print("🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨\(kakaoNativeAppKey)")
    }
    
    var body: some Scene {
        
        // 레파지토리 및 뷰모델 의존성 주입
        let viewModels = DependencyProvider.makeTabViewModels()
        
        
        WindowGroup {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            loadKakaoToken { success in
                                withAnimation {
                                    isLoggedIn = success
                                    showSplash = false
                                }
                                if !isLoggedIn {
//                                    navigationManager.push(.LoginView)
                                }
                            }
                        }
                    } // : onAppear
                    .onOpenURL { url in
                        if AuthApi.isKakaoTalkLoginUrl(url) {
                            _ = AuthController.handleOpenUrl(url: url)
                        }
                    }
                
            } else {
                if isLoggedIn{
                    NavigationStack(path: $navigationManager.path) {
                        TabContentView(viewModel: viewModels)
                            .navigationDestination(for: ViewType.self) { path in
                                switch path{
                                    // case 추가해서 탭뷰 제외 뷰 넣으면 됨
                                case .LoginView:
                                    LoginView(isLoggedIn: $isLoggedIn)

                                default :
                                    EmptyView()
                                }
                            } // : navigationDestination
                    } // : NavigationStack
                    .environmentObject(navigationManager)
                    .onOpenURL { url in
                        if AuthApi.isKakaoTalkLoginUrl(url) {
                            _ = AuthController.handleOpenUrl(url: url)
                        }
                    }
                } else {
                    NavigationStack(path: $navigationManager.path) {
                        LoginView(isLoggedIn: $isLoggedIn)
                    }
                    .environmentObject(navigationManager)
                    .onOpenURL { url in
                        if AuthApi.isKakaoTalkLoginUrl(url) {
                            _ = AuthController.handleOpenUrl(url: url)
                        }
                    }
                }// : if-else
            }
        }
    }
}
