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
        0: TourTypeCode.all,
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

    private var nearbySearchSerialTask: Task<Void, Never>?
    private var nearbySearchGeneration = 0
    
    init(tourRepository: TourRepositoryProtocol) {
        self.tourRepository = tourRepository
    }
    
    // 새로운 검색 시작 (페이지 리셋)
    func fetchNearbySpots(lat: Double, lng: Double, selected: Int) async {
        lastLat = lat
        lastLng = lng
        lastSelected = selected

        nearbySearchGeneration += 1
        let generation = nearbySearchGeneration
        let previous = nearbySearchSerialTask

        nearbySearchSerialTask = Task { @MainActor in
            await previous?.value
            guard generation == nearbySearchGeneration else { return }

            isLoading = true
            errorMessage = nil
            currentPage = 1
            spots = []
            hasMoreData = true

            let typeCode = Self.typeMap[selected] ?? TourTypeCode.all
            print("🛣️ [SpotSearch] search-location selected=\(selected) typeCode=\(typeCode) pageNum=1 lat=\(lat) lon=\(lng) gen=\(generation)")

            do {
                let results = try await tourRepository.searchLocationSpots(
                    pageNum: 1,
                    mapX: String(lastLng),
                    mapY: String(lastLat),
                    radius: "20000",
                    typeCode: typeCode
                )

                guard generation == nearbySearchGeneration else { return }

                let filtered = results.filter { $0.typeCode != "C01" }
                spots = filtered

                if filtered.isEmpty {
                    hasMoreData = false
                } else {
                    currentPage = 2
                }

                errorMessage = nil
            } catch {
                guard generation == nearbySearchGeneration else { return }
                errorMessage = "스팟을 불러오는데 실패했습니다."
                print("API 오류: \(error)")
                hasMoreData = false
            }

            isLoading = false
        }

        await nearbySearchSerialTask?.value
    }
    
    // 다음 페이지 로드 (기존 데이터에 추가) - SpotAdditionalView용
    func loadMoreSpots() async {
        if isLoading || !hasMoreData { return }
        
        isLoading = true
        let typeCode = Self.typeMap[lastSelected] ?? TourTypeCode.all

        print("🛣️ [SpotSearch] search-location selected=\(lastSelected) typeCode=\(typeCode) pageNum=\(currentPage) lat=\(lastLat) lon=\(lastLng)")

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
