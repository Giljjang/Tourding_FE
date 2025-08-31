//
//  NavigationManager.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

enum ViewType : Hashable {
    case SplashView
    case HomewView
    case SpotSearchView
    case MyPageView
    
    case LoginView
    case RidingView
    case SpotAddView(lat: Double, lon: Double)
    case ServiceView
    case DestinationSearchView
}

final class NavigationManager: ObservableObject {
    @Published var path: [ViewType] = [] // 탭바 X -> stack
    @Published var currentTab: ViewType = .HomewView // 탭바 O 상태관리
    
    func push(_ view: ViewType) {
        path.append(view)
    }
    
    func pop() {
        guard !path.isEmpty else {
            print("⚠️ Cannot pop: Navigation path is empty")
            return
        }
        path.removeLast()
    }
    
    func popToRoot(){
        path.removeAll()
    }
}
