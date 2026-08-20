//
//  SpotAdditionalView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 10/19/25.
//

import SwiftUI
import CoreLocation

struct SpotAdditionalView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject private var spotviewModel: SpotSearchViewModel
    @ObservedObject private var dsviewModel: DestinationSearchViewModel
    
    @State private var selectedCategoryID: Int = 0  // tag 선택한 Index
    
    init(spotviewModel: SpotSearchViewModel, dsviewModel: DestinationSearchViewModel) {
        self.spotviewModel = spotviewModel
        self.dsviewModel = dsviewModel
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Top Navigation Bar
            ZStack {
                HStack {
                    Button(action: {
                        navigationManager.pop()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.gray5)
                            .padding()
                    }
                    Spacer()
                }
                
                Text("근처 추천 스팟")
                    .font(.pretendardMedium(size: 18))
                    .foregroundColor(Color.gray5)
            }   // ZStack
            .frame(height: 56)
            .padding(.bottom, 0)
            
            
            searchTagView
                .padding(.bottom, 16)

                if spotviewModel.spots.isEmpty {
                    Spacer()
                    spotEmptyStateView
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    // 목록 상태: 세로 스크롤
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            CustomSpotView(
                                spots: spotviewModel.spots,
                                errorMessage: nil,
                                navigationDetail: { contentid, contenttypeid in
                                    let data = ReqDetailModel(contentid: contentid, contenttypeid: contenttypeid)
                                    
                                    print("스팟탐색: contentid: \(contentid), contenttypeid: \(contenttypeid)")
                                    navigationManager.push(.DetailSpotView(isSpotAdd: false, detailId: data))
                                    
                                },
                                isVertical: true
                            ) // : CustomSpotView
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            
                            // 페이지네이션 트리거
                            if spotviewModel.hasMoreData {
                                if spotviewModel.isLoading {
    //                                    DotsLoadingView()
    //                                        .padding(.vertical, 20)
                                } else {
                                    Color.clear
                                        .frame(height: 100)
                                        .onAppear {
                                            Task {
                                                await spotviewModel.loadMoreSpots()
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
                
            }   // VStack
            .background(Color(.white))
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationBarHidden(true)
            
            // 로딩뷰
            if spotviewModel.isLoading {
                Color.white.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    DotsLoadingView()
                    
                    Spacer()
                }
            }// if 로딩 상태
            
        }   // ZStack
        .interactiveDismissDisabled(false)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        print("👈 스와이프 뒤로가기 감지")
                        navigationManager.pop()
                    }
                }
        )
        .onReceive(dsviewModel.$currentLocation.compactMap { $0 }) { coord in
            Task {
                // 역지오코딩 호출이 있었으나 결과를 쓸 곳이 없어(지역명 표시 UI 부재)
                // 위치가 바뀔 때마다 카카오 API를 부르고 버렸다. 호출을 제거한다.
                // 지역명을 표시하게 되면 SpotSearchView처럼 되살릴 것.
                requestSpots(for: coord)
            }
        }
        .onChange(of: selectedCategoryID) { _ in
            guard let coord = dsviewModel.currentLocation else { return }
            requestSpots(for: coord)
        }
    }
    
    
    
    
    //MARK: - 뷰 불러오기
    private var searchTagView: some View {
        SearchTagView(selectedCategoryID: $selectedCategoryID, fromeHome: false)
    }
    // MARK: - 빈 상태 뷰
    private var spotEmptyStateView: some View {
        HStack{
            VStack(spacing: 24) {
                // 표지판 아이콘
                Image("spotempty")
                    .scaledToFit()
                    .frame(width: 172)
                    .foregroundColor(.gray3)
                
                Text("앗, 현재 위치 근처에는\n 추천 스팟이 없어요")
                    .font(.pretendardMedium(size: 18))
                    .foregroundColor(.gray3)
                    .lineSpacing(6) // 줄간격을 6pt 만큼 띄움
                    .multilineTextAlignment(.center) // (선택) 가운데 정렬

            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            
        }
    }
    //MARK: - 서버 통신 공통 코드
    private func requestSpots(for coord: CLLocationCoordinate2D) {
        Task {
            await spotviewModel.fetchNearbySpots(
                lat: coord.latitude,
                lng: coord.longitude,
                selected: selectedCategoryID
            )
        }
    }
    
}
