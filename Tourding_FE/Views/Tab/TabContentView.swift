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
    
    init(viewModel: TabViewModelsContainer) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            
            switch navigationManager.currentTab {
            case .HomewView:
                HomeView(viewModel: viewModel.homeViewModel)
            case .SpotSearchView:
                SpotSearchView()
            case .MyPageView :
                MyPageView()
            default:
                HomeView(viewModel: viewModel.homeViewModel)
            }
            
            CustomTabView(currentView: navigationManager.currentTab)
                .padding(.bottom, 52)
            
            // 커스텀 모달 뷰
            if modalManager.isPresented && modalManager.showView == .tabView {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        modalManager.hideModal()
                    }
                
                CustomModalView(modalManager: modalManager)
            } // : if
            
        } // : Zstack
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    let repository = TestRepository()
    
    let homeViewModel = HomeViewModel(testRepository: repository)
    let myPageViewModel = MyPageViewModel()
    let spotSearchViewModel = SpotSearchViewModel()
    
    let viewModels = TabViewModelsContainer(
        homeViewModel: homeViewModel,
        myPageViewModel: myPageViewModel,
        spotSearchViewModel: spotSearchViewModel
    )
    
    TabContentView(viewModel: viewModels)
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
