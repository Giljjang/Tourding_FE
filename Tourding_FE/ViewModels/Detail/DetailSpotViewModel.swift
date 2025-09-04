//
//  DetailSpotViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import Foundation

final class DetailSpotViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    
    private let tourRepository: TourRepositoryProtocol
    private let routeRepository: RouteRepositoryProtocol
    
    init(
        tourRepository: TourRepositoryProtocol,
        routeRepository: RouteRepositoryProtocol) {
            self.tourRepository = tourRepository
            self.routeRepository = routeRepository
    }
    
    //MARK: - API 호출
    @MainActor
    func getTourAreaDetailAPI(requestBody: ReqDetailModel) async {
        isLoading = true
        do {
            
            print("ReqDetailModel: \(requestBody)")
            let response = try await tourRepository.getTourAreaDetail(requestBody: requestBody)
            
            print("Detail: \(response)")
            
        } catch {
            print("GET ERROR: /tour/area-detail \(error)")
        }
        isLoading = false
    }
}
