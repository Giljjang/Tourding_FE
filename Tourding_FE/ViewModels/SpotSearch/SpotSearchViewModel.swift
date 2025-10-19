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
    
    private static let typeMap: [Int: String] = [
        0: "",
        1: "A01",
        2: "A02",
        3: "A03",
        4: "A04",
        5: "A05",
        6: "B02"
    ]
    
    init(tourRepository: TourRepositoryProtocol) {
        self.tourRepository = tourRepository
    }
    
    func fetchNearbySpots(lat: Double, lng: Double, selected: Int) async {
        isLoading = true
        errorMessage = nil
        
        let typeCode = Self.typeMap[selected] ?? ""

        do {
            let results = try await tourRepository.searchLocationSpots(
                pageNum: 0,
                mapX: String(lng),
                mapY: String(lat),
                radius: "20000",
                typeCode: typeCode
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
