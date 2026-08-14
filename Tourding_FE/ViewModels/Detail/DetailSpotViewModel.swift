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
    private let userSession: UserSessionProviding

    init(
        tourRepository: TourRepositoryProtocol,
        routeRepository: RouteRepositoryProtocol,
        userSession: UserSessionProviding) {
            self.tourRepository = tourRepository
            self.routeRepository = routeRepository
            self.userSession = userSession
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
        defer { isLoading = false }

        guard let userId = userSession.userId else {
            print("⏭️ postRouteAPI skipped: userId is nil")
            return
        }

        do {
            let response = try await routeRepository.getRoutesLocationName(userId: userId, isUsed: false)
            routeLocation = response
            
            print("🔹routeLocation: \(routeLocation)")
            
        } catch {
            print("GET ERROR: /routes/location-name \(error)")
        }
    }
    
    @MainActor
    func postRouteAPI(originalData: [LocationNameModel], updatedData: SpotData) async {

        isLoading = true
        defer { isLoading = false }

        guard let userId = userSession.userId else {
            print("⏭️ postRouteAPI skipped: userId is nil")
            return
        }

        guard let start = originalData.first,
              let end = originalData.last else {
            print("❌ originalData가 비어있거나 start/end가 없음")
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

        // typeCode (0, last 제외 + updatedData 마지막에 추가)
        //
        // wayPoints·contentId와 같은 "끝에 붙이기" 규칙이어야 한다.
        // locateName은 도착지가 배열에 남아 있어 count-1이 "도착지 앞"이지만,
        // 여기는 dropLast()로 도착지를 이미 뺐으므로 count-1이 "마지막 경유지 앞"이 되어
        // 새 스팟과 마지막 경유지의 카테고리가 서로 뒤바뀐다.
        let typeCodes = originalData.dropFirst().dropLast().map { $0.typeCode }
        let typeCode = (typeCodes + [updatedData.typeCode]).joined(separator: ",")
        
        // contentId (0, last 제외 + updatedData 마지막에 추가)
        let contentIds = originalData.dropFirst().dropLast()
        let contentIdList = contentIds.map {
            "\($0.contentId)"
        }
        let updatedContentId = "\(updatedData.contentid)"
        let contents = (contentIdList + [updatedContentId]).joined(separator: ",")
        
        // contentTypeId (0, last 제외 + updatedData 마지막에 추가)
        // 관광타입(12/14/32/39…)이 들어가는 자리다. contentId를 넣으면 안 된다.
        let contentTypeIds = originalData.dropFirst().dropLast()
        let contentTypeIdList = contentTypeIds.map {
            "\($0.contentTypeId)"
        }
        let updatedContentTypeId = "\(updatedData.contenttypeid)"
        let contentTypes = (contentTypeIdList + [updatedContentTypeId]).joined(separator: ",")

        let requestBody = RequestRouteModel(
            userId: userId,
            start: "\(start.lon),\(start.lat)",
            goal: "\(end.lon),\(end.lat)",
            wayPoints: wayPoints,
            locateName: locateName,
            typeCode: typeCode,
            contentId: contents,
            contentTypeId: contentTypes,
            isUsed: false
        )
        
        do {
            print("🔵 API 호출 시작")
            try await routeRepository.postRoutes(requestBody: requestBody)
            print("🔵 API 호출 성공")
        } catch {
            print("❌ POST ERROR: /routes \(error)")
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
