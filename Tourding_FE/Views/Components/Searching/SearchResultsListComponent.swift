//
//  SearchResultsListComponent.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/22/25.
//

import SwiftUI
import CoreLocation

struct SearchResultsListComponent: View {
    let searchResults: [Place]
    let currentLocation: CLLocationCoordinate2D?
    let searchText: String
    let isLoading: Bool
    let onPlaceSelect: (Place) -> Void
    let onLoadMore: (Int) -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, place in
                    // 셀
                    PlaceRowItemComponent(
                        place: place,
                        currentLocation: currentLocation,
                        searchText: searchText
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPlaceSelect(place)
                    }
                    .onAppear {
                        // 무한 스크롤 로딩
                        onLoadMore(index)
                    }
                }
                
                // 더 로드 중 인디케이터
                if isLoading && !searchResults.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 0)
        }
        .scrollDismissesKeyboard(.immediately)
        .refreshable { // iOS 15+: ScrollView에서도 작동
            onRefresh()
        }
    }
}
