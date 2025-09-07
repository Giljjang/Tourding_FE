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
    
    @Published var clickFliter: String = "전체"
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
    
    func containsCoordinate(originalData: [LocationNameModel], selectedData: SpotData) -> Bool {
        return originalData.contains { data in
            data.lat == selectedData.mapy &&
            data.lon == selectedData.mapx
        }
    }
    
    //MARK: - API 호출
    func fetchNearbySpots(lat: String, lng: String, typeCode: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var results = try await tourRepository.searchLocationSpots(
                pageNum: 0,
                mapX: lng,
                mapY: lat,
                radius: "20000",
                typeCode: typeCode
            )
            
            print("fetchNearbySpots typeCode : \(typeCode)")
//            print("fetchNearbySpots : \(results)")
            
            //추천 코스 제외
            spots = results.filter { $0.typeCode != "C01" }
        
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
            
//            print("routeLocation: \(routeLocation)")
            
        } catch {
            print("GET ERROR: /routes/location-name \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func postRouteAPI(originalData: [LocationNameModel], updatedData: SpotData) async {
        isLoading = true
        guard let start = originalData.first,
              let end = originalData.last else {
            return
        }

        // wayPoints (0, last 제외 + updatedData 마지막에 추가)
        let middlePoints = originalData.dropFirst().dropLast()
        let wayPointsArray = middlePoints.map { "\($0.lon),\($0.lat)" }
        let updatedPoint = "\(updatedData.mapx),\(updatedData.mapy)"
        let wayPoints = (wayPointsArray + [updatedPoint]).joined(separator: "|")

        // locateName (모두 포함 + updatedData.title을 마지막 앞에 삽입)
        var locateNames = originalData.map { $0.name }
        if locateNames.count >= 2 {
            locateNames.insert(updatedData.title, at: locateNames.count - 1)
        } else {
            locateNames.append(updatedData.title)
        }
        let locateName = locateNames.joined(separator: ",")

        // typeCode (0번, 마지막 제외 + updatedData.typeCode를 마지막 앞에 삽입)
        var typeCodes = originalData.dropFirst().dropLast().map { $0.typeCode }
        if typeCodes.count >= 1 {
            typeCodes.insert(updatedData.typeCode, at: typeCodes.count - 1)
        } else {
            typeCodes.append(updatedData.typeCode)
        }
        let typeCode = typeCodes.joined(separator: ",")

        let requestBody = RequestRouteModel(
            userId: userId,
            start: "\(start.lon),\(start.lat)",
            goal: "\(end.lon),\(end.lat)",
            wayPoints: wayPoints,
            locateName: locateName,
            typeCode: typeCode
        )

//        print("requestBody: \(requestBody)")
        
        do {
            let response: () = try await routeRepository.postRoutes(requestBody: requestBody)

            isLoading = false
        } catch {
            print("POST ERROR: /routes \(error)")
        }
    }
    
}
