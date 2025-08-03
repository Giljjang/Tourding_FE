//
//  RidingView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct RidingView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject private var viewModel: RidingViewModel
        
    init(viewModel: RidingViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing:0){
            
            Spacer()
            
            Text("HomeView")
                .foregroundStyle(Color.main)
            
            Spacer()
        } // VStack
    }
}

#Preview {
    RidingView(viewModel: RidingViewModel(testRepository: TestRepository()))
            .environmentObject(NavigationManager())
}
