
//
//  KakaoLocalService.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/15/25.
//

import Foundation
import CoreLocation

final class KakaoLocalService {
    
    /// 카카오 REST API 키
    private static var kakaoAPIKey: String {
        return Bundle.main.infoDictionary?["KAKAO_REST_API_KEY"] as? String ?? ""
    }
    
    /// 공통 헤더 생성
    private static var commonHeaders: [String: String] {
        return [
            "Authorization": "KakaoAK \(kakaoAPIKey)",
            "Content-Type": "application/json"
        ]
    }
    
    // MARK: - 키워드로 장소 검색
    /// 키워드로 장소를 검색합니다.
    /// - Parameters:
    ///   - query: 검색할 키워드
    ///   - currentLocation: 현재 위치 (옵션, 거리 계산용)
    ///   - radius: 검색 반경 (미터 단위, 기본값: 20000m = 20km)
    ///   - page: 페이지 번호 (기본값: 1)
    ///   - size: 페이지당 결과 수 (기본값: 15, 최대: 15)
    ///   - sort: 정렬 방식 ("accuracy": 정확도순, "distance": 거리순)
    /// - Returns: 검색 결과
    static func searchPlaces(
        query: String,
        currentLocation: CLLocationCoordinate2D? = nil,
        radius: Int = 20000,
        page: Int = 1,
        size: Int = 15,
        sort: String = "accuracy"
    ) async throws -> KakaoLocalResponse {
        
        // ✅ accuracy면 전국 검색: radius 미전송
        // ✅ distance면 반경 검색: 카카오 스펙상 최대 20km
        let effectiveRadius: Int? = (sort == "distance") ? min(radius, 20000) : nil
        
        let searchRequest = KakaoLocalSearchRequest(
            query: query,
            x: currentLocation?.longitude.description,
            y: currentLocation?.latitude.description,
            radius: effectiveRadius,
            page: page,
            size: size,
            sort: sort
        )
        
        return try await NetworkService.request(
            apiType: .kakaoLocal,
            endpoint: "/v2/local/search/keyword.json",
            parameters: searchRequest.queryParameters,
            headers: commonHeaders,
            method: "GET"
        )
    }
    
    // MARK: - 카테고리로 장소 검색
    /// 카테고리 그룹 코드로 장소를 검색합니다.
    /// - Parameters:
    ///   - categoryGroupCode: 카테고리 그룹 코드 (MT1, CS2, PS3, SC4, AC5, PK6, OL7, SW8, BK9, CT1, AG2, PO3, AT4, AD5, FD6, CE7, HP8, PM9)
    ///   - currentLocation: 현재 위치
    ///   - radius: 검색 반경 (미터 단위, 기본값: 20000m = 20km)
    ///   - page: 페이지 번호 (기본값: 1)
    ///   - size: 페이지당 결과 수 (기본값: 15, 최대: 15)
    ///   - sort: 정렬 방식 ("accuracy": 정확도순, "distance": 거리순)
    /// - Returns: 검색 결과
    static func searchPlacesByCategory(
        categoryGroupCode: String,
        currentLocation: CLLocationCoordinate2D,
        radius: Int = 20000,
        page: Int = 1,
        size: Int = 15,
        sort: String = "distance"
    ) async throws -> KakaoLocalResponse {
        
        let parameters: [String: String] = [
            "category_group_code": categoryGroupCode,
            "x": currentLocation.longitude.description,
            "y": currentLocation.latitude.description,
            "radius": "\(radius)",
            "page": "\(page)",
            "size": "\(size)",
            "sort": sort
        ]
        
        return try await NetworkService.request(
            apiType: .kakaoLocal,
            endpoint: "/v2/local/search/category.json",
            parameters: parameters,
            headers: commonHeaders,
            method: "GET"
        )
    }
    
    
    // MARK: - 좌표 기반 주소 정보 받아오기(KAKAO)
    struct KakaoRegionResponse: Codable {
        struct Region: Codable {
            let regionType: String
            let addressName: String
            let region1depthName: String
            let region2depthName: String
            let region3depthName: String
            enum CodingKeys: String, CodingKey {
                case regionType = "region_type"
                case addressName = "address_name"
                case region1depthName = "region_1depth_name"
                case region2depthName = "region_2depth_name"
                case region3depthName = "region_3depth_name"
            }
        }
        let documents: [Region]
    }
}

//
extension KakaoLocalService {
    static func reverseGeocode(x lon: Double, y lat: Double) async throws -> KakaoRegionResponse {
        let params = ["x": "\(lon)", "y": "\(lat)"]
        return try await NetworkService.request(
            apiType: .kakaoLocal,
            endpoint: "/v2/local/geo/coord2regioncode.json",
            parameters: params,
            headers: commonHeaders,
            method: "GET"
        )
    }
}




// MARK: - 인기 키워드 검색 (편의 메서드들)

//    /// 맛집 검색
//    static func searchRestaurants(
//        near location: CLLocationCoordinate2D,
//        query: String = "맛집",
//        radius: Int = 10000
//    ) async throws -> KakaoLocalResponse {
//        return try await searchPlaces(
//            query: query,
//            currentLocation: location,
//            radius: radius,
//            sort: "distance"
//        )
//    }
//
//    /// 카페 검색
//    static func searchCafes(
//        near location: CLLocationCoordinate2D,
//        query: String = "카페",
//        radius: Int = 5000
//    ) async throws -> KakaoLocalResponse {
//        return try await searchPlaces(
//            query: query,
//            currentLocation: location,
//            radius: radius,
//            sort: "distance"
//        )
//    }
//
//    /// 관광지 검색
//    static func searchTouristSpots(
//        near location: CLLocationCoordinate2D,
//        query: String = "관광지",
//        radius: Int = 50000
//    ) async throws -> KakaoLocalResponse {
//        return try await searchPlaces(
//            query: query,
//            currentLocation: location,
//            radius: radius,
//            sort: "distance"
//        )
//    }
//
//    /// 숙박 시설 검색
//    static func searchAccommodations(
//        near location: CLLocationCoordinate2D,
//        query: String = "숙박",
//        radius: Int = 20000
//    ) async throws -> KakaoLocalResponse {
//        return try await searchPlaces(
//            query: query,
//            currentLocation: location,
//            radius: radius,
//            sort: "distance"
//        )
//    }
//}
//
//// MARK: - 카테고리 그룹 코드 상수
//extension KakaoLocalService {
//    enum CategoryGroupCode {
//        static let largeMart = "MT1"            // 대형마트
//        static let convenienceStore = "CS2"     // 편의점
//        static let kindergarten = "PS3"         // 어린이집, 유치원
//        static let school = "SC4"               // 학교
//        static let academy = "AC5"              // 학원
//        static let parking = "PK6"              // 주차장
//        static let gasStation = "OL7"           // 주유소, 충전소
//        static let subway = "SW8"               // 지하철역
//        static let bank = "BK9"                 // 은행
//        static let culturalFacility = "CT1"     // 문화시설
//        static let intermediateAgency = "AG2"   // 중개업소
//        static let publicInstitution = "PO3"    // 공공기관
//        static let touristAttraction = "AT4"    // 관광명소
//        static let accommodation = "AD5"        // 숙박
//        static let food = "FD6"                 // 음식점
//        static let cafe = "CE7"                 // 카페
//        static let hospital = "HP8"             // 병원
//        static let pharmacy = "PM9"             // 약국
//    }

