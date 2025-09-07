//
//  DetailSpotViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import Foundation

final class DetailSpotViewModel: ObservableObject {
    @Published var userId: Int = 2
    
    @Published var isLoading: Bool = false
    @Published var detailData: ContentDetailModel? = nil
    
    @Published var routeLocation: [LocationNameModel] = []
    
    private let tourRepository: TourRepositoryProtocol
    private let routeRepository: RouteRepositoryProtocol
    
    init(
        tourRepository: TourRepositoryProtocol,
        routeRepository: RouteRepositoryProtocol) {
            self.tourRepository = tourRepository
            self.routeRepository = routeRepository
    }
    
    //MARK: - Utils
    func containsCoordinate(originalData: [LocationNameModel], selectedData: SpotData) -> Bool {
        return originalData.contains { data in
            data.lat == selectedData.mapy &&
            data.lon == selectedData.mapx
        }
    }
    
    func mapTypeCodeToImageName() -> String {
        switch detailData?.typeCode {
        case "A01": return "nature"
        case "A02": return "humon"
        case "A03": return "leport"
        case "A04": return "shoping"
        case "A05": return "food"
        case "B02": return "sleep"
        default:
            return "icon_menu" // 매칭 안되면 기본 이미지
        }
    }
    func mapTypeCodeToName() -> String {
        switch detailData?.typeCode {
        case "A01": return "자연"
        case "A02": return "인문(문화/예술/역사)"
        case "A03": return "레포츠"
        case "A04": return "쇼핑"
        case "A05": return "음식"
        case "B02": return "숙박"
        default:
            return ""
        }
    }
    
    func cleanOverviewText(_ text: String?) -> String {
        guard let text = text else { return "" }
        return text.replacingOccurrences(of: "<br>", with: "\n")
    }

    
    //MARK: - API 호출
    @MainActor
    func getTourAreaDetailAPI(requestBody: ReqDetailModel) async {
        isLoading = true
        do {
            
            print("ReqDetailModel: \(requestBody)")
            let response = try await tourRepository.getTourAreaDetail(requestBody: requestBody)
            
            print("Detail: \(response)")
            
            detailData = response
            
        } catch {
            print("GET ERROR: /tour/area-detail \(error)")
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
