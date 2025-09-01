//
//  SearchStateViewsComponent.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/22/25.
//

import SwiftUI

struct SearchStateViewsComponent: View {
    enum SearchState {
        case empty
        case empty2
        case loading
        case noResults
    }
    
    let state: SearchState
    
    var body: some View {
        Group {
            switch state {
            case .empty:
                EmptyStateView()
            case .empty2:
                EmptyStateView2()
            case .loading:
                LoadingStateView()
            case .noResults:
                NoResultsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 빈 상태 뷰
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("searchempty")
                .resizable()
                .scaledToFit()
                .frame(width: 338)
        }
    }
}

struct EmptyStateView2: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("empty2")
                .resizable()
                .scaledToFit()
                .frame(width: 338)
        }
    }
}

// MARK: - 로딩 상태 뷰
struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            DotsLoadingView()
        }
    }
}

// MARK: - 검색 결과 없음 뷰
struct NoResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("searchwrong")
                .frame(width: 338)
        }
    }
}
