//
//  RidingViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import Foundation

final class RidingViewModel: ObservableObject {
    @Published var start: String = "한동대학교"
    @Published var end: String = "영남대학교"
    @Published var spotList: [RidingSpotModel]  = []
    
    init() {
        showMockSpotList()
    }
    
    private func showMockSpotList(){
        let mock1 = RidingSpotModel(name: "태화강공원", themeType: .humanities)
        let mock2 = RidingSpotModel(name: "어딘가.. 맛있는 곳", themeType: .food)
        
        spotList.append(contentsOf: [mock1, mock2])
        
    } // : func
}
