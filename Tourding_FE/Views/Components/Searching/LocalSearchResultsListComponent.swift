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
                ForEach(Array(results.enumerated()), id: \.element.contentid) { index, spot in
                    LocalSpotRowItemComponent(spot: spot)
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(spot) }
                        .onAppear { onLoadMore(index) } // 마지막 셀에서 다음 페이지 로드
                }

                if isLoading && !results.isEmpty {
                    HStack { Spacer(); ProgressView().padding(); Spacer() }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .refreshable { onRefresh() }
    }
}
