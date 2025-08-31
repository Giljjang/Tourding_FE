//
//  SpotAddViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/28/25.
//

import Foundation

@MainActor
final class SpotAddViewModel: ObservableObject {
    @Published var userId: Int = 2
    
    @Published var clickFliter: String = ""
    let tagFilter: [String] = ["전체","자연", "인문(문화/예술/역사)", "레포츠", "쇼핑", "음식", "숙박"]
    
    @Published var routeLocation: [LocationNameModel] = []
    @Published var spots: [SpotData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tourRepository: TourRepositoryProtocol
    private let routeRepository: RouteRepositoryProtocol
    
    init(
        tourRepository: TourRepositoryProtocol,
        routeRepository: RouteRepositoryProtocol) {
            self.tourRepository = tourRepository
            self.routeRepository = routeRepository
    }
    
    //MARK: - View 로직
    func matchImageName(for title: String)-> String {
        switch title {
        case "전체":
            return "icon_menu"
        case "자연":
            return "icon_nature"
        case "인문(문화/예술/역사)":
            return "icon_humanities"
        case "레포츠":
            return "icon_Leports"
        case "쇼핑":
            return "icon_shopping"
        case "음식":
            return "icon_food"
        case "숙박":
            return "icon_Accommodation"
        default:
            return "icon_menu"
        }
    } // : func
    
    //MARK: - API 호출
    func fetchNearbySpots(lat: String, lng: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            spots = try await tourRepository.searchLocationSpots(
                pageNum: 0,
                mapX: lng,
                mapY: lat,
                radius: "20000"
            )
        
        } catch {
            errorMessage = "스팟을 불러오는데 실패했습니다."
            print("API 오류: \(error)")
            
        }
        
        isLoading = false
    }
    
    @MainActor
    func getRouteLocationAPI() async {
        isLoading = true
        do {
            let response = try await routeRepository.getRoutesLocationName(userId: userId)
            routeLocation = response
            
        } catch {
            print("GET ERROR: /routes/location-name \(error)")
        }
        isLoading = false
    }
}
