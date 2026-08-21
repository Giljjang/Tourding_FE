//
//  NavigationManager.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

enum RidingRouteSource: Hashable {
    case draft
    case recentUsed

    var isUsed: Bool {
        switch self {
        case .draft:
            return false
        case .recentUsed:
            return true
        }
    }
}

enum ViewType : Hashable {
    case SplashView
    case HomeView
    case SpotSearchView
    case MyPageView
    
    case LoginView
    case OnboardingSurveyView
    /// `isTemporary`: 코스 편집에서 열면 true — 서버에 저장하지 않고 이번 경로에만 적용한다
    case RidingStyleSettingsView(isTemporary: Bool = false)
    case RidingView(isNotNormal: Bool? = nil, // 비정상 종료일 때 true
                    isStart: Bool = false, // 바로 라이딩 시작하면 true
                    routeSource: RidingRouteSource = .draft)
    case SpotAddView(lat: String, lon: String, sessionId: UUID)
    case ServiceView
    case DestinationSearchView(isFromHome: Bool, isAddSpot: Bool)
    case DetailSpotView(isSpotAdd: Bool, detailId: ReqDetailModel)
    case RecommendRouteView(routeName: String, description: String)
    case SpotAdditionalView
}

extension ViewType {
    /// 코스 편집 화면인가. 진입 방식마다 연관값이 달라 케이스만 본다.
    var isRidingEditor: Bool {
        if case .RidingView = self { return true }
        return false
    }
}

final class NavigationManager: ObservableObject {
    @Published var path: [ViewType] = [] // 탭바 X -> stack
    @Published var currentTab: ViewType = .HomeView // 탭바 O 상태관리

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

extension NavigationManager {
    /// 코스 편집 화면이 아직 스택에 있는가.
    ///
    /// `onDisappear`는 **자식 화면으로 push할 때도 불린다** —
    /// 스팟 추가나 라이딩 스타일 화면으로 들어갈 때마다 편집 세션이 끝나면
    /// "편집 중에는 일시 스타일 유지"가 성립하지 않는다. 이걸로 두 경우를 가른다.
    var holdsRidingEditor: Bool {
        path.contains { $0.isRidingEditor }
    }
}
