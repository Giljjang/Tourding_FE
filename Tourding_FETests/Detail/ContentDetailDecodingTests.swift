//
//  ContentDetailDecodingTests.swift
//  Tourding_FETests
//
//  버그 1 관련 — "리스트에는 정보가 보이는 스팟이 상세보기에서 아무것도 표시되지 않는다"
//
//  DetailSpotView는 모든 필드를 `detailData?.x ?? ""` / `if let`으로 그린다.
//  따라서 디코딩이 실패하면 detailData가 nil로 남아 에러 표시 하나 없이 전 항목이 빈 화면이 된다.
//  그런데 ContentDetailModel은 60여 필드 중 contentid·typeCode·contenttypeid 셋만 non-optional이라,
//  서버가 그 셋 중 하나만 생략해도 응답 전체가 버려진다.
//  /routes/guide 에서 실제로 같은 계열의 전면 실패가 났다.
//

import Foundation
import Testing
@testable import Tourding_FE

struct ContentDetailDecodingTests {

    /// 분류 필드가 빠져도 본문은 보여야 한다 — 일부 누락이 전면 실패가 되면 안 된다
    @Test func decodesDetailWhenServerOmitsClassificationFields() throws {
        let detail: ContentDetailModel = try FixtureLoader.load("tour_area_detail_partial.json")

        #expect(detail.title == "도깨비정원")
        #expect(detail.address == "강원특별자치도 원주시 지정면")
        #expect(detail.overview?.isEmpty == false)
        #expect(detail.openInfo?.usetime == "09:00~18:00")
    }

    /// 없는 분류 필드는 nil로 관측돼야 한다 (호출부가 이미 옵셔널 안전하다)
    @Test func missingClassificationFieldsSurfaceAsNil() throws {
        let detail: ContentDetailModel = try FixtureLoader.load("tour_area_detail_partial.json")

        #expect(detail.contentid == "2863322")
        #expect(detail.typeCode == nil)
        #expect(detail.contenttypeid == nil)
    }
}
