//
//  ContentView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct TabContentView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    private var viewModel: TabViewModelsContainer
    
    @ObservedObject private var spotVM: SpotSearchViewModel // SpotSearchViewModel의 변화를 관찰하기 위해서 따로 추가
    
    init(viewModel: TabViewModelsContainer) {
        self.viewModel = viewModel
        self.spotVM = viewModel.spotSearchViewModel
    }
    
    var body: some View {
        ZStack {
            
            switch navigationManager.currentTab {
            case .HomewView:
                HomeView(viewModel: viewModel.homeViewModel)
            case .SpotSearchView:
                SpotSearchView(
                    spotviewModel: spotVM,
                    dsviewModel: viewModel.dsViewModel
                )
            case .MyPageView :
                MyPageView(viewModel: viewModel.myPageViewModel, recentSearchViewModel: viewModel.recentSearchViewModel)
            default:
                HomeView(viewModel: viewModel.homeViewModel)
            }
            
            CustomTabView(currentView: navigationManager.currentTab)
                .padding(.bottom, 52)
                .allowsHitTesting(!viewModel.spotSearchViewModel.isLoading)
                .disabled(viewModel.spotSearchViewModel.isLoading)
            
            // 커스텀 모달 뷰
            if modalManager.isPresented && modalManager.showView == .tabView {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        modalManager.hideModal()
                    }
                
                CustomModalView(modalManager: modalManager)
            } // : if
            // 스팟 검색 로딩 오버레이 (전체 화면)
            if viewModel.spotSearchViewModel.isLoading {
                Color.white.opacity(0.5).ignoresSafeArea()
                DotsLoadingView()
            }
        } // : Zstack
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    let repository = RouteRepository()
    let TourRepository = TourRepository()
    
    let homeViewModel = HomeViewModel(routeRepository: repository)
    let myPageViewModel = MyPageViewModel()
    let spotSearchViewModel = SpotSearchViewModel(tourRepository: TourRepository)
    let dsViewModel = DestinationSearchViewModel()
    let RecentSearchViewModel = RecentSearchViewModel()
    
    let viewModels = TabViewModelsContainer(
        homeViewModel: homeViewModel,
        myPageViewModel: myPageViewModel,
        spotSearchViewModel: spotSearchViewModel,
        dsViewModel: dsViewModel,
        recentSearchViewModel: RecentSearchViewModel
    )
    
    TabContentView(viewModel: viewModels)
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
        .environmentObject(RouteSharedManager())
}
