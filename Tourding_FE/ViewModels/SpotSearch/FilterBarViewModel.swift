//
//  FilterBarViewModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/31/25.
//

import Foundation
import Combine
@MainActor
class FilterBarViewModel: NSObject, ObservableObject {
    @Published var localResults: [SpotData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreResults = false

    private var currentPage = 1
    private var currentSearchQuery = ""
    private let tourRepo: TourRepositoryProtocol

    // (선택) 이전 요청 취소용
    private var currentTask: Task<Void, Never>?

    init(tourRepository: TourRepositoryProtocol) {
        self.tourRepo = tourRepository
    }

    func searchLocal(
        query: String,
        typeCode: String? = nil,
        areaCode: Int? = nil
    ) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            localResults = []
            errorMessage = nil
            hasMoreResults = false
            return
        }

        // ✅ 초기 검색: 바로 로딩 켜기 (NoResult 깜빡임 방지)
        isLoading = true
        errorMessage = nil
        hasMoreResults = false

        currentSearchQuery = q
        currentPage = 1
        localResults = []

        // (선택) 이전 태스크 취소
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            await self.performLocalSearch(loadMore: false, typeCode: typeCode, areaCode: areaCode)
        }
    }

    func loadMoreLocal(typeCode: String? = nil, areaCode: Int? = nil) {
        guard hasMoreResults, !isLoading, !currentSearchQuery.isEmpty else { return }
        Task { [weak self] in
            guard let self = self else { return }
            await self.performLocalSearch(loadMore: true, typeCode: typeCode, areaCode: areaCode)
        }
    }

//    private func performLocalSearch(loadMore: Bool, typeCode: String?, areaCode: Int?) async {
//        if loadMore { isLoading = true }
//        defer { isLoading = false }
//
//        do {
//            try Task.checkCancellation()
//
//            let items = try await tourRepo.searchByKeyword(
//                keyword: currentSearchQuery,
//                pageNum: currentPage,
//                typeCode: (typeCode?.isEmpty == false) ? typeCode! : "0",
//                areaCode: areaCode ?? 0
//            )
//
//            try Task.checkCancellation()
//
//            if loadMore { localResults += items } else { localResults = items }
//            hasMoreResults = !items.isEmpty
//            currentPage += 1
//        } catch is CancellationError {
//            // 취소는 조용히 무시
//        } catch {
//            errorMessage = (error as NSError).localizedDescription
//            hasMoreResults = false
//        }
//    }
    private func performLocalSearch(loadMore: Bool, typeCode: String?, areaCode: Int?) async {
        print("🔍 performLocalSearch 시작 - loadMore: \(loadMore)")
        
        if loadMore {
            isLoading = true
            print("📊 더보기 로딩 시작")
        }
        
        defer {
            isLoading = false
            print("📊 로딩 완료 - isLoading: false")
        }

        do {
            try Task.checkCancellation()
            
            print("🌐 API 호출 시작 - keyword: \(currentSearchQuery), page: \(currentPage)")

            let items = try await tourRepo.searchByKeyword(
                keyword: currentSearchQuery,
                pageNum: currentPage,
                typeCode: (typeCode?.isEmpty == false) ? (typeCode ?? "0") : "0",
                areaCode: areaCode ?? 0
            )

            print("📥 API 응답 받음 - items count: \(items.count)")
            
            try Task.checkCancellation()

            if loadMore {
                localResults += items
                print("➕ 결과 추가됨 - 총 개수: \(localResults.count)")
            } else {
                localResults = items
                print("🔄 결과 교체됨 - 총 개수: \(localResults.count)")
            }
            
            hasMoreResults = !items.isEmpty
            currentPage += 1
            
            print("✅ 검색 완료 - hasMore: \(hasMoreResults), nextPage: \(currentPage)")
            
        } catch is CancellationError {
            print("❌ 검색 취소됨")
        } catch {
            print("❌ 검색 에러: \(error)")
            errorMessage = (error as NSError).localizedDescription
            hasMoreResults = false
        }
    }

    /// 필터와 함께 로컬 검색 실행
        func searchLocalWithFilters(
            query: String,
            region: String?,
            theme: String?
        ) {
            print("searchLocalWithFilters까지는 왔습니다. query: \(query), region: \(region ?? "nil"), theme: \(theme ?? "nil")")
            let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedQuery.isEmpty else { return }
            
            let areaCode = convertRegionToAreaCode(region)
            let typeCode = convertThemeToTypeCode(theme)
            
            searchLocal(query: trimmedQuery, typeCode: typeCode, areaCode: areaCode)
        }
        
        /// 더 많은 결과 로드 (필터 포함)
        func loadMoreWithFilters(region: String?, theme: String?) {
            let areaCode = convertRegionToAreaCode(region)
            let typeCode = convertThemeToTypeCode(theme)
            loadMoreLocal(typeCode: typeCode, areaCode: areaCode)
        }
        
        // MARK: - Private Conversion Methods
        
        /// 칩 라벨 → TourAPI areaCode. 매핑의 단일 소스는 `SearchRegion`이다.
        /// (테스트에서 직접 검증하기 위해 internal — 로직은 SearchRegion에 있다)
        func convertRegionToAreaCode(_ region: String?) -> Int? {
            guard let region else { return nil }
            return SearchRegion(rawValue: region)?.areaCode
        }
        
        private func convertThemeToTypeCode(_ theme: String?) -> String? {
            guard let theme = theme else { return nil }
            
            let themeMap: [String: String] = [
                "자연": "A01",
                "인문(문화/예술/역사)": "A02",
                "레포츠": "A03",
                "쇼핑": "A04",
                "음식": "A05",
                "숙박": "B02"
            ]
            
            return themeMap[theme]
        }
}
