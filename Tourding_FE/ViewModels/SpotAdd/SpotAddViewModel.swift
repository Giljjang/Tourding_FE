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
    @Published var currentPage = 1
    
    @Published var errorMessage: String?
    
    private let tourRepository: TourRepositoryProtocol
    private let routeRepository: RouteRepositoryProtocol

    /// 첫 페이지 search-location 직렬화 — 동시 요청 시 서버 500 방지
    private var nearbySearchSerialTask: Task<Void, Never>?
    private var nearbySearchGeneration = 0
    
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

            // UserDefaults에서 저장된 필터 상태 복원
            self.clickFliter = UserDefaults.standard.string(forKey: "SpotAddClickFilter") ?? "전체"
            self.userId = userSession.userId
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
    
    func typeCode(for filter: String) -> String {
        switch filter {
        case "전체":
            return TourTypeCode.all
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
            return TourTypeCode.all
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
    func fetchNearbySpots(lat: String, lng: String, typeCode: String, pageNum: Int = 1) async {
        let isFirstPage = pageNum <= 1

        if isFirstPage {
            nearbySearchGeneration += 1
            let generation = nearbySearchGeneration
            let previous = nearbySearchSerialTask

            // #region agent log
            DebugSessionLogger.log(
                location: "SpotAddViewModel.swift:fetchNearbySpots",
                message: "first page fetch queued",
                hypothesisId: "G",
                data: [
                    "generation": String(generation),
                    "typeCode": typeCode,
                    "filter": clickFliter
                ]
            )
            // #endregion

            nearbySearchSerialTask = Task { @MainActor in
                await previous?.value
                guard generation == nearbySearchGeneration else {
                    print("🛣️ [SpotAdd] stale queued fetch skipped gen=\(generation)")
                    return
                }
                await performNearbySearch(
                    lat: lat,
                    lng: lng,
                    typeCode: typeCode,
                    pageNum: pageNum,
                    generation: generation
                )
            }
            await nearbySearchSerialTask?.value
            return
        }

        await performNearbySearch(
            lat: lat,
            lng: lng,
            typeCode: typeCode,
            pageNum: pageNum,
            generation: nearbySearchGeneration
        )
    }

    private func performNearbySearch(
        lat: String,
        lng: String,
        typeCode: String,
        pageNum: Int,
        generation: Int
    ) async {
        let isFirstPage = pageNum <= 1
        if isFirstPage {
            isLoading = true
            currentPage = 1
            hasMoreData = true
        } else {
            isScrollLoading = true
        }
        errorMessage = nil

        defer {
            if isFirstPage {
                isLoading = false
            } else {
                isScrollLoading = false
            }
        }

        print("🛣️ [SpotAdd] search-location filter=\(clickFliter) typeCode=\(typeCode) pageNum=\(pageNum) lat=\(lat) lon=\(lng) gen=\(generation)")

        // #region agent log
        DebugSessionLogger.log(
            location: "SpotAddViewModel.swift:performNearbySearch",
            message: "search executing",
            hypothesisId: "G",
            data: [
                "generation": String(generation),
                "currentGeneration": String(nearbySearchGeneration),
                "typeCode": typeCode,
                "pageNum": String(pageNum),
                "filter": clickFliter,
                "lat": lat,
                "lon": lng,
                "isFirstPage": String(isFirstPage)
            ]
        )
        // #endregion

        do {
            let results = try await tourRepository.searchLocationSpots(
                pageNum: pageNum,
                mapX: lng,
                mapY: lat,
                radius: "20000",
                typeCode: typeCode
            )

            guard generation == nearbySearchGeneration else {
                print("🛣️ [SpotAdd] stale response ignored gen=\(generation)")
                return
            }

            let filteredResults = results.filter { $0.typeCode != "C01" }

            if isFirstPage {
                spots = filteredResults
                if filteredResults.isEmpty {
                    hasMoreData = false
                } else {
                    currentPage = 2
                }
            } else {
                spots.append(contentsOf: filteredResults)
                if filteredResults.isEmpty {
                    hasMoreData = false
                } else {
                    currentPage += 1
                }
            }

            print("📄 hasMoreData: \(hasMoreData) (데이터 있음: \(!filteredResults.isEmpty))")

        } catch {
            guard generation == nearbySearchGeneration else { return }
            errorMessage = "스팟을 불러오는데 실패했습니다."
            print("API 오류: \(error)")
        }
    }
    
    // 무한 스크롤을 위한 다음 페이지 로드
    func loadNextPage(lat: String, lng: String, typeCode: String) async {
        print("🔄 loadNextPage 호출됨 - hasMoreData: \(hasMoreData), isScrollLoading: \(isScrollLoading), currentPage: \(currentPage)")
        
        guard hasMoreData && !isScrollLoading else { 
            print("❌ loadNextPage 조건 불만족 - hasMoreData: \(hasMoreData), isScrollLoading: \(isScrollLoading)")
            return 
        }
        
        print("📄 다음 페이지 로드 시작: \(currentPage)")
        await fetchNearbySpots(lat: lat, lng: lng, typeCode: typeCode, pageNum: currentPage)
    }
    
    @MainActor
    func getRouteLocationAPI(showsLoading: Bool = true) async {
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            return
        }

        if showsLoading {
            isLoading = true
        }
        defer {
            if showsLoading {
                isLoading = false
            }
        }

        do {
            let response = try await routeRepository.getRoutesLocationName(userId: userId, isUsed: editSession.isUsed)
            routeLocation = response
        } catch {
            print("GET ERROR: /routes/location-name \(error)")
            errorMessage = "경로 정보를 불러오는데 실패했습니다."
        }
    }
    
    /// 스팟 추가 진입점.
    ///
    /// 화면은 스팟 리스트를 먼저 띄우고 routeLocation을 나중에 받는다.
    /// 리스트가 뜨는 순간 사용자는 탭할 수 있으므로, 추가 시점에 경로가 비어 있을 수 있다.
    /// 그대로 postRouteAPI에 넘기면 guard에 걸려 POST가 나가지 않는데도 그냥 pop돼
    /// "추가했는데 리스트에도 지도에도 없는" 상태가 된다.
    @MainActor
    func addSpotToRoute(_ spot: SpotData) async {
        if routeLocation.isEmpty {
            await getRouteLocationAPI(showsLoading: false)
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
        guard let userId = userId else {
            print("❌ userId가 nil입니다")
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            return
        }
        
        // 경로가 비었으면 POST하지 않는다.
        // 리팩토링 때 이 조건을 count >= 2로 좁혔다가 되돌렸다 — 원래 판정은
        // `first`/`last`가 nil인가(= 빈 배열인가)였다. 항목이 하나뿐인 경로도
        // 예전에는 요청이 나갔으므로 그 동작을 유지한다.
        guard !originalData.isEmpty else {
            print("❌ 경로 데이터가 부족합니다")
            errorMessage = "경로 정보가 부족합니다."
            return
        }

        isLoading = true
        // 해제를 do 블록 안에 두면 실패 시 로딩 오버레이가 영구히 남는다
        defer { isLoading = false }

        let updatedRoute = RouteRequestBuilder.insertingSpotBeforeGoal(updatedData, into: originalData)
        guard let requestBody = RouteRequestBuilder.make(
            from: updatedRoute,
            userId: userId,
            isUsed: editSession.isUsed,
            routeOption: await profileStore.currentOption(userId: userId)
        ) else {
            print("❌ 경로 본문을 만들 수 없습니다")
            errorMessage = "경로 정보가 부족합니다."
            return
        }


        do {
            _ = try await routeRepository.postRoutes(requestBody: requestBody)
        } catch {
            print("POST ERROR: /routes \(error)")
        }
    }
    
}
