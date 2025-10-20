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
    @Published var currentPage: Int = 1
    @Published var hasMoreData: Bool = true
    
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
    
    private var lastLat: Double = 0
    private var lastLng: Double = 0
    private var lastSelected: Int = 0
    
    init(tourRepository: TourRepositoryProtocol) {
        self.tourRepository = tourRepository
    }
    
    // 새로운 검색 시작 (페이지 리셋)
    func fetchNearbySpots(lat: Double, lng: Double, selected: Int) async {
        isLoading = true
        errorMessage = nil
        currentPage = 1  // 페이지 리셋
        spots = []  // 기존 데이터 초기화
        hasMoreData = true
        
        lastLat = lat
        lastLng = lng
        lastSelected = selected
        
        let typeCode = Self.typeMap[selected] ?? ""
        
        do {
            let results = try await tourRepository.searchLocationSpots(
                pageNum: 1,
                mapX: String(lastLng),
                mapY: String(lastLat),
                radius: "20000",
                typeCode: typeCode
            )
            
            // 추천 코스 제외
            let filtered = results.filter { $0.typeCode != "C01" }
            spots = filtered
            
            if filtered.isEmpty {
                hasMoreData = false
            } else {
                currentPage = 2  // 다음 페이지 준비
            }
            
            errorMessage = nil
        } catch {
            errorMessage = "스팟을 불러오는데 실패했습니다."
            print("API 오류: \(error)")
            hasMoreData = false
        }
        
        isLoading = false
    }
    
    // 다음 페이지 로드 (기존 데이터에 추가) - SpotAdditionalView용
    func loadMoreSpots() async {
        if isLoading || !hasMoreData { return }
        
        isLoading = true
        let typeCode = Self.typeMap[lastSelected] ?? ""
        
        do {
            let results = try await tourRepository.searchLocationSpots(
                pageNum: currentPage,
                mapX: String(lastLng),
                mapY: String(lastLat),
                radius: "20000",
                typeCode: typeCode
            )
            
            // 추천 코스 제외
            let filtered = results.filter { $0.typeCode != "C01" }
            
            if filtered.isEmpty {
                hasMoreData = false
            } else {
                spots.append(contentsOf: filtered)
                currentPage += 1
            }
            
            errorMessage = nil
        } catch {
            errorMessage = "스팟을 불러오는데 실패했습니다."
            print("API 오류: \(error)")
            hasMoreData = false
        }
        
        isLoading = false
    }
    
    func refreshLocationAndFetchSpots() async {
        // DestinationSearchViewModel의 refreshLocation() 호출은 View에서
    }
}
