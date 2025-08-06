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
    @StateObject private var loginViewModel = LoginViewModel()  // ✅ ViewModel 생성
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
                    if loginViewModel.isLoggedIn{
                        NavigationStack(path: $navigationManager.path) {
                            TabContentView(viewModel: viewModels)
                                .navigationDestination(for: ViewType.self) { path in
                                    switch path{
                                    
                                    case .RidingView:
                                        RidingView(ridingViewModel: ridingViewModel)
                                    case .LoginView:
                                        LoginView()
                                        
                                    default :
                                        EmptyView()
                                    }
                                } // : navigationDestination
                        } // : NavigationStack
                        .environmentObject(navigationManager)
                        .environmentObject(loginViewModel)  //  여기서 주입
                        .onOpenURL { url in
                            if AuthApi.isKakaoTalkLoginUrl(url) {
                                _ = AuthController.handleOpenUrl(url: url)
                            }
                        }
                    } else {
                        NavigationStack(path: $navigationManager.path) {
                            LoginView()
                        }
                        .environmentObject(navigationManager)
                        .environmentObject(loginViewModel)  //  여기서 주입
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
