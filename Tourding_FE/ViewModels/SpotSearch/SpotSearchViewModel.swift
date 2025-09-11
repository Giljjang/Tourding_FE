//
//  SpotSearchViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class SpotSearchViewModel: ObservableObject {
    @Published var spots: [SpotData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tourRepository: TourRepositoryProtocol
    
    init(tourRepository: TourRepositoryProtocol) {
        self.tourRepository = tourRepository
    }
    
    func fetchNearbySpots(lat: Double, lng: Double) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let results = try await tourRepository.searchLocationSpots(
                pageNum: 0,
                mapX: String(lng),
                mapY: String(lat),
                radius: "20000",
                typeCode: ""
            )
            
            //추천 코스 제외
            spots = results.filter { $0.typeCode != "C01" }
        } catch {
            errorMessage = "스팟을 불러오는데 실패했습니다."
            print("API 오류: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshLocationAndFetchSpots() async {
        isLoading = true
        // DestinationSearchViewModel의 refreshLocation() 호출은 View에서
    }
}
