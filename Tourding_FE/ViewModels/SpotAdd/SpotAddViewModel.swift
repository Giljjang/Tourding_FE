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
    
    func matchTypeCodeName(for title: String) -> String {
        switch title {
        case "자연":
            return "A01"
        case "인문(문화/예술/역사)":
            return "A02"
        case "레포츠":
            return "A03"
        case "쇼핑":
            return "A04"
        case "음식":
            return "A05"
        case "숙박":
            return "B02"
        case "추천코스":
            return "C01"
        default:
            return "A01"
        }
    }
    
    func simplifiedAddressRegex(_ fullAddress: String) -> String {
        // 숫자와 번지 제거
        let pattern = #"(\d+.*$)"# // 숫자+문자열로 끝나는 부분
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        let range = NSRange(location: 0, length: fullAddress.utf16.count)
        let result = regex.stringByReplacingMatches(in: fullAddress, options: [], range: range, withTemplate: "")
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    //MARK: - API 호출
    func fetchNearbySpots(lat: String, lng: String, typeCode: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            spots = try await tourRepository.searchLocationSpots(
                pageNum: 0,
                mapX: lng,
                mapY: lat,
                radius: "20000",
                typeCode: typeCode
            )
            
//            print("spots : \(spots)")
        
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
    
    //Todo:
    @MainActor
    func postRouteAPI(start: LocationData, end: LocationData) async {
        isLoading = true
        let requestBody: RequestRouteModel = RequestRouteModel(
            userId: userId,
            start: "\(start.longitude),\(start.latitude)",
            goal: "\(end.longitude),\(end.latitude)",
            wayPoints: "",
            locateName: "\(start.name),\(end.name)"
        )
        
        do {
            let response: () = try await routeRepository.postRoutes(requestBody: requestBody)

            isLoading = false
        } catch {
            print("POST ERROR: /routes \(error)")
        }
    }
}
