//
//  DetailSpotViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import Foundation

final class DetailSpotViewModel: ObservableObject {
    @Published var userId: Int?
    
    @Published var isLoading: Bool = false
    @Published var detailData: ContentDetailModel? = nil
    @Published var currentPosition: DetailBottomSheetPosition = .standard
    
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
            return "" // 매칭 안되면 기본 이미지
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
    
    // contenttypeid 별 매칭
    func mapTypeCodeToEnum() -> ContentType? {
        guard let id = detailData?.contenttypeid else { return nil }
        return ContentType(rawValue: id)
    }
    
    func formatOverview(_ text: String?) -> String {
        guard let text = text else { return "" }
        
        // <br>, <br/>, <br />, <BR>, <BR/>, <BR /> 모두 제거
        do {
            let cleaned = text.replacingOccurrences(
                of: "<br\\s*/?>",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            print("cleaned: \(cleaned)")
            return cleaned
        } catch {
            print("❌ 정규식 패턴 오류: \(error)")
            // 정규식 실패 시 단순 문자열 치환으로 대체
            return text.replacingOccurrences(of: "<br>", with: "")
                      .replacingOccurrences(of: "<br/>", with: "")
                      .replacingOccurrences(of: "<br />", with: "")
        }
    }

    func extractURL(from htmlString: String?) -> String? {
        guard let html = htmlString else { return nil }
        
        let pattern = "href=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        
        if let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        
        return nil
    }
    
    //MARK: - API 호출
    @MainActor
    func getTourAreaDetailAPI(requestBody: ReqDetailModel) async {
        isLoading = true
        do {
            
            print("ReqDetailModel: \(requestBody)")
            let response = try await tourRepository.getTourAreaDetail(requestBody: requestBody)
            
//            print("Detail: \(response)")
            
            detailData = response
            
        } catch {
            print("GET ERROR: /tour/area-detail \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func getRouteLocationAPI() async {
        
        isLoading = true
        
        guard let userId = KeychainHelper.loadUid()  else {
            print("⏭️ postRouteAPI skipped: userId is nil")
            return
        }
        
        do {
            let response = try await routeRepository.getRoutesLocationName(userId: userId)
            routeLocation = response
            
            print("🔹routeLocation: \(routeLocation)")
            
        } catch {
            print("GET ERROR: /routes/location-name \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func postRouteAPI(originalData: [LocationNameModel], updatedData: SpotData) async {
        
        isLoading = true
        
        guard let userId = KeychainHelper.loadUid()  else {
            print("⏭️ postRouteAPI skipped: userId is nil")
            return
        }
        
        guard let start = originalData.first,
              let end = originalData.last else {
            print("❌ originalData가 비어있거나 start/end가 없음")
            isLoading = false
            return
        }
        
        print("🔵 start: \(start), end: \(end)")

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
        
        do {
            print("🔵 API 호출 시작")
            let _: () = try await routeRepository.postRoutes(requestBody: requestBody)
            print("🔵 API 호출 성공")

            isLoading = false
        } catch {
            print("❌ POST ERROR: /routes \(error)")
            isLoading = false
        }
    }
}

enum ContentType: String {
    case touristSpot = "12"
    case culturalFacility = "14"
    case festival = "15"
    case travelCourse = "25"
    case leisure = "28"
    case lodging = "32"
    case shopping = "38"
    case restaurant = "39"
    
    var displayName: String {
        switch self {
        case .touristSpot: return "관광지"
        case .culturalFacility: return "문화시설"
        case .festival: return "행사/공연/축제"
        case .travelCourse: return "여행코스"
        case .leisure: return "레포츠"
        case .lodging: return "숙박"
        case .shopping: return "쇼핑"
        case .restaurant: return "음식점"
        }
    }
}
