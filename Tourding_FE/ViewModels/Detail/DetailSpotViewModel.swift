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
    @Published var errorMessage: String? = nil
    
    private let tourRepository: TourRepositoryProtocol
    private let routeRepository: RouteRepositoryProtocol
    private let userSession: UserSessionProviding

    /// 라이딩 스타일 공급원. 경로 요청에 실을 값을 여기서 얻는다.
    let profileStore: RidingProfileProviding
    /// 지금 편집 중인 경로(draft / 최근 사용). 읽기·쓰기가 같은 경로를 향해야 한다.
    let editSession: RouteEditSessionProviding

    init(
        tourRepository: TourRepositoryProtocol,
        routeRepository: RouteRepositoryProtocol,
        userSession: UserSessionProviding,
        profileStore: RidingProfileProviding,
        editSession: RouteEditSessionProviding) {
            self.profileStore = profileStore
            self.editSession = editSession
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
            let response = try await routeRepository.getRoutesLocationName(userId: userId, isUsed: editSession.isUsed)
            routeLocation = response
            
            print("🔹routeLocation: \(routeLocation)")
            
        } catch {
            print("GET ERROR: /routes/location-name \(error)")
        }
    }
    
    /// 스팟 추가 진입점.
    ///
    /// onAppear는 상세 정보를 먼저 받고 getRouteLocationAPI를 나중에 부른다.
    /// 상세가 그려진 순간 추가 버튼을 누를 수 있으므로 그때 경로가 비어 있을 수 있다.
    /// 그대로 postRouteAPI에 넘기면 guard에 걸려 POST가 나가지 않는데도 화면은 넘어간다.
    @MainActor
    func addSpotToRoute(_ spot: SpotData) async {
        if routeLocation.isEmpty {
            await getRouteLocationAPI()
        }

        guard !routeLocation.isEmpty else {
            errorMessage = "경로 정보를 불러오지 못해 스팟을 추가하지 못했습니다."
            print("❌ 스팟 추가 중단 - 경로 데이터 없음")
            return
        }

        await postRouteAPI(originalData: routeLocation, updatedData: spot)
    }

    @MainActor
    func postRouteAPI(originalData: [LocationNameModel], updatedData: SpotData) async {

        isLoading = true
        defer { isLoading = false }

        guard let userId = userSession.userId else {
            print("⏭️ postRouteAPI skipped: userId is nil")
            return
        }

        // 경로가 비었으면 POST하지 않는다.
        // 리팩토링 때 이 조건을 count >= 2로 좁혔다가 되돌렸다 — 원래 판정은
        // `first`/`last`가 nil인가(= 빈 배열인가)였다. 항목이 하나뿐인 경로도
        // 예전에는 요청이 나갔으므로 그 동작을 유지한다.
        guard !originalData.isEmpty else {
            print("❌ originalData가 비어있거나 start/end가 없음")
            return
        }

        let updatedRoute = RouteRequestBuilder.insertingSpotBeforeGoal(updatedData, into: originalData)
        guard let requestBody = RouteRequestBuilder.make(
            from: updatedRoute,
            userId: userId,
            isUsed: editSession.isUsed,
            routeOption: await profileStore.effectiveOption(userId: userId, editSession: editSession)
        ) else {
            print("❌ 경로 본문을 만들 수 없습니다")
            return
        }


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
