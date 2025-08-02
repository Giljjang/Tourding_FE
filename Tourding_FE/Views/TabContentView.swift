//
//  ContentView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct TabContentView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    private var viewModel: TabViewModelsContainer
    
    init(viewModel: TabViewModelsContainer) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack(alignment: .bottom){
            
            switch navigationManager.currentTab {
            case .HomeView:
                HomeView(viewModel: viewModel.homeViewModel)
            case .MyPageView :
                MyPageView()
            case .TourRecommendationView:
                TourRecommendationView()
            default:
                HomeView(viewModel: viewModel.homeViewModel)
            }
            
            CustomTabView(currentView: navigationManager.currentTab)
        } // : Zstack
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    let repository = TestRepository()
    
    let homeViewModel = HomeViewModel(testRepository: repository)
    let myPageViewModel = MyPageViewModel()
    let tourRecommendationViewModel = TourRecommendationViewModel()

    let viewModels = TabViewModelsContainer(
        homeViewModel: homeViewModel,
        myPageViewModel: myPageViewModel,
        tourRecommendationViewModel: tourRecommendationViewModel
    )
    
    TabContentView(viewModel: viewModels)
        .environmentObject(NavigationManager())
}
