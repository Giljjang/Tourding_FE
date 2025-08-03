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
            case .RidingView:
                RidingView(viewModel: viewModel.ridingViewModel)
            case .SpotSearchView:
                SpotSearchView()
            case .MyPageView :
                MyPageView()
            default:
                RidingView(viewModel: viewModel.ridingViewModel)
            }
            
            CustomTabView(currentView: navigationManager.currentTab)
                .padding(.bottom, 52)
        } // : Zstack
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    let repository = TestRepository()
    
    let ridingViewModel = RidingViewModel(testRepository: repository)
    let myPageViewModel = MyPageViewModel()
    let spotSearchViewModel = SpotSearchViewModel()

    let viewModels = TabViewModelsContainer(
        ridingViewModel: ridingViewModel,
        myPageViewModel: myPageViewModel,
        spotSearchViewModel: spotSearchViewModel
    )
    
    TabContentView(viewModel: viewModels)
        .environmentObject(NavigationManager())
}
