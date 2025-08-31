//
//  SpotAddViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/28/25.
//

import Foundation

@MainActor
final class SpotAddViewModel: ObservableObject {
    @Published var clickFliter: String = ""
    let tagFilter: [String] = ["전체","자연", "인문(문화/예술/역사)", "레포츠", "쇼핑", "음식", "숙박"]
    
    @Published var spots: [SpotData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tourRepository: TourRepositoryProtocol
    
    init(tourRepository: TourRepositoryProtocol) {
        self.tourRepository = tourRepository
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
    
    private func categoryIcon(for typeId: String) -> String {
        switch typeId {
        case "12": return "humon"   // 관광지
        case "14": return "humon"   // 문화시설
        case "15": return "humon"   // 축제공연행사
        case "25": return "humon"   // 여행코스
        case "28": return "leport"  // 레포츠
        case "32": return "sleep"   // 숙박
        case "38": return "shoping" // 쇼핑
        case "39": return "food"    // 음식점
        default:   return "관광지"  // 기본값
        }
    }

    
    
    //MARK: - API 호출
    func fetchNearbySpots(lat: Double, lng: Double) async {
        isLoading = true
        errorMessage = nil
        
        do {
            spots = try await tourRepository.searchLocationSpots(
                pageNum: 0,
                mapX: String(lng),
                mapY: String(lat),
                radius: "20000"
            )
        
        } catch {
            errorMessage = "스팟을 불러오는데 실패했습니다."
            print("API 오류: \(error)")
        }
        
        isLoading = false
    }
}
