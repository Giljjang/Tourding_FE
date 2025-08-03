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
        VStack(alignment: .leading,spacing:0){
            
            HStack(alignment: .top) {
                Image("logo")
                    .padding(.top, 26)
                
                Spacer()
            } // : HStack
            
            Spacer()
        } // : VStack
        .padding(.horizontal, 16)
        .background(Color.gray1)
    }
}

#Preview {
    RidingView(viewModel: RidingViewModel(testRepository: TestRepository()))
            .environmentObject(NavigationManager())
}
