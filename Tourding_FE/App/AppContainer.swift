//
//  AppContainer.swift
//  Tourding_FE
//
//  화면 간에 공유되어야 하는 의존성을 앱 수명당 1회만 구성한다.
//
//  이전에는 Tourding_FEApp.body에서 DependencyProvider 팩토리를 직접 호출했다.
//  body는 @Published 변경(네비게이션 push, 토스트 on/off 등)마다 재평가되므로
//  그때마다 ViewModel이 새로 만들어졌고, @ObservedObject로 주입받는 화면은
//  빈 인스턴스를 받아 검색 결과·필터 상태를 잃었다.
//  (DestinationSearchViewModel은 init에서 GPS를 시작하므로 위치 갱신도 매번 재시작됐다.)
//
//  ⚠️ 담는 기준: **@ObservedObject로 주입되어 화면 간 상태를 공유해야 하는 것만** 넣는다.
//  @StateObject(wrappedValue:)로 받는 화면(DetailSpotView / SpotAddView / RecommendRouteView /
//  RidingView)은 push마다 새 인스턴스를 받는 것이 기존 동작이므로 여기 넣지 않는다.
//  넣으면 이전 스팟의 상세 데이터가 남거나 라이딩 flag가 유지되는 등 동작이 바뀐다.
//
//  향후 AI 서비스처럼 화면 간 공유가 필요한 의존성은 이 컨테이너에 등록한다.
//

import Foundation

@MainActor
final class AppContainer: ObservableObject {

    /// 탭 화면들이 공유 (SpotSearchView·DestinationSearchView가 @ObservedObject로 사용)
    let tabViewModels: TabViewModelsContainer

    /// DestinationSearchView가 @ObservedObject로 사용
    let filterBarViewModel: FilterBarViewModel

    /// DestinationSearchView가 @ObservedObject로 사용
    let recentSearchViewModel: RecentSearchViewModel

    init() {
        tabViewModels = DependencyProvider.makeTabViewModels()
        filterBarViewModel = DependencyProvider.makeFilterBarViewModel()
        recentSearchViewModel = DependencyProvider.makeRecentSearchViewModel()
    }
}
