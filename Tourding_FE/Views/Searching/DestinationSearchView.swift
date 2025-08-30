//
//  DestinationSearchView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/7/25.
//

import SwiftUI
import CoreLocation

struct DestinationSearchView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var routeManager: RouteSharedManager
    @EnvironmentObject var recentSearchViewModel : RecentSearchViewModel
    
    @StateObject private var dsViewModel = DestinationSearchViewModel()
    
    
    
    @State private var searchText = ""
    @State private var shouldShowRecentSearches = true  // 최근 검색어 표시 여부를 직접 제어
    @State private var suppressNextOnChange = false     // 칩 누를 때 onchange 무시하기위해서
    
    let isFromHome: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 검색바 영역
            SearchHeaderComponent(
                searchText: $searchText,
                hasSearched: .constant(false),
                onBack: {
                    navigationManager.pop()
                },
                onSearchSubmit: {
                    handleSearchSubmit()
                },
                onTextChange: {
                    handleTextChange()
                }
            )
            .padding(.bottom, 18)
            
            // 최근 검색어 섹션 - 단순한 조건으로 변경
            if !recentSearchViewModel.items.isEmpty && shouldShowRecentSearches {
                RecentSearchSectionComponent(
                    recentSearchItems: recentSearchViewModel.items,
                    onChipTap: { searchTerm in
                        handleChipTap(searchTerm)
                    },
                    onChipDelete: { searchTerm in
                        recentSearchViewModel.remove(searchTerm)
                    },
                    onClearAll: {
                        recentSearchViewModel.clear()
                    }
                )
            }
            
            // 구분선
            if !searchText.isEmpty && !dsViewModel.searchResults.isEmpty {
                Rectangle()
                    .frame(height: 8)
                    .foregroundStyle(Color.gray1)
            }
            
            // 콘텐츠 영역
            contentArea
        }
        .contentShape(Rectangle())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture { hideKeyboard() }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onChange(of: searchText) { newValue in
            handleSearchTextChange(newValue)
        }
        .onDisappear {
            dsViewModel.clearResults()
        }
    }
    
    // MARK: - 이벤트 핸들러들
    private func handleSearchSubmit() {
        print("검색 제출: '\(searchText)'")
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            shouldShowRecentSearches = false  // 엔터 누르면 최근 검색어 숨김
            recentSearchViewModel.add(trimmedText)
            dsViewModel.searchPlaces(query: trimmedText)
        }
    }
    
    private func handleTextChange() {
        // 텍스트가 변경되기 시작하면 최근 검색어 표시
            shouldShowRecentSearches = true
    }
    
    private func handleChipTap(_ searchTerm: String) {
        print("칩 탭: '\(searchTerm)'")
        shouldShowRecentSearches = false          // 섹션 숨김
        suppressNextOnChange = true               // 다음 onChange는 무시
        searchText = searchTerm                   //
        dsViewModel.searchPlaces(query: searchTerm)
    }
    
    private func handleSearchTextChange(_ newValue: String) {
        if suppressNextOnChange {                 //chip 프로그램 변경 무시
            suppressNextOnChange = false
            shouldShowRecentSearches = false
            return
        }
        if newValue.isEmpty {
            // 검색어가 비어있으면 최근 검색어 다시 표시
            shouldShowRecentSearches = true
            dsViewModel.clearResults()
        } else {
            // 타이핑 중이면 실시간 검색
            shouldShowRecentSearches = true
            dsViewModel.searchPlaces(query: newValue)
        }
    }
    
    // MARK: - 콘텐츠 영역
    private var contentArea: some View {
        Group {
            if searchText.isEmpty {
                SearchStateViewsComponent(state: .empty)
            } else if dsViewModel.isLoading && dsViewModel.searchResults.isEmpty {
                SearchStateViewsComponent(state: .loading)
            } else if dsViewModel.searchResults.isEmpty {
                SearchStateViewsComponent(state: .noResults)
            } else {
                SearchResultsListComponent(
                    searchResults: dsViewModel.searchResults,
                    currentLocation: dsViewModel.currentLocation,
                    searchText: searchText,
                    isLoading: dsViewModel.isLoading,
                    onPlaceSelect: { place in
                        shouldShowRecentSearches = false
                        recentSearchViewModel.add(place.placeName)

                        if routeManager.currentSelectionMode == .startLocation {
                            routeManager.setStartLocation(from: place)
                        } else if routeManager.currentSelectionMode == .endLocation {
                            routeManager.setEndLocation(from: place)
                        }

                        dsViewModel.selectPlace(place)
                        navigationManager.pop()
                    },
                    onLoadMore: { index in
                        if index == dsViewModel.searchResults.count - 1, dsViewModel.hasMoreResults {
                            Task { await dsViewModel.loadMoreResults() }
                        }
                    },
                    onRefresh: {
                        if !searchText.isEmpty {
                            dsViewModel.searchPlaces(query: searchText)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - 미리보기
#Preview {
    NavigationView {
        DestinationSearchView(isFromHome: false)
            .environmentObject(NavigationManager())
            .environmentObject(RecentSearchViewModel())
    }
}
