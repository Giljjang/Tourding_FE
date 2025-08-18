//
//  dd.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/15/25.
//

//
//  DestinationSearchViewModel.swift
//  Tourding_FE
//
//  Created by AI on 8/15/25.
//

//카카오 통신으로 검색 할 때 주로 사용,

import Foundation
import CoreLocation
import Combine

@MainActor
class DestinationSearchViewModel: NSObject, ObservableObject {
// MARK: - Published Properties
    @Published var searchResults: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var hasMoreResults = false
    
    // MARK: - Private Properties
    private var currentPage = 1
    private var totalCount = 0
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private var currentSearchQuery = ""
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Location Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 위치 권한 요청
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Search Methods
    
    /// 실시간 검색 (debounce 적용)
    func searchPlaces(query: String) {
        // 검색어가 비어있으면 결과 초기화
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            currentSearchQuery = ""
            return
        }
        
        // 이전 검색어와 같으면 무시
        guard query != currentSearchQuery else { return }
        
        currentSearchQuery = query
        currentPage = 1
        
        // 디바운스를 위해 0.3초 후에 검색 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 검색어가 여전히 유효한지 확인
            if query == self.currentSearchQuery {
                Task {
                    await self.performSearch(query: query, loadMore: false)
                }
            }
        }
    }
    
    /// 실제 검색 수행
    private func performSearch(query: String, loadMore: Bool = false) async {
        if !loadMore {
            searchResults = []
            isLoading = true
        }
        errorMessage = nil

        do {
            let response = try await KakaoLocalService.searchPlaces(
                query: query,
                currentLocation: currentLocation,
                radius: 20000,                 // accuracy일 땐 Service에서 미전송 처리됨
                page: currentPage,
                size: 15,
                sort: "accuracy"               // ✅ 항상 정확도순으로 받기
            )

            // 1) 페이지 합치기
            let merged = loadMore ? (self.searchResults + response.documents)
                                  : response.documents

            // 2) 중복 제거(id 기준)
            let deduped = deduplicateByID(merged)

            // 3) 정확도 유지 + 동일 항목끼리만 거리 오름차순
            self.searchResults = applyAccuracyWithDistanceTieBreak(deduped)

            // 페이징/메타 처리
            totalCount = response.meta.totalCount
            hasMoreResults = !response.meta.isEnd
            currentPage += 1

        } catch {
            errorMessage = handleError(error)
            print("Search error: \(error)")
        }

        isLoading = false
    }
    
    /// 더 많은 결과 로드
    func loadMoreResults() async {
        guard hasMoreResults && !isLoading && !currentSearchQuery.isEmpty else { return }
        await performSearch(query: currentSearchQuery, loadMore: true)
    }
    
    /// 검색 결과 초기화
    func clearResults() {
        searchResults = []
        currentSearchQuery = ""
        errorMessage = nil
        hasMoreResults = false
        currentPage = 1
        isLoading = false
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) -> String {
        if let networkError = error as? ErrorType {
            return networkError.localizedDescription
        }
        return "검색 중 오류가 발생했습니다"
    }
    
    // MARK: - Utility Methods
    
    /// 장소 선택
    func selectPlace(_ place: Place) {
        // 선택된 장소에 대한 처리 (예: 네비게이션, 상세 정보 등)
        print("Selected place: \(place.placeName) at \(place.addressName)")
        // 여기서 선택된 장소를 상위 뷰나 다른 서비스로 전달
    }
}

// MARK: - CLLocationManagerDelegate
extension DestinationSearchViewModel: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        currentLocation = location.coordinate
        
        // 위치를 한 번 얻으면 업데이트 중지 (배터리 절약)
        manager.stopUpdatingLocation()
        
        // 이미 검색어가 있다면 위치 기반으로 재검색
        if !currentSearchQuery.isEmpty {
            Task {
                await performSearch(query: currentSearchQuery)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        // 위치를 못 가져와도 검색은 가능하도록 함
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            // 위치 권한이 없어도 검색은 계속 진행
            print("Location permission denied")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    // 중복 제거 (id 기준)
    private func deduplicateByID(_ items: [Place]) -> [Place] {
        var seen = Set<String>()
        var result: [Place] = []
        result.reserveCapacity(items.count)
        for p in items where seen.insert(p.id).inserted {
            result.append(p)
        }
        return result
    }

    // 정확도(원본 순서) 유지 + 동일 장소끼리만 거리 오름차순
    private func applyAccuracyWithDistanceTieBreak(_ items: [Place]) -> [Place] {
        // 원본(accuracy) 순서를 보존하기 위해 인덱스를 함께 보관
        let indexed = items.enumerated().map { (idx, p) in (idx, p) }

        // “같은 장소” 정의: placeName + 주소(도로명 있으면 도로명 우선)
        func key(_ p: Place) -> String {
            let addr = p.roadAddressName.isEmpty ? p.addressName : p.roadAddressName
            return (p.placeName + "|" + addr).lowercased()
        }

        // distance(m). 없으면 아주 큰 값으로
        func dist(_ p: Place) -> Double {
            p.distanceInMeters ?? .greatestFiniteMagnitude
        }

        let grouped = Dictionary(grouping: indexed, by: { key($0.1) })
        // 그룹 전체 순서는 “그 그룹에서 가장 먼저 등장한 원본 인덱스”로 결정
        let orderedKeys = grouped.keys.sorted { a, b in
            let ia = grouped[a]?.map({ $0.0 }).min() ?? .max
            let ib = grouped[b]?.map({ $0.0 }).min() ?? .max
            return ia < ib
        }

        var output: [Place] = []
        output.reserveCapacity(items.count)
        for k in orderedKeys {
            let bucket = grouped[k]!
            // 그룹 내부는 거리 오름차순, 동일 거리면 원본 인덱스 순
            let sortedBucket = bucket.sorted {
                let da = dist($0.1), db = dist($1.1)
                if da != db { return da < db }
                return $0.0 < $1.0
            }
            output.append(contentsOf: sortedBucket.map { $0.1 })
        }
        return output
    }

    
    
    
    
    
}
