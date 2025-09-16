//
//  SpotAddViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/28/25.
//

import Foundation

@MainActor
final class SpotAddViewModel: ObservableObject {
    @Published var userId: Int?
    
    @Published var clickFliter: String {
        didSet {
            UserDefaults.standard.set(clickFliter, forKey: "SpotAddClickFilter")
        }
    }
    let tagFilter: [String] = ["전체","자연", "인문(문화/예술/역사)", "레포츠", "쇼핑", "음식", "숙박"]
    
    @Published var routeLocation: [LocationNameModel] = []
    @Published var spots: [SpotData] = []
    
    @Published var isLoading = false //전체 로딩
    @Published var isScrollLoading: Bool = false // 스크롤 로딩
    @Published var hasMoreData = true // 가져올 데이터가 더 있는지 확인
    @Published var currentPage = 0
    
    @Published var errorMessage: String?
    
    private let tourRepository: TourRepositoryProtocol
    private let routeRepository: RouteRepositoryProtocol
    
    init(
        tourRepository: TourRepositoryProtocol,
        routeRepository: RouteRepositoryProtocol) {
            self.tourRepository = tourRepository
            self.routeRepository = routeRepository
            
            // UserDefaults에서 저장된 필터 상태 복원
            self.clickFliter = UserDefaults.standard.string(forKey: "SpotAddClickFilter") ?? "전체"
            self.userId = KeychainHelper.loadUid()
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
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: fullAddress.utf16.count)
            let result = regex.stringByReplacingMatches(in: fullAddress, options: [], range: range, withTemplate: "")
            return result.trimmingCharacters(in: .whitespaces)
        } catch {
            print("❌ 정규식 패턴 오류: \(error)")
            // 정규식 실패 시 원본 주소 반환
            return fullAddress
        }
    }
    
    func containsCoordinate(originalData: [LocationNameModel], selectedData: SpotData) -> Bool {
        return originalData.contains { data in
            data.lat == selectedData.mapy &&
            data.lon == selectedData.mapx
        }
    }
    
    //MARK: - API 호출
    func fetchNearbySpots(lat: String, lng: String, typeCode: String, pageNum: Int = 0) async {
        if pageNum == 0 {
            isLoading = true
            currentPage = 0
            hasMoreData = true
        } else {
            isScrollLoading = true
        }
        errorMessage = nil
        
        do {
            var results = try await tourRepository.searchLocationSpots(
                pageNum: pageNum,
                mapX: lng,
                mapY: lat,
                radius: "20000",
                typeCode: typeCode
            )
            
            print("fetchNearbySpots typeCode : \(typeCode), pageNum: \(pageNum)")
            print("📊 받은 데이터 개수: \(results.count)")
            
            //추천 코스 제외
            let filteredResults = results.filter { $0.typeCode != "C01" }
            print("🔍 필터링 후 데이터 개수: \(filteredResults.count)")
            
            if pageNum == 0 {
                // 첫 페이지 → 기존 데이터 리셋
                spots = filteredResults
                currentPage = 0
                print("🔄 첫 페이지 로드 완료 - 총 \(spots.count)개")
            } else {
                // 다음 페이지 → 기존 데이터 뒤에 추가
                spots.append(contentsOf: filteredResults)
                currentPage = pageNum
                print("➕ 다음 페이지 추가 완료 - 총 \(spots.count)개")
            }
            
            // 더 이상 데이터가 없는지 확인 (빈 배열이면 마지막 페이지)
            hasMoreData = !filteredResults.isEmpty
            print("📄 hasMoreData: \(hasMoreData) (데이터 있음: \(!filteredResults.isEmpty))")
            
        } catch {
            errorMessage = "스팟을 불러오는데 실패했습니다."
            print("API 오류: \(error)")
            
        }
        
        if pageNum == 0 {
            isLoading = false
        } else {
            isScrollLoading = false
        }
    }
    
    // 무한 스크롤을 위한 다음 페이지 로드
    func loadNextPage(lat: String, lng: String, typeCode: String) async {
        print("🔄 loadNextPage 호출됨 - hasMoreData: \(hasMoreData), isScrollLoading: \(isScrollLoading), currentPage: \(currentPage)")
        
        guard hasMoreData && !isScrollLoading else { 
            print("❌ loadNextPage 조건 불만족 - hasMoreData: \(hasMoreData), isScrollLoading: \(isScrollLoading)")
            return 
        }
        
        let nextPage = currentPage + 1
        print("📄 다음 페이지 로드 시작: \(nextPage)")
        await fetchNearbySpots(lat: lat, lng: lng, typeCode: typeCode, pageNum: nextPage)
    }
    
    @MainActor
    func getRouteLocationAPI() async {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            return
        }
        
        isLoading = true
        do {
            let response = try await routeRepository.getRoutesLocationName(userId: userId)
            routeLocation = response
            
//            print("routeLocation: \(routeLocation)")
            
        } catch {
            print("GET ERROR: /routes/location-name \(error)")
            errorMessage = "경로 정보를 불러오는데 실패했습니다."
        }
        isLoading = false
    }
    
    @MainActor
    func postRouteAPI(originalData: [LocationNameModel], updatedData: SpotData) async {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            return
        }
        
        guard let start = originalData.first,
              let end = originalData.last else {
            print("❌ 경로 데이터가 부족합니다")
            errorMessage = "경로 정보가 부족합니다."
            return
        }
        
        isLoading = true

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
