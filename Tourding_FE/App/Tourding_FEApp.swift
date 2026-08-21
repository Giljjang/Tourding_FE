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
    // 의존성 그래프는 앱 수명당 1회만 구성한다 (body에서 만들면 렌더마다 재생성됨)
    @StateObject private var container = AppContainer()

    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var modalManager = ModalManager()
    @StateObject private var routeManager = RouteSharedManager()
 
    @State private var showSplash = true
    
    init() {
        // kakao sdk 초기화
        let kakaoNativeAppKey = (Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String) ?? ""
        KakaoSDK.initSDK(appKey: kakaoNativeAppKey)
        print("🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨\(kakaoNativeAppKey)")
        print("🔎 BASE_URL at runtime =>", BASE_URL)
        #if DEBUG
        if MockAPIConfiguration.useMockAPI {
            print("🧪 Mock API mode enabled (-UseMockAPI or UserDefaults)")
        }
        #endif
    }
    
    var body: some Scene {

        // 화면 간 공유가 필요한 의존성 — AppContainer가 앱 수명당 1회만 생성한다
        let viewModels = container.tabViewModels
        let filterViewModel = container.filterBarViewModel
        let RecentSearchViewModel = container.recentSearchViewModel

        // push마다 새 인스턴스를 받는 화면들 (@StateObject(wrappedValue:))
        let ridingViewModel = DependencyProvider.makeRidingViewModel()
        let spotAddViewModel = DependencyProvider.makeSpotAddViewModel()
        let detailViewModel = DependencyProvider.makeDetailViewModel()
        let recommendRouteViewModel = DependencyProvider.makeRecommendViewModel()

        WindowGroup {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
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
                        if !loginViewModel.hasCompletedOnboarding {
                            // 최초 회원가입 후 첫 진입에서만 노출, 완료 시 다시 뜨지 않음
                            OnboardingSurveyView(onComplete: {
                                loginViewModel.completeOnboarding()
                            })
                        } else {
                            TabContentView(viewModel: viewModels)
                                .navigationDestination(for: ViewType.self) { path in
                                switch path {
                                    // case 추가해서 탭뷰 제외 뷰 넣으면 됨
                                case .LoginView:
                                    LoginView()
                                case .OnboardingSurveyView:
                                    OnboardingSurveyView(onComplete: {
                                        navigationManager.pop()
                                    })
                                case .RidingStyleSettingsView(let isTemporary):
                                    RidingStyleSettingsView(isTemporary: isTemporary)
                                case .ServiceView:
                                    ServiceView()
                                case .RidingView(let isNotNormal, let isStart, let routeSource):
                                    RidingView(ridingViewModel: ridingViewModel, isNotNormal: isNotNormal,
                                        isStart: isStart,
                                        routeSource: routeSource
                                    )
                                case .SpotAddView(let lat, let lon, _):
                                    SpotAddView(
                                        spotAddViewModel: spotAddViewModel,
                                        lat: lat,
                                        lon: lon)
                                case .DestinationSearchView(let isFromHome, let isAddSpot):
                                    DestinationSearchView(
                                        isFromHome: isFromHome,
                                        filterViewModel: filterViewModel,
                                        RecentSearchViewModel: RecentSearchViewModel,
                                        isAddSpot: isAddSpot)
                                case .DetailSpotView(let isSpotAdd, let detailId):
                                    DetailSpotView(
                                        detailViewModel: detailViewModel,
                                        isSpotAdd: isSpotAdd,
                                        detailId: detailId
                                    )
                                case .RecommendRouteView(let routeName, let description):
                                    RecommendRouteView(
                                        recommendRouteViewModel: recommendRouteViewModel,
                                        routeName: routeName,
                                        description: description)
                                case .SpotAdditionalView:
                                    SpotAdditionalView(spotviewModel: viewModels.spotSearchViewModel, dsviewModel: viewModels.dsViewModel)
                                default:
                                    EmptyView()
                                }
                            } // : navigationDestination
                        } // : hasCompletedOnboarding else
                    } else {
                        LoginView()
                    }
                }   // : NavigationStack
                .environmentObject(navigationManager)
                .environmentObject(modalManager)
                .environmentObject(loginViewModel)
                .environmentObject(routeManager)
                .environmentObject(container)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
            }
        }
    }
}
