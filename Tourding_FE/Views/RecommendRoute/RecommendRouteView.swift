//
//  RecommendRouteView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/19/25.
//

import SwiftUI

struct RecommendRouteView: View {
    
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @StateObject private var recommendRouteViewModel: RecommendRouteViewModel
    
    init(recommendRouteViewModel: RecommendRouteViewModel
    ) {
        self._recommendRouteViewModel = StateObject(wrappedValue: recommendRouteViewModel)
    }
    
    var body: some View {
        Text("Hello, World!")
    }
}
