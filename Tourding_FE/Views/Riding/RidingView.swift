//
//  RidingView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import SwiftUI

struct RidingView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject private var viewModel: RidingViewModel
    
    init(viewModel: RidingViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("test")
        } // : VStack
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    RidingView(viewModel: RidingViewModel())
        .environmentObject(NavigationManager())
}
