//
//  Tourding_FEApp.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

@main
struct Tourding_FEApp: App {
    @StateObject private var navigationManager = NavigationManager()
    @State private var showSplash = true
    
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
                            
                            // 로그인X인 경우 처리
                            navigationManager.push(.LoginView)
                        }
                    } // : onAppear
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
            } // : if-else
        }
    }
}
