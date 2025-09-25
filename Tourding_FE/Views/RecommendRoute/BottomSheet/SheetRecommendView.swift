//
//  SheetRecommendView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/20/25.
//

import SwiftUI

struct SheetRecommendView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @ObservedObject private var recommendRouteViewModel: RecommendRouteViewModel
    
    init(recommendRouteViewModel: RecommendRouteViewModel) {
        self.recommendRouteViewModel = recommendRouteViewModel
    }
    
    var body: some View {
        VStack(alignment: .leading,spacing: 0) {
            
        } // :VStack
    }
}
