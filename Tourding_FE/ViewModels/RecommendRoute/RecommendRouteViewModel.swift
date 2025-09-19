//
//  RecommendRouteViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/19/25.
//

import Foundation

final class RecommendRouteViewModel: ObservableObject {
    
    private let tourRepository: TourRepositoryProtocol
    
    init(
        tourRepository: TourRepositoryProtocol) {
            self.tourRepository = tourRepository
    }
    
}
