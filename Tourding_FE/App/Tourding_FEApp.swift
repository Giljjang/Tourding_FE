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
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var modalManager = ModalManager()
    
    @State private var showSplash = true
    
    init() {
        // kakao sdk 초기화
        let kakaoNativeAppKey = (Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String) ?? ""
        KakaoSDK.initSDK(appKey: kakaoNativeAppKey)
        print("🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨\(kakaoNativeAppKey)")
    }
    
    var body: some Scene {
        
        // 레파지토리 및 뷰모델 의존성 주입
        let viewModels = DependencyProvider.makeTabViewModels()
        let ridingViewModel = DependencyProvider.makeRidingViewModel()
        
        WindowGroup {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            loadKakaoToken { success in
                                withAnimation {
                                    loginViewModel.fetchUserInfo()
                                    loginViewModel.isLoggedIn = success
                                    showSplash = false
                                }
                                if !loginViewModel.isLoggedIn {
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
                // ✅ NavigationStack을 한 번만 사용하고 조건문을 내부에서 처리
                NavigationStack(path: $navigationManager.path) {
                    // 🎯 조건문을 NavigationStack 내부로 이동
                    if loginViewModel.isLoggedIn {
                        TabContentView(viewModel: viewModels)
                            .navigationDestination(for: ViewType.self) { path in
                                switch path {
                                    // case 추가해서 탭뷰 제외 뷰 넣으면 됨
                                case .LoginView:
                                    LoginView()
                                case .MyPageView:
                                    MyPageView()
                                case .ServiceView:
                                    ServiceView()
                                case .RidingView:
                                    RidingView(ridingViewModel: ridingViewModel)
                                default:
                                    EmptyView()
                                }
                            } // : navigationDestination
                    } else {
                        LoginView()
                    }
                }   // : NavigationStack
                .environmentObject(navigationManager)
                .environmentObject(modalManager)
                .environmentObject(loginViewModel)
                .environmentObject(viewModels.myPageViewModel)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
            }
        }
    }
}
