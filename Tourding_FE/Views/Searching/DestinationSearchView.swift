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
//    @EnvironmentObject var recentSearchViewModel : RecentSearchViewModel
    
    @StateObject private var dsViewModel = DestinationSearchViewModel()
    @ObservedObject private var filterViewModel: FilterBarViewModel
    @ObservedObject private var recentSearchViewModel: RecentSearchViewModel
    
    @State private var searchText = ""
    @State private var shouldShowRecentSearches = true  // 최근 검색어 표시 여부를 직접 제어
    @State private var suppressNextOnChange = false     // 칩 누를 때 onchange 무시하기위해서
    @State private var didSubmit = false   //  엔터 or 칩으로 ‘제출’했는지
    
    // 필터 상태 추가
    @State private var selectedRegion: String? = nil
    @State private var selectedTheme: String? = nil
    
    @State private var isSearchInProgress = false     // 검색 중 상태 보호용 플래그 추가
    
    
    let isFromHome: Bool
    
    init(isFromHome: Bool, filterViewModel: FilterBarViewModel, RecentSearchViewModel: RecentSearchViewModel) {
        self.isFromHome = isFromHome
        self.filterViewModel = filterViewModel
        self.recentSearchViewModel = RecentSearchViewModel
    }
    
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
                    // onChange(of: searchText)를 사용하므로 여기서는 아무것도 하지 않음
//                    handleSearchTextChange(searchText)
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
                        didSubmit = false
                    }
                )
            }
            // 이거 필터 누르면, 검색되고 아래 뷰에 뜨게 해야겠쥐?
            if !isFromHome && didSubmit {
                FilterBarView(
                    selectedRegion: $selectedRegion,
                    selectedTheme: $selectedTheme,
                    onFilterChanged: { region, theme in
                        filterViewModel.searchLocalWithFilters(
                            query: searchText,
                            region: region,
                            theme: theme
                        )
                    },
                    onResetFilters: {
                        selectedRegion = nil
                        selectedTheme = nil
                        filterViewModel.searchLocalWithFilters(
                            query: searchText,
                            region: nil,
                            theme: nil
                        )
                    }
                )
                .padding(.bottom, 18)
            }
            
            // 구분선
            if !searchText.isEmpty && (!dsViewModel.searchResults.isEmpty || !filterViewModel.localResults.isEmpty && didSubmit) {
                Rectangle()
                    .frame(height: 8)
                    .foregroundStyle(Color.gray1)
            }
            
            // 콘텐츠 영역
            contentArea
        }
        .contentShape(Rectangle())
        .background(Color(.white).ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture {hideKeyboard() }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onChange(of: searchText) { newValue in
            print("?????onChange가 눌리는겨")
            handleSearchTextChange(newValue)
        }
        .onDisappear {
            dsViewModel.clearResults()
        }
    }
    
    // MARK: - 이벤트 핸들러들
    private func handleSearchSubmit() {
          print("🔍 검색 제출: '\(searchText)' isFromHome: \(isFromHome)")
//          let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
//          guard !trimmedText.isEmpty else { return }
          
          // 🆕 검색 진행 중 플래그 설정
          isSearchInProgress = true
          didSubmit = true
          shouldShowRecentSearches = false
          recentSearchViewModel.add(searchText)
          suppressNextOnChange = true
          
          if isFromHome {
              print("🏠 홈에서 카카오 API 검색 시작")
              dsViewModel.searchPlaces(query: searchText)
          } else {
              print("🌍 로컬 검색 준비 중...")
              print("📊 검색 전 상태 - didSubmit: \(didSubmit), isLoading: \(filterViewModel.isLoading)")
              
              selectedRegion = nil
              selectedTheme = nil
              
//              handleChipTap(trimmedText)
              
              filterViewModel.searchLocalWithFilters(
                  query: searchText,
                  region: selectedRegion,
                  theme: selectedTheme
              )
              
              
              print("📊 검색 후 즉시 상태 - isLoading: \(filterViewModel.isLoading)")
          }
      }
    
    // 🆕 검색 완료 감지 및 플래그 해제
    private func handleSearchCompletion() {
        if !filterViewModel.isLoading && isSearchInProgress {
            print("🎯 검색 완료 감지 - 플래그 해제")
            isSearchInProgress = false
        }
    }
    
    private func handleChipTap(_ searchTerm: String) {
        print("칩 탭: '\(searchTerm)'")
        shouldShowRecentSearches = false          // 섹션 숨김
        suppressNextOnChange = true               // 다음 onChange는 무시
        didSubmit = true
        selectedRegion = nil
        selectedTheme = nil
        searchText = searchTerm                   //
        if isFromHome{
            dsViewModel.searchPlaces(query: searchTerm)
        } else {
            // TODO: 여기서 로컬 서버 주소로 하는거 추가
            print("칩 탭: '\(searchTerm)'")

            filterViewModel.searchLocalWithFilters(query: searchTerm, region: selectedRegion , theme: selectedTheme)
        }
    }
    
    private func handleSearchTextChange(_ newValue: String) {
        if suppressNextOnChange {                 //chip 프로그램 변경 무시
            suppressNextOnChange = false
            shouldShowRecentSearches = false
            didSubmit = true
            print("111111111onChange가 눌리는겨")
            
            return
        }
        if newValue.isEmpty {
            // 검색어가 비어있으면 최근 검색어 다시 표시
            shouldShowRecentSearches = true
            didSubmit = false
            dsViewModel.clearResults()
            print("2222222onChange가 눌리는겨")
            
        } else {
            if isFromHome{
                // 타이핑 중이면 실시간 검색
                shouldShowRecentSearches = true
                didSubmit = true
                dsViewModel.searchPlaces(query: newValue)
                print("33333333onChange가 눌리는겨")
                
            } else { // 여기서는 아무것도 안뜨고 그냥 최근 검색어만 숨기기
                shouldShowRecentSearches = true
                didSubmit = false
                print("4444444onChange가 눌리는겨")
                
            }
        }
    }
    
    // MARK: - 콘텐츠 영역
    @ViewBuilder
    private var contentArea: some View {
        if isFromHome{ // Home에서 왔을 때
            if searchText.isEmpty {
                SearchStateViewsComponent(state: .empty)
                    .onAppear{print("home의 isEmpty가 눌리는겨")}
                
            } else if dsViewModel.isLoading && dsViewModel.searchResults.isEmpty {
                SearchStateViewsComponent(state: .loading)
                    .onAppear{print("home으 ㅣ loading가 눌리는겨")}
                
            } else if dsViewModel.searchResults.isEmpty{
                SearchStateViewsComponent(state: .noResults)
                    .onAppear{print("home의 noResults가 눌리는겨")}
                
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
                .onAppear{print("home에서 온 이것이 눌리는겨")}
            }
        } else {        // 여기서 부터 local
            if searchText.isEmpty || didSubmit == false {
                SearchStateViewsComponent(state: .empty)
                    .onAppear { print("isEmpty가 눌리는겨") }
            } else if filterViewModel.isLoading && filterViewModel.localResults.isEmpty {
                SearchStateViewsComponent(state: .loading)
                    .onAppear {
                    print("loading가 눌리는겨")
                }
            } else if filterViewModel.localResults.isEmpty {
                SearchStateViewsComponent(state: .noResults)
                    .onAppear { print("noResults가 눌리는겨") }
            }
            
            else { // 홈 말고 다른 곳에서 왔을 때
                LocalSearchResultsListComponent(
                    results: filterViewModel.localResults,
                    isLoading: filterViewModel.isLoading,
                    onSelect: { spot in
                        // 로컬 스팟 선택 시 동작
                        print("로컬 스팟 선택: \(spot)")
                        // 필요한 경우 여기서 상세 화면으로 이동하거나 다른 동작 수행
                    },
                    onLoadMore: { index in
                        if index == filterViewModel.localResults.count - 1, filterViewModel.hasMoreResults {
                            filterViewModel.loadMoreWithFilters(
                                region: selectedRegion,
                                theme: selectedTheme
                            )
                        }
                    },
                    onRefresh: {
                        if !searchText.isEmpty {
                            filterViewModel.searchLocalWithFilters(
                                query: searchText,
                                region: selectedRegion,
                                theme: selectedTheme
                            )
                        }
                    }
                )
                .onAppear {
                    print("Home에서 안오고 달다른 곳에서 온거시여")
                }
            }
        }
    }
}

//// MARK: - 미리보기
//#Preview {
//    let filterViewModel = FilterBarViewModel(tourRepository: TourRepository())
//    
//    return NavigationView {
//        DestinationSearchView(isFromHome: false, filterViewModel: filterViewModel)
//            .environmentObject(NavigationManager())
//            .environmentObject(RecentSearchViewModel())
//            .environmentObject(RouteSharedManager())
//            .environmentObject(HomeViewModel(testRepository: TestRepository()))
//    }
//}
