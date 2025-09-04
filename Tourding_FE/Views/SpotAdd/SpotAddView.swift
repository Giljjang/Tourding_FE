//
//  SpotAddView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/28/25.
//

import SwiftUI

struct SpotAddView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @StateObject var spotAddViewModel: SpotAddViewModel
    let lat: String
    let lon: String
    
    init(spotAddViewModel: SpotAddViewModel,
         lat: String, lon: String) {
        self._spotAddViewModel = StateObject(wrappedValue: spotAddViewModel)
        self.lat = lat
        self.lon = lon
    }
    
    var body: some View {
        ZStack{
            VStack(alignment: .leading,spacing:0){
                
                VStack(alignment: .leading, spacing: 0) {
                    header
                    
                    section
                    
                    filterSection
                }
                .background(Color(hex: "#F7F9FC").opacity(0.8))
                .background(.ultraThinMaterial)
                .cornerRadius(25)
                
                if spotAddViewModel.spots.isEmpty {
                    emptyView
                } else {
                    scrollSpotListView
                }//: if-else
                
                Spacer()
                
            } // : VStack
            
            if modalManager.isPresented && modalManager.showView == .spotAdd {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        modalManager.hideModal()
                    }
                
                CustomModalView(modalManager: modalManager)
            }
            
            if spotAddViewModel.isLoading {
                Color.white.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack{
                    Spacer()
                    
                    DotsLoadingView()
                    
                    Spacer()
                }
            }// if 로딩 상태
            
        }// :Zstck
        .navigationBarBackButtonHidden()
        .background(Color.gray1)
        .onAppear{
            Task{
                await spotAddViewModel.fetchNearbySpots(lat: lat, lng: lon, typeCode: "")
                await spotAddViewModel.getRouteLocationAPI()
            }
        }//: onAppear
    }
    
    //MARK: - View
    private var header: some View {
        HStack(spacing: 0) {
            Button(action:{
                navigationManager.pop()
                //뒤로갈 때 전달
            }){
                Image("spotAdd_back")
                    .padding(.leading, 16)
            }
            
            Spacer()
            
            Text("스팟 추가")
                .foregroundColor(.gray5)
                .font(.pretendardMedium(size: 18))
            
            Spacer()
            
            Button(action:{
                //Todo: 검색 페이지로 이동
            }){
                Image("spotAdd_search")
                    .padding(.trailing, 16)
            }
            
        } // : HStack
        .frame(height: 56)
        .padding(.top, 24)
    } // : header
    
    private var section: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("들르기 좋은 스팟")
                    .foregroundColor(.gray6)
                    .font(.pretendardSemiBold(size: 26))
                
                Text("도착지 근처 스팟을 모았어요")
                    .foregroundColor(.gray4)
                    .font(.pretendardMedium(size: 16))
            } // : VStack
            .padding(.top, 46)
            .padding(.trailing, 27)
            
            Image("illust_Recommended spot")
                .padding(.top, 14)
        } // : HStack
        .padding(.leading, 16)
        .padding(.bottom, 16)
    }
    
    private func toggleFilterButton(
        title: String
    ) -> some View {
        Button(action:{
            spotAddViewModel.clickFliter = title
            Task{
                await spotAddViewModel.fetchNearbySpots(
                    lat: lat,
                    lng: lon,
                    typeCode: spotAddViewModel.matchTypeCodeName(for: title))
            }
        }){
            HStack(spacing: 0) {
                Image(
                    spotAddViewModel.clickFliter == title ? "\(spotAddViewModel.matchImageName(for: title))_on" :
                    spotAddViewModel.matchImageName(for: title))
                
                Text(title)
                    .foregroundColor(
                        spotAddViewModel.clickFliter == title ?
                            .white : .gray4)
                    .font(.pretendardMedium(size: 14))
            }
            .padding(.vertical, 6)
            .padding(.leading, 10)
            .padding(.trailing, 12)
            .background(spotAddViewModel.clickFliter == title ? Color.gray5 : Color.white)
            .cornerRadius(10)
        }
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(spotAddViewModel.tagFilter, id:\.self){ tag in
                    toggleFilterButton(title: tag)
                }
            } // : HStack
            .padding(.leading, 16)
            .padding(.bottom, 14)
        } // : ScrollView
    }
    
    private var spotRowView: some View {
        ForEach(spotAddViewModel.spots){ spot in
            HStack(alignment: .top, spacing: 0){
                VStack{
                    if let url = URL(string: spot.firstimage), !spot.firstimage.isEmpty {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image("empty")
                    }
                }
                .frame(width: 52, height: 52)
                .background(Color.gray1)
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.title.truncated(limit: 14))
                        .foregroundColor(.gray6)
                        .font(.pretendardSemiBold(size: 16))
                    
                    Text(spot.addr1 == "" ? "-" : spotAddViewModel.simplifiedAddressRegex(spot.addr1).truncated(limit: 16))
                        .foregroundColor(.gray4)
                        .font(.pretendardRegular(size: 14))
                }
                .padding(.leading, 12)
                .padding(.top, 5)
                
                Spacer()
                
                Button(action:{
                    if spotAddViewModel.containsCoordinate(originalData: spotAddViewModel.routeLocation, selectedData: spot){
                        modalManager.showModal(
                            title: "출발지와 도착지가 동일해요",
                            subText: "확인 후 다른 위치로 설정해 주세요",
                            activeText: "확인하기",
                            showView: .spotAdd,
                            onCancel: {
                                print("취소됨")
                            },
                            onActive: {
                                print("시작됨")
                            }
                        )
                    } else {
                        modalManager.showModal(
                            title: "코스에 이 스팟을 추가할까요?",
                            subText: "'\(spot.title.truncated(limit: 21))'",
                            activeText: "추가하기",
                            showView: .spotAdd,
                            onCancel: {
                                print("취소됨")
                            },
                            onActive: {
                                print("추가됨")
                                Task{
                                    await spotAddViewModel.postRouteAPI(originalData: spotAddViewModel.routeLocation, updatedData: spot)
                                    await spotAddViewModel.getRouteLocationAPI()
                                    navigationManager.pop()
                                
                                }
                            }
                        )
                    } // : if-else
                }){
                    Text("추가")
                        .foregroundColor(.gray4)
                        .font(.pretendardMedium(size: 14))
                        .padding(.vertical, 9.2)
                        .padding(.horizontal, 12)
                        .background(Color.gray1)
                        .cornerRadius(10)
                }
                .padding(.vertical, 10)
                
            } // : HStack
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } // : ForEach
    }
    
    private var scrollSpotListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                //Row Cell List
                spotRowView
                
            } //: VStack
            .padding(.top, 4)
            .background(.white)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.top, 24)
        } // : ScrollView
    }
    
    private var emptyView: some View {
        VStack{
            Spacer()
            
            HStack(alignment: .top, spacing:0){
                Spacer()
                
                Image("illust_No recommendations")
                
                Spacer()
            }
            
            Text("앗, 현재 위치 근처에는\n추천 스팟이 없어요")
                .foregroundColor(.gray3)
                .font(.pretendardMedium(size: 18))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Spacer()
        } // : VStack
        .frame(maxHeight: .infinity)
        .padding(.top, 24)
    }
}
