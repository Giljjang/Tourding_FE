//
//  DependencyProvider.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/25/25.
//

import Foundation

struct DependencyProvider {
    static func makeTabViewModels() -> TabViewModelsContainer {
        let repository = TestRepository()
        let ridingViewModel = RidingViewModel(testRepository: repository)
        let myPageViewModel = MyPageViewModel()
        let spotSearchViewModel = SpotSearchViewModel()
        
        return TabViewModelsContainer(
            ridingViewModel: ridingViewModel,
            myPageViewModel: myPageViewModel,
            spotSearchViewModel: spotSearchViewModel
        )
    }
}
