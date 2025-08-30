//
//  SpotRepositoryProtocol.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/28/25.
//

import Foundation

protocol SpotRepositoryProtocol {
    
    // MARK: - Spot Search
    
    /// 특정 위치 주변 스팟 검색
    /// - Parameters:
    ///   - pageNum: 페이지 번호
    ///   - mapX: 경도 (longitude)
    ///   - mapY: 위도 (latitude)
    ///   - radius: 검색 반경
    /// - Returns: 검색된 스팟 리스트
    func searchLocationSpots(
        pageNum: Int,
        mapX: String,
        mapY: String,
        radius: String
    ) async throws -> SpotSearchResponse
    
    // MARK: - Spot Detail
    
    /// 스팟 상세 정보 가져오기
    /// - Parameter contentId: 스팟 ID
    /// - Returns: 스팟 상세 정보
    func getSpotDetail(contentId: String) async throws -> SpotDetailResponse
    
    // MARK: - Bookmark
    
    /// 스팟 북마크 추가/제거
    /// - Parameter contentId: 스팟 ID
    /// - Returns: 북마크 결과
    func toggleBookmark(contentId: String) async throws -> BookmarkResponse
    
    /// 북마크된 스팟 리스트 가져오기
    /// - Parameter pageNum: 페이지 번호
    /// - Returns: 북마크된 스팟 리스트
    func getBookmarkedSpots(pageNum: Int) async throws -> SpotSearchResponse
    
    // MARK: - Search
    
    /// 키워드로 스팟 검색
    /// - Parameters:
    ///   - keyword: 검색 키워드
    ///   - pageNum: 페이지 번호
    /// - Returns: 검색된 스팟 리스트
    func searchSpotsByKeyword(
        keyword: String,
        pageNum: Int
    ) async throws -> SpotSearchResponse
    
    // MARK: - Category
    
    /// 카테고리별 스팟 검색
    /// - Parameters:
    ///   - contentTypeId: 컨텐츠 타입 ID (음식점: 39, 관광지: 12 등)
    ///   - pageNum: 페이지 번호
    ///   - mapX: 경도 (선택사항)
    ///   - mapY: 위도 (선택사항)
    ///   - radius: 검색 반경 (선택사항)
    /// - Returns: 카테고리별 스팟 리스트
    func searchSpotsByCategory(
        contentTypeId: String,
        pageNum: Int,
        mapX: String?,
        mapY: String?,
        radius: String?
    ) async throws -> SpotSearchResponse
}
