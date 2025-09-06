//
//  SpotSearchView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI
import CoreLocation

struct SpotSearchView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    //    @StateObject var destinationVM = DestinationSearchViewModel()
    //    @EnvironmentObject var destinationVM: DestinationSearchViewModel
    
    @State private var regionTitle: String = ""     // 주소값 받아오기
    
    @ObservedObject private var spotviewModel: SpotSearchViewModel
    @ObservedObject private var dsviewModel: DestinationSearchViewModel
    
    
    init(spotviewModel: SpotSearchViewModel, dsviewModel: DestinationSearchViewModel) {
        self.spotviewModel = spotviewModel
        self.dsviewModel = dsviewModel
    }
    
    var body: some View {
        ZStack{
            Color.gray1.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing:0){
                VStack(alignment: .leading, spacing:0){
                    headerSpot
                        .padding(.bottom, 12)
                        .padding(.top, 50)
                        .padding(.leading, 16)
                    
                    searchBar
                        .padding(.bottom, 20)
                        .padding(.leading, 16)
                } //:VStack
                .background(Color(hex: "#F7F9FC").opacity(0.8))
                .background(.ultraThinMaterial)
                .cornerRadius(25)
                
                ScrollView(showsIndicators: false) {
                    myPosition
                        .padding(.top, 19)
                        .padding(.bottom, 17)
                        .padding(.leading, 16)
                    
                    if spotviewModel.spots.isEmpty {
                        spotEmptyStateView
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // 목록 상태: 가로 스크롤
                        ScrollView(.horizontal, showsIndicators: false) {
                            CustomSpotView(
                                spots: spotviewModel.spots,
                                errorMessage: nil, navigationDetail: { contentid, contenttypeid in
                                    let data = ReqDetailModel(contentid: contentid, contenttypeid: contenttypeid)
                                    
                                    print("스팟탐색: contentid: \(contentid), contenttypeid: \(contenttypeid)")
                                    navigationManager.push(.DetailSpotView(isSpotAdd: false, detailId: data))
                                    
                                }
                            ) // : CustomSpotView
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 150)
                } // :ScrollView
                
                Spacer()
                
            } // : Vstack
        } // : ZStack
        // 좌표가 갱신되면 주소 표시
        .onReceive(dsviewModel.$currentLocation.compactMap { $0 }) { coord in
            Task {
                do {
                    let res = try await KakaoLocalService.reverseGeocode(
                        x: coord.longitude, y: coord.latitude
                    )
                    let r = res.documents.first(where: { $0.regionType == "H" }) ?? res.documents.first
                    regionTitle = [r?.region1depthName, r?.region2depthName, r?.region3depthName]
                        .compactMap { $0 }.joined(separator: " ")
                } catch {
                    // 필요 시 에러 토스트/라벨
                }
                // TODO: 여기서 우리 서버 카드 리스트 호출 붙이면 됨
                await spotviewModel.fetchNearbySpots(lat: coord.latitude, lng: coord.longitude)
                
            }
        }
    }
    
    
    //MARK: - View
    
    private var headerSpot: some View {
        HStack(spacing:0){
            VStack(alignment: .leading, spacing:0) {
                
                Text("스팟 탐색")
                    .font(.pretendardSemiBold(size: 26))
                    .foregroundColor(Color.gray6)
                Text("새로운 여행지를 찾아볼까요?")
                    .font(.pretendardMedium(size: 16))
                    .foregroundColor(Color.gray4)
            }
            Spacer()
            
            Image("searching spot")
                .frame(width: 126)
                .padding(.trailing, 28)
            
        } // : HStack
    } // : headerText
    
    private var searchBar: some View {
        HStack() {
            Button(action:{
                navigationManager.push(.DestinationSearchView(isFromHome: false))
            }
                   
            ){
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray3)
                
                Text("어디로 떠나볼까요?")
                    .foregroundColor(.gray2)
                    .font(.pretendardMedium(size: 16))
                Spacer()
            }
            .frame(height: 26)
            .padding(.leading, 16)
            .padding(.vertical, 13)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(Color.gray6)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.trailing, 16)
    }
    
    private var myPosition: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 7){
                Text(regionTitle.isEmpty ? "내 위치를 선택해보세요" : regionTitle)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .background(Color.main)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                Text("근처에 이런곳은 어때요?")
                    .font(.pretendardSemiBold(size: 20))
                    .foregroundColor(.gray5)
            }
            
            Spacer()
            
            Button {
                Task {
                    await spotviewModel.refreshLocationAndFetchSpots()
                    dsviewModel.refreshLocation()
                }
            } label: {
                HStack(spacing: 4.5) {
                    Image("gps")
                    Text("내 위치")
                }
                .font(.pretendardMedium(size: 14))
                .foregroundColor(Color.gray4)
            }
        } // : HStack
        .padding(.trailing, 16)
    } // : headerText
    
    // MARK: - 빈 상태 뷰
    private var spotEmptyStateView: some View {
        HStack{
            VStack(spacing: 24) {
                // 표지판 아이콘 (피그마 디자인과 유사한 이미지)
                Image("spotempty")
                    .scaledToFit()
                    .frame(width: 172)
                    .foregroundColor(.gray3)
                
                Text("앗, 현재 위치 근처에는")
                    .font(.pretendardMedium(size: 18))
                    .foregroundColor(.gray3)
                
                Text("추천 스팟이 없어요")
                    .font(.pretendardMedium(size: 18))
                    .foregroundColor(.gray3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            
        }
    }
    
}
//
//#Preview {
//    SpotSearchView(
//        spotviewModel: SpotSearchViewModel(tourRepository: TourRepository()),
//        dsviewModel: DestinationSearchViewModel(tourRepository: TourRepository()))
//}
