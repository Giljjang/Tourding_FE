//
//  DestinationSearchViewModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/15/25.
//

//카카오 통신으로 검색 할 때 주로 사용,

import Foundation
import CoreLocation
import Combine
import SwiftUI

@MainActor
final class DestinationSearchViewModel: NSObject, ObservableObject {
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
        super.init()                         // 2) 슈퍼 초기화
        setupLocationManager()               // 3) 이후 설정(델리게이트 등)
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
                    print("searchPlaces:\(query)")
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
            // 취소 검사
            try Task.checkCancellation()
            
            let response = try await KakaoLocalService.searchPlaces(
                query: query,
                currentLocation: currentLocation,
                radius: 20000,                 // accuracy일 땐 Service에서 미전송 처리됨
                page: currentPage,
                size: 15,
                sort: "accuracy"               // ✅ 항상 정확도순으로 받기
            )
            
            // 취소 검사
            try Task.checkCancellation()
            
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
            
        } catch is CancellationError {
            print("🚫 DestinationSearchViewModel 검색 취소됨")
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
            Task { [weak self] in
                guard let self = self else { return }
                await self.performSearch(query: self.currentSearchQuery)
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
    
    
    // MARK: - 내 위치로 주소값 불러오기
    func refreshLocation() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            // 한 번 얻으면 stopUpdatingLocation() 하도록 돼 있으니 다시 요청
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // 설정 앱으로 이동
            // 권한이 거부된 경우 설정으로 이동하도록 안내
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - 현재 위치를 Place 객체로 변환하여 반환
    func getCurrentLocationAsPlace() async -> Place? {
        guard let currentLocation = currentLocation else {
            print("❌ 현재 위치 정보가 없습니다")
            return nil
        }
        
        do {
            // 역지오코딩을 통해 주소 정보 가져오기
            let response = try await KakaoLocalService.reverseGeocode(
                x: currentLocation.longitude,
                y: currentLocation.latitude
            )
            
            // 가장 상세한 주소 정보 선택 (H: 행정구역, B: 법정구역)
            guard let region = response.documents.first(where: { $0.regionType == "H" }) ?? response.documents.first else {
                print("❌ 주소 정보를 가져올 수 없습니다")
                return nil
            }
            
            // 더 간결한 주소 형태로 placeName 생성
            let shortAddress = [
                region.region1depthName,
                region.region2depthName,
                region.region3depthName
            ].compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            
            // Place 객체 생성
            let place = Place(
                id: "current_location_\(Date().timeIntervalSince1970)", // 고유 ID 생성
                placeName: shortAddress.isEmpty ? "현재 위치" : shortAddress, // 실제 주소를 placeName으로 사용
                categoryName: "현재위치",
                categoryGroupCode: "",
                categoryGroupName: "",
                phone: "",
                addressName: region.addressName,
                roadAddressName: region.addressName, // 도로명 주소가 없으므로 일반 주소 사용
                x: String(currentLocation.longitude),
                y: String(currentLocation.latitude),
                placeUrl: "",
                distance: "0" // 현재 위치이므로 거리는 0
            )
            
            print("✅ 현재 위치 Place 객체 생성 완료:")
            print("   장소명: \(place.placeName)")
            print("   주소: \(place.addressName)")
            print("   좌표: \(place.latitude), \(place.longitude)")
            
            return place
            
        } catch {
            print("❌ 역지오코딩 실패: \(error)")
            return nil
        }
    }
    
    
}
