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

    private var filteredResults: [SpotData] {
        let allowedTypeCodes: Set<String> = ["A01", "A02", "A03", "A04", "A05", "B02"]
        return results.filter { allowedTypeCodes.contains(displayTypeCode(for: $0)) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
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
        .onChange(of: results) { newResults in
            // #region agent log
            DebugSessionLogger.log(
                location: "LocalSearchResultsListComponent.swift:body",
                message: "local results display filter",
                hypothesisId: "H",
                data: [
                    "sourceCount": String(newResults.count),
                    "displayCount": String(filteredResults.count),
                    "emptyTypeCodeCount": String(newResults.filter { $0.typeCode.isEmpty }.count),
                    "contentTypeIds": Array(Set(newResults.map { $0.contenttypeid })).sorted().joined(separator: ",")
                ]
            )
            // #endregion
        }
    }

    private func displayTypeCode(for spot: SpotData) -> String {
        let typeCode = spot.typeCode.uppercased()
        if !typeCode.isEmpty {
            return typeCode
        }

        switch spot.contenttypeid {
        case "28":
            return "A03"
        case "32":
            return "B02"
        case "38":
            return "A04"
        case "39":
            return "A05"
        case "12", "14", "15":
            return "A02"
        default:
            return ""
        }
    }
}
