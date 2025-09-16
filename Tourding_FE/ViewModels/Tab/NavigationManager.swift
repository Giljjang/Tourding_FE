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
    case RidingView(flag: Bool? = nil) //비정상 종료일 때 true
    case SpotAddView(lat: String, lon: String)
    case ServiceView
    case DestinationSearchView(isFromHome: Bool, isAddSpot: Bool)
    case DetailSpotView(isSpotAdd: Bool, detailId: ReqDetailModel)
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

extension NavigationManager {
    // 지정한 개수만큼 pop. 기본값은 1
    func pop(count: Int = 1) {
        guard !path.isEmpty else {
            print("⚠️ Cannot pop: Navigation path is empty")
            return
        }
        
        let removeCount = min(count, path.count)
        path.removeLast(removeCount)
    }
    
    // 특정 뷰까지 pop (해당 뷰는 제거하지 않음)
    func popToView(_ targetView: ViewType) {
        guard !path.isEmpty else {
            print("⚠️ Cannot pop: Navigation path is empty")
            return
        }
        
        // 뒤에서부터 찾아서 targetView가 나올 때까지 제거
        while !path.isEmpty {
            let lastView = path.last!
            if lastView == targetView {
                break // targetView를 찾았으면 중단
            }
            path.removeLast()
        }
        
        print("🔵 popToView 완료. 현재 path: \(path)")
    }
    
    // 특정 뷰까지 pop (해당 뷰도 제거)
    func popIncludingView(_ targetView: ViewType) {
        guard !path.isEmpty else {
            print("⚠️ Cannot pop: Navigation path is empty")
            return
        }
        
        // 뒤에서부터 찾아서 targetView까지 제거
        while !path.isEmpty {
            let lastView = path.removeLast()
            if lastView == targetView {
                break // targetView를 찾아서 제거했으면 중단
            }
        }
        
        print("🔵 popIncludingView 완료. 현재 path: \(path)")
    }
    
    // 현재 네비게이션 스택 상태 출력 (디버깅용)
    func printCurrentPath() {
        print("🔵 현재 네비게이션 스택:")
        for (index, view) in path.enumerated() {
            print("  \(index): \(view)")
        }
    }
}

