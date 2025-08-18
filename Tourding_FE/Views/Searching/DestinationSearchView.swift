
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
    @StateObject private var viewModel = DestinationSearchViewModel()
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var routeManager: RouteSharedManager
    @StateObject private var recentSearchViewModel = RecentSearchViewModel()
    
    @State private var searchText = ""
    @State var hasSearched = false // 검색 실행 여부 추적
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 검색바 영역
            searchHeader
                .padding(.bottom, 18)
            
            if !recentSearchViewModel.items.isEmpty && (searchText.isEmpty || (!searchText.isEmpty && !hasSearched)) {
                recentSearchSection
            }
            
            if !searchText.isEmpty && !viewModel.searchResults.isEmpty{
                Rectangle()
                    .frame(height: 8)
                    .foregroundStyle(Color.gray1)
            }
            
            // 콘텐츠 영역
            contentArea
        }
        .contentShape(Rectangle())            // 빈 공간도 탭 인식 가능하게
        .ignoresSafeArea(.keyboard, edges: .bottom)   // 키보드 떠도 레이아웃 안 밀림
        .onTapGesture { hideKeyboard() } // 키보드 내리기
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onChange(of: searchText) {
            hasSearched = false // 타이핑 중에는 검색하지 않은 상태로 리셋
            viewModel.searchPlaces(query: searchText)
        }
        .onDisappear {
            viewModel.clearResults()
        }
    }
    
    // MARK: - 상단 검색바
    private var searchHeader: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 16)
            
            Button(action: {
                navigationManager.pop()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.gray5)
                    .frame(width: 24, height: 24)
            }
            
            SearchBar(
                  text: $searchText,
                  hasSearched: $hasSearched,
                  onSubmit: {
                      hasSearched = true // 엔터를 누르면 검색 완료 상태로 변경
                      // 검색어가 비어있지 않을 때만 최근 검색어에 추가
                      let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                      if !trimmedText.isEmpty {
                          recentSearchViewModel.add(trimmedText)
                      }
                  },
                  onTextChange: {
                      // 사용자가 직접 타이핑할 때만 hasSearched를 false로 리셋
                      if hasSearched {
                          hasSearched = false
                      }
                  }
              )
            
            Spacer()
                .frame(width: 4)
        }
        .padding(.top, 8)
    }
    
    // MARK: - 최근 검색어 섹션
        private var recentSearchSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                // 헤더
                HStack {
                    Text("최근 검색")
                        .font(.pretendardMedium(size: 18))
                        .foregroundColor(.gray6)
                    
                    Spacer()
                    
                    Button("전체삭제") {
                        recentSearchViewModel.clear()
                    }
                    .font(.pretendardMedium(size: 14))
                    .foregroundColor(.gray5)
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 14)
                
                // 최근 검색어 칩들 (가로 스크롤)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recentSearchViewModel.items, id: \.self) { searchTerm in
                            RecentChip(
                                title: searchTerm,
                                onTap: {
                                    // 칩을 탭하면 검색어 입력 후 검색 실행
                                    hasSearched = true
                                    searchText = searchTerm
                                    viewModel.searchPlaces(query: searchTerm)
                                },
                                onDelete: {
                                    recentSearchViewModel.remove(searchTerm)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    
    // MARK: - 콘텐츠 영역
    private var contentArea: some View {
        Group {
            if searchText.isEmpty {
                // 빈 상태 (검색어 없음)
                emptyStateView
            } else if viewModel.isLoading && viewModel.searchResults.isEmpty {
                // 로딩 상태
                loadingStateView
            } else if viewModel.searchResults.isEmpty {
                // 1초 로딩 + 검색 결과 없음
                noResultsView
            } else {
                // 검색 결과 리스트
                searchResultsList
            }
        }
    }
    
    // MARK: - 빈 상태 뷰
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image("searchempty")
                .resizable()
                .scaledToFit()
                .frame(width: 338)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 로딩 상태 뷰
    private var loadingStateView: some View {
        VStack(spacing: 16) {
            DotsLoadingView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 검색 결과 없음 뷰
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image("searchwrong")
                .frame(width: 338)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 검색 결과 리스트
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, place in
                    // 셀
                    PlaceRowItem(
                        place: place,
                        currentLocation: viewModel.currentLocation,
                        searchText: searchText,
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hasSearched = true
                        // 장소 선택시에도 최근검색어에 추가
                        recentSearchViewModel.add(place.placeName)

                        if(routeManager.currentSelectionMode == .startLocation){
                            routeManager.setStartLocation(from: place)
                        }else if(routeManager.currentSelectionMode == .endLocation){
                            routeManager.setEndLocation(from: place)
                        }
                        
                        viewModel.selectPlace(place)
                        navigationManager.pop()
                    }
                    .onAppear {
                        // 무한 스크롤 로딩
                        if index == viewModel.searchResults.count - 1, viewModel.hasMoreResults {
                            Task { await viewModel.loadMoreResults() }
                        }
                    }
                }
                
                // 더 로드 중 인디케이터
                if viewModel.isLoading && !viewModel.searchResults.isEmpty {
                    HStack { Spacer(); ProgressView().padding(); Spacer() }
                }
            }
            .padding(.vertical, 0)
        }
        .scrollDismissesKeyboard(.immediately)
        .refreshable { // iOS 15+: ScrollView에서도 작동
            if !searchText.isEmpty { viewModel.searchPlaces(query: searchText) }
        }
    }
}

// MARK: - 장소 행 아이템
struct PlaceRowItem: View {
    let place: Place
    var currentLocation: CLLocationCoordinate2D?
    var searchText: String = "" // 검색어 추가
    
    var body: some View {
        VStack(spacing:0){
            HStack(spacing: 16) {
                // 위치 아이콘
                Image("spot")
                    .resizable()
                    .renderingMode(.original)          // 템플릿 변환 방지(색 유지)
                    .aspectRatio(1, contentMode: .fit) // 정사각 유지
                    .frame(width: 18, height: 20)
                    .fixedSize()
                
                // 장소 정보
                VStack(alignment: .leading, spacing: 5) {
                    // 장소명 (하이라이트 적용)
                    place.placeName.highlightedText(
                        searchText: searchText,
                        highlightColor: .blue, // 원하는 하이라이트 색상
                        normalColor: Color.gray6
                    )
                    .font(.pretendardMedium(size: 16))
                    .lineLimit(1)
                    
                    // 주소
                    Text(place.roadAddressName.isEmpty ? place.addressName : place.roadAddressName)
                        .font(.pretendardRegular(size: 14))
                        .foregroundColor(Color.gray4)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 거리 표시
                if let formattedDistance = place.formattedDistance {
                    Text(formattedDistance)
                        .font(.pretendardMedium(size: 14))
                        .foregroundColor(Color.gray5)
                }
            } // : HStack
            .padding(.vertical, 16)
            .padding(.leading, 18)
            .padding(.trailing, 16)
            // 커스텀 구분선
            Divider()
                .frame(height:1)
                .overlay(Color.gray1)
                .padding(.horizontal, 16)
        } // : VStack
        .contentShape(Rectangle())
    }
}

// MARK: - 미리보기
#Preview {
    NavigationView {
        DestinationSearchView()
            .environmentObject(NavigationManager())
    }
}
