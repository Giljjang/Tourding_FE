//
//  LocalSearchResultsListComponent.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/31/25.
//

import SwiftUI

struct LocalSearchResultsListComponent: View {
    let results: [SpotData]
    let isLoading: Bool
    let onSelect: (SpotData) -> Void
    let onLoadMore: (Int) -> Void
    let onRefresh: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 허용된 카테고리 코드만 노출 (unknown/기타 제외)
                let allowedTypeCodes: Set<String> = ["A01", "A02", "A03", "A04", "A05", "B02"]
                let filteredResults = results.filter { allowedTypeCodes.contains($0.typeCode.uppercased()) }

                ForEach(Array(filteredResults.enumerated()), id: \.element.contentid) { index, spot in
                    LocalSpotRowItemComponent(spot: spot)
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(spot) }
                        .onAppear { onLoadMore(index) } // 마지막 셀에서 다음 페이지 로드 (필터된 기준)
                }

                if isLoading && !filteredResults.isEmpty {
                    HStack { Spacer(); ProgressView().padding(); Spacer() }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .refreshable { onRefresh() }
    }
}
