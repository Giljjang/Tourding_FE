//
//  NavigationManager.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

enum ViewType : Hashable {
    case SplashView
    case HomeView
    case TourRecommendationView
    case MyPageView
    
    case LoginView
}

final class NavigationManager: ObservableObject {
    @Published var path: [ViewType] = [] // 탭바 X -> stack
    @Published var currentTab: ViewType = .HomeView // 탭바 O 상태관리
    
    func push(_ view: ViewType) {
        path.append(view)
    }
    
    func pop(){
        path.removeLast()
    }
    
    func popToRoot(){
        path.removeAll()
    }
}
