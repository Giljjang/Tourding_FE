//
//  SheetRecommendView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/20/25.
//

import SwiftUI

struct SheetRecommendView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @ObservedObject private var recommendRouteViewModel: RecommendRouteViewModel
    private var currentPosition: RecommendBottomSheetPosition
    
    init(recommendRouteViewModel: RecommendRouteViewModel,
         currentPosition: RecommendBottomSheetPosition) {
        self.recommendRouteViewModel = recommendRouteViewModel
        self.currentPosition = currentPosition
    }
    
    var body: some View {
        VStack(alignment: .leading,spacing: 0) {
            header
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 390, height: 8)
                .background(Color.gray1)
            
            // 컨텐츠
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    
                    Text("경유지 안내")
                        .foregroundColor(.gray5)
                        .font(.pretendardMedium(size: 20))
                        .frame(minHeight: 28)
                        .padding(.bottom, 10)
                    
                    if let name1 = recommendRouteViewModel.routeLocation.first?.name {
                        HStack(spacing: 6) {
                            Image("icon_point of departure")
                                .padding(.leading, 17)
                            
                            Text(name1)
                                .foregroundColor(.gray5)
                                .font(.pretendardMedium(size: 16))
                            
                            Spacer()
                        } // : HStack
                        .frame(height: 56)
                        .background(Color.gray1)
                        .cornerRadius(10)
                        .padding(.bottom, 10)
                    }
                    
                    if let name2 = recommendRouteViewModel.routeLocation.last?.name {
                        HStack(spacing: 6) {
                            Image("icon_point of departure")
                                .padding(.leading, 17)
                            
                            Text(name2)
                                .foregroundColor(.gray5)
                                .font(.pretendardMedium(size: 16))
                            
                            Spacer()
                        } // : HStack
                        .frame(height: 56)
                        .background(Color.gray1)
                        .cornerRadius(10)
                        .padding(.bottom, 24)
                    }
                    
                    Text("코스 설명")
                        .foregroundColor(.gray5)
                        .font(.pretendardMedium(size: 20))
                        .frame(minHeight: 28)
                        .padding(.bottom, 8)
                    
                } // : VStack
                .padding(.top, 24)
                
                ExpandableTextView(
                    text: recommendRouteViewModel.description,
                    lineLimit: 2,
                    font: .pretendardRegular(size: 15),
                    fontSize: 15,
                    color: .gray5
                )
                .padding(.bottom, 20)
                
                //컨텐츠뷰 하단 여백 추가
                if currentPosition == .large {
                    Spacer()
                        .frame(height: 150)
                } else if currentPosition == .medium {
                    Spacer()
                        .frame(height: 150)
                }
                
            } // : ScrollView
            .padding(.horizontal, 16)
            
            Spacer()
        } // : VStack
        .padding(.top, 8)
        .background(.white)
        
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(recommendRouteViewModel.routeName.isEmpty ? "추천 코스" : recommendRouteViewModel.routeName.truncated(limit: 21))
                .foregroundColor(.gray6)
                .font(.pretendardMedium(size: 24))
                .frame(minHeight: 34)
                .padding(.bottom, 4)
            
            HStack(spacing: 2) {
                if let start = recommendRouteViewModel.routeLocation.first?.name {
                    Text(start.isEmpty ? "출발지" : start.truncated(limit: 12))
                        .foregroundColor(.gray4)
                        .font(.pretendardMedium(size: 16))
                }
                
                Image("icon_right_color")
                
                if let goal = recommendRouteViewModel.routeLocation.last?.name {
                    Text(goal.isEmpty ? "도착지" : goal.truncated(limit: 12))
                        .foregroundColor(.gray4)
                        .font(.pretendardMedium(size: 16))
                }
                
                Spacer()
            } // : HStack
            .frame(minHeight: 26)
            .padding(.bottom, 20)
            
            // 코스 정보
            courseInfo
            
        }// VStack
        .padding(.horizontal, 16)
    } // : header
    
    private var courseInfo: some View {
        HStack(alignment: .top, spacing: 41) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 3) {
                    Image("icon_time-required (1)")
                    
                    Text("소요 시간")
                        .foregroundColor(.gray4)
                        .font(.pretendardMedium(size: 14))
                        .frame(minHeight: 22)
                } // : HStack
                .padding(.top, 3.5)
                
                if let time =  recommendRouteViewModel.routeTotal?.duration {
                    Text(RidingViewModel.formatSecondsToHoursMinutes(time))
                        .foregroundColor(.main)
                        .font(.pretendardMedium(size: 18))
                        .frame(minHeight: 27)
                        .padding(.bottom, 3.5)
                }
            } // : VStack
            .frame(minWidth: 98)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 1, height: 28)
                .background(Color.gray2)
            
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 3) {
                    Image("icon_total-distance (1)")
                    
                    Text("코스 길이")
                        .foregroundColor(.gray4)
                        .font(.pretendardMedium(size: 14))
                        .frame(minHeight: 22)
                } // : HStack
                .padding(.top, 3.5)
                
                if let distance =  recommendRouteViewModel.routeTotal?.distance {
                    Text(RidingViewModel.formatDistance(distance))
                        .foregroundColor(.main)
                        .font(.pretendardMedium(size: 18))
                        .frame(minHeight: 27)
                        .padding(.bottom, 3.5)
                }
            } // : VStack
            .frame(minWidth: 98)
        } // : HStack
        .padding(.horizontal, 39)
        .padding(.bottom, 18)
    }
}
