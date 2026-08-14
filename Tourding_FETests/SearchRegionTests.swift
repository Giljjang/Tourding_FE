//
//  SearchRegionTests.swift
//  Tourding_FETests
//
//  지역 필터 칩 ↔ TourAPI areaCode 매핑.
//
//  이전에는 칩 목록(FilterSelectionSheet)과 매핑(FilterBarViewModel)이 따로 있었고,
//  "충청"·"경상"·"전라"가 각각 33·35·37 하나로만 매핑돼
//  충남(34)·경남(36)·전남(38) 스팟이 검색에서 영구히 빠졌다.
//

import Testing
@testable import Tourding_FE

struct SearchRegionTests {

    /// 백엔드가 정한 areaCode 표 전체
    @Test func mapsEveryLabelToItsAreaCode() {
        let table: [(label: String, areaCode: Int)] = [
            ("서울", 1), ("인천", 2), ("대전", 3), ("대구", 4), ("광주", 5),
            ("부산", 6), ("울산", 7), ("세종", 8),
            ("경기", 31), ("강원", 32),
            ("충북", 33), ("충남", 34),
            ("경북", 35), ("경남", 36),
            ("전북", 37), ("전남", 38),
            ("제주", 39)
        ]

        for entry in table {
            let region = SearchRegion(rawValue: entry.label)
            #expect(region?.areaCode == entry.areaCode, "\(entry.label)는 areaCode \(entry.areaCode)여야 한다")
        }
    }

    /// areaCode를 공유하지 않는 도(道)는 하나의 칩으로 묶을 수 없다.
    /// TourAPI가 areaCode를 하나만 받으므로 묶으면 절반이 검색에서 빠진다.
    @Test func doesNotMergeProvincesWithDifferentAreaCodes() {
        #expect(SearchRegion(rawValue: "충청") == nil)
        #expect(SearchRegion(rawValue: "경상") == nil)
        #expect(SearchRegion(rawValue: "전라") == nil)
    }

    /// 칩 목록과 매핑이 같은 소스에서 나온다 — 한쪽만 바뀌어 드리프트하는 것을 막는다
    @Test func chipOrderSplitsProvincesInPlace() {
        #expect(SearchRegion.allCases.map(\.rawValue) == [
            "서울", "인천", "경기", "대전", "세종", "충북", "충남",
            "대구", "경북", "경남", "울산", "부산", "광주",
            "전북", "전남", "강원", "제주"
        ])
    }

    @Test func areaCodesAreUniqueAcrossChips() {
        let codes = SearchRegion.allCases.map(\.areaCode)
        #expect(Set(codes).count == codes.count)
    }
}

@MainActor
struct FilterBarRegionMappingTests {

    /// ViewModel이 실제로 이 매핑을 쓰는지 (칩 라벨 → 요청 areaCode)
    @Test func resolvesChipLabelToAreaCode() {
        let viewModel = FilterBarViewModel(tourRepository: FakeTourRepository())

        #expect(viewModel.convertRegionToAreaCode("충남") == 34)
        #expect(viewModel.convertRegionToAreaCode("경남") == 36)
        #expect(viewModel.convertRegionToAreaCode("전남") == 38)
        #expect(viewModel.convertRegionToAreaCode("경기") == 31)
    }

    /// 필터 미선택은 지역 조건 없음 (areaCode=0으로 전송)
    @Test func resolvesNilRegionToNoAreaFilter() {
        let viewModel = FilterBarViewModel(tourRepository: FakeTourRepository())

        #expect(viewModel.convertRegionToAreaCode(nil) == nil)
        #expect(viewModel.convertRegionToAreaCode("없는지역") == nil)
    }
}
