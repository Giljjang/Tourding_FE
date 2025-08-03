//
//  ContentView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct TabContentView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var modalManager = ModalManager()
    private var viewModel: TabViewModelsContainer
    
    init(viewModel: TabViewModelsContainer) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            
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
            
            // 커스텀 모달 뷰
            if modalManager.isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        modalManager.hideModal()
                    }
                
                CustomModalView(modalManager: modalManager)
            } // : if
            
        } // : Zstack
        .edgesIgnoringSafeArea(.bottom)
        .environmentObject(modalManager)
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
        .environmentObject(ModalManager())
}
