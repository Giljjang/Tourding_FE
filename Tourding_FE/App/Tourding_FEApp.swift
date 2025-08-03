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
    
    init() {
            // kakao sdk 초기화
            let kakaoNativeAppKey = (Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String) ?? ""
            KakaoSDK.initSDK(appKey: kakaoNativeAppKey)
            print("🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨\(kakaoNativeAppKey)")
            
            loadKakaoToken { isLoggedIn in
                if isLoggedIn {
                    print("✅ 자동 로그인 성공!")
                    // → 로그인 성공시 UI 전환 등 처리
                } else {
                    print("❌ 자동 로그인 실패. 로그인 화면으로 이동")
                    // → 로그인 화면으로 이동
                }
            }
        }
    
    var body: some Scene {

        // 레파지토리 및 뷰모델 의존성 주입
        let viewModels = DependencyProvider.makeTabViewModels()
        
        
        WindowGroup {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSplash = false
                            }
                            //TODo: 로그인 분기처리 필요
                            // 로그인X인 경우 처리
                            navigationManager.push(.LoginView)
                        }
                    } // : onAppear
                    .onOpenURL { url in
                        if AuthApi.isKakaoTalkLoginUrl(url) {
                            _ = AuthController.handleOpenUrl(url: url)
                        }
                    }
                
            } else {
                NavigationStack(path: $navigationManager.path) {
                    TabContentView(viewModel: viewModels)
                        .navigationDestination(for: ViewType.self) { path in
                            switch path{
                            // case 추가해서 탭뷰 제외 뷰 넣으면 됨
                            case .LoginView:
                                LoginView()
                                
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
            } // : if-else
        }
    }
}
