//
//  SearchRegion.swift
//  Tourding_FE
//
//  스팟 탐색 지역 필터 — 칩 라벨과 TourAPI areaCode의 단일 소스.
//
//  TourAPI는 areaCode를 하나만 받으므로 여러 도(道)를 한 칩으로 묶을 수 없다.
//  묶으면 대표 코드 하나만 조회되어 나머지 도의 스팟이 검색에서 빠진다.
//

import Foundation

enum SearchRegion: String, CaseIterable {
    case seoul = "서울"
    case incheon = "인천"
    case gyeonggi = "경기"
    case daejeon = "대전"
    case sejong = "세종"
    case chungbuk = "충북"
    case chungnam = "충남"
    case daegu = "대구"
    case gyeongbuk = "경북"
    case gyeongnam = "경남"
    case ulsan = "울산"
    case busan = "부산"
    case gwangju = "광주"
    case jeonbuk = "전북"
    case jeonnam = "전남"
    case gangwon = "강원"
    case jeju = "제주"

    var areaCode: Int {
        switch self {
        case .seoul: return 1
        case .incheon: return 2
        case .daejeon: return 3
        case .daegu: return 4
        case .gwangju: return 5
        case .busan: return 6
        case .ulsan: return 7
        case .sejong: return 8
        case .gyeonggi: return 31
        case .gangwon: return 32
        case .chungbuk: return 33
        case .chungnam: return 34
        case .gyeongbuk: return 35
        case .gyeongnam: return 36
        case .jeonbuk: return 37
        case .jeonnam: return 38
        case .jeju: return 39
        }
    }

    /// 필터 칩 표시 순서 (매핑과 같은 소스)
    static var chipLabels: [String] {
        allCases.map(\.rawValue)
    }
}
