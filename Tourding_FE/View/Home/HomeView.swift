//
//  HomeView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject private var viewModel: HomeViewModel
        
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing:0){
            
            Spacer()
            
            Text("HomeView")
//            NaverMapView()
//                .frame(width: 400, height: 400)
            
            Spacer()
        } // VStack
        .frame(width:.infinity)
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(testRepository: TestRepository()))
            .environmentObject(NavigationManager())
}
