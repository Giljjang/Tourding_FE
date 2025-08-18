//
//  SearchListModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/13/25.
//
//
//import Foundation
//
//struct SearchListModel: Hashable, Identifiable {
//    let id: String = UUID().uuidString
//    let Title: String
//    let SubTitle: String
//    let distance: Int
//    let longitude: Double
//    let latitude: Double
//}
//
//
//
//
//
//// KakaoKeywordSearchDTO.swift
//struct KakaoKeywordSearchResponse: Decodable {
//    let documents: [KakaoPlace]
//    let meta: KakaoMeta
//}
//
//struct KakaoMeta: Decodable {
//    let is_end: Bool
//    let pageable_count: Int
//    let total_count: Int
//}
//
//struct KakaoPlace: Decodable {
//    let id: String
//    let place_name: String          // 장소명
//    let address_name: String        // 지번주소
//    let road_address_name: String   // 도로명주소
//    let x: String                   // 경도 (String으로 옴)
//    let y: String                   // 위도 (String으로 옴)
//    let distance: String?           // 중심좌표 기준 거리(미터). x,y 주면 내려옴
//}
//
//extension SearchListModel {
//    init(from dto: KakaoPlace) {
//        self.init(
//            Title: dto.place_name,
//            SubTitle: dto.road_address_name.isEmpty ? dto.address_name : dto.road_address_name,
//            distance: Int(dto.distance ?? "0") ?? 0,
//            longitude: Double(dto.x) ?? 0,
//            latitude: Double(dto.y) ?? 0
//        )
//    }
//}

//
//  KakaoLocalModels.swift
//  Tourding_FE
//
//  Created by AI on 8/15/25.
//

import Foundation

// MARK: - 카카오 로컬 키워드 검색 응답
struct KakaoLocalResponse: Codable {
    let meta: Meta
    let documents: [Place]
}

// MARK: - 메타 정보
struct Meta: Codable {
    let totalCount: Int
    let pageableCount: Int
    let isEnd: Bool
    let sameName: SameName?
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pageableCount = "pageable_count"
        case isEnd = "is_end"
        case sameName = "same_name"
    }
}

// MARK: - 동일한 이름의 장소 정보
struct SameName: Codable {
    let region: [String]
    let keyword: String
    let selectedRegion: String
    
    enum CodingKeys: String, CodingKey {
        case region
        case keyword
        case selectedRegion = "selected_region"
    }
}

// MARK: - 장소 정보
struct Place: Codable, Identifiable {
    let id: String
    let placeName: String
    let categoryName: String
    let categoryGroupCode: String
    let categoryGroupName: String
    let phone: String
    let addressName: String
    let roadAddressName: String
    let x: String // 경도 (longitude)
    let y: String // 위도 (latitude)
    let placeUrl: String
    let distance: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case categoryName = "category_name"
        case categoryGroupCode = "category_group_code"
        case categoryGroupName = "category_group_name"
        case phone
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case x
        case y
        case placeUrl = "place_url"
        case distance
    }
}

// MARK: - 장소 정보 확장 (계산된 속성들)
extension Place {
    /// 위도 (Double 타입)
    var latitude: Double {
        return Double(y) ?? 0.0
    }
    
    /// 경도 (Double 타입)
    var longitude: Double {
        return Double(x) ?? 0.0
    }
    
    /// 거리 (미터 단위, Double 타입)
    var distanceInMeters: Double? {
        guard let distance = distance else { return nil }
        return Double(distance)
    }
    
    /// 거리 (킬로미터 단위, 포맷된 문자열)
    var formattedDistance: String? {
        guard let distanceInMeters = distanceInMeters else { return nil }
        
        if distanceInMeters < 1000 {
            return "\(Int(distanceInMeters))m"
        } else {
            let km = distanceInMeters / 1000
            return String(format: "%.1fkm", km)
        }
    }
}

// MARK: - 카카오 로컬 API 검색 요청 파라미터
struct KakaoLocalSearchRequest {
    let query: String           // 검색 키워드
    let categoryGroupCode: String? = nil // 카테고리 그룹 코드 (옵션)
    let x: String?              // 중심 좌표의 경도 (현재 위치)
    let y: String?              // 중심 좌표의 위도 (현재 위치)
    let radius: Int?            // 중심 좌표부터의 반경거리 (미터)
    let rect: String? = nil     // 사각형 범위 (옵션)
    let page: Int               // 페이지 번호 (기본값: 1)
    let size: Int               // 페이지당 문서 수 (기본값: 15, 최대: 15)
    let sort: String            // 정렬 방식 (distance, accuracy)
    
    init(query: String,
         x: String? = nil,
         y: String? = nil,
         radius: Int? = nil,
         page: Int = 1,
         size: Int = 15,
         sort: String = "accuracy") {
        self.query = query
        self.x = x
        self.y = y
        self.radius = radius
        self.page = page
        self.size = size
        self.sort = sort
    }
    
    /// URL 쿼리 파라미터로 변환
    var queryParameters: [String: String] {
        var params: [String: String] = [
            "query": query,
            "page": "\(page)",
            "size": "\(size)",
            "sort": sort
        ]
        
        if let x = x { params["x"] = x }
        if let y = y { params["y"] = y }
        if let radius = radius { params["radius"] = "\(radius)" }
        if let categoryGroupCode = categoryGroupCode { params["category_group_code"] = categoryGroupCode }
        if let rect = rect { params["rect"] = rect }
        
        return params
    }
}
