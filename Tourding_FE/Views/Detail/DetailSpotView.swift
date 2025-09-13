//
//  DetailSpotView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import SwiftUI

struct DetailSpotView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @StateObject private var detailViewModel: DetailSpotViewModel
    
    let isSpotAdd: Bool
    let detailId: ReqDetailModel
    
    init(detailViewModel: DetailSpotViewModel,
         isSpotAdd: Bool, detailId: ReqDetailModel
    ) {
        self._detailViewModel = StateObject(wrappedValue: detailViewModel)
        self.isSpotAdd = isSpotAdd
        self.detailId = detailId
    }
    
    let topSafeArea = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first?.safeAreaInsets.top ?? 0
    let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                
                detailImage
                
                DetailBottomSheet(
                    content: SheetDetailView(detailViewModel: detailViewModel),
                    screenHeight: geometry.size.height,
                    viewModel: detailViewModel
                )
                
                if detailViewModel.currentPosition == .large {
                    largeTopBar(geometry: geometry)
                }
                
                backButton
                
                if isSpotAdd {
                    spotAddButton
                        .padding(.bottom, 30)
                        .background(.white)
                }
                
                //커스텀 모달
                if modalManager.isPresented && modalManager.showView == .detail {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            modalManager.hideModal()
                        }
                    
                    CustomModalView(modalManager: modalManager)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
                
                // 이미지 확대 모달
                if modalManager.isImageZoomPresented{
                    ImageZoomView(
                        imageUrl: detailViewModel.detailData?.firstimage ?? "",
                        title: detailViewModel.detailData?.title)
                }
                
                if detailViewModel.isLoading {
                    Color.white.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack{
                        Spacer()
                        
                        DotsLoadingView()
                        
                        Spacer()
                    }
                }// if 로딩 상태
                
            } // :ZStack
        } // :GeometryReader
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .onAppear{
            Task { [weak detailViewModel] in
                do {
                    try Task.checkCancellation()
                    await detailViewModel?.getTourAreaDetailAPI(requestBody: detailId)
                    
                    try Task.checkCancellation()
                    await detailViewModel?.getRouteLocationAPI()
                } catch is CancellationError {
                    print("🚫 DetailSpotView 초기화 Task 취소됨")
                } catch {
                    print("❌ DetailSpotView 초기화 에러: \(error)")
                }
            }
        } // :onAppear
    }
    
    //MARK: - View
    private var backButton: some View {
        Button(action:{
            navigationManager.pop()
        }){
            Image("riding_back")
                .padding(.vertical, 8)
                .padding(.leading, 6)
                .padding(.trailing,10)
                .background(Color.white)
                .cornerRadius(30)
        }
        .position(x: 36, y: SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
    } // : backButton
    
    private func largeTopBar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                
                Spacer()
            }
            .frame(
                height: geometry.size.height
                - detailViewModel.currentPosition.height(screenHeight: geometry.size.height)
                      + geometry.safeAreaInsets.top
            )
            .background(Color.white)
            .offset(y: geometry.safeAreaInsets.top)
            .shadow(color: Color(red: 0.71, green: 0.76, blue: 0.81).opacity(0.15), radius: 5, x: 0, y: 4)
            
            Rectangle()
                .fill(Color.white)
                .frame(height: 4)
                .offset(y: geometry.safeAreaInsets.top - 4)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private var spotAddButton: some View {
        Button(action:{
            let detail = detailViewModel.detailData
            
            let spot = SpotData(
                title: detail?.title ?? "",
                addr1: "",
                typeCode: detail?.typeCode ?? "", contentid: detail?.contentid ?? "", contenttypeid: detail?.contenttypeid ?? "",
                firstimage: "", firstimage2: "",
                mapx: detail?.lon ?? "", mapy: detail?.lat ?? "")
            
            if detailViewModel.containsCoordinate(originalData: detailViewModel.routeLocation, selectedData: spot){
                modalManager.showModal(
                    title: "출발지와 도착지가 동일해요",
                    subText: "확인 후 다른 위치로 설정해 주세요",
                    activeText: "확인하기",
                    showView: .detail,
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
                subText: detailViewModel.detailData?.title ?? "",
                activeText: "추가하기",
                showView: .detail,
                onCancel: {
                    print("취소됨")
                },
                onActive: {
                    
                    Task { [weak detailViewModel] in
                        do {
                            try Task.checkCancellation()
                            await detailViewModel?.postRouteAPI(originalData: detailViewModel?.routeLocation ?? [], updatedData: spot)
                            
                            try Task.checkCancellation()
                            await detailViewModel?.getRouteLocationAPI()
                            
                            await MainActor.run {
                                // RidingView까지 가기 
                                navigationManager.popToView(.RidingView)
                            }
                        } catch is CancellationError {
                            print("🚫 DetailSpotView 추가 Task 취소됨")
                        } catch {
                            print("❌ DetailSpotView 추가 에러: \(error)")
                        }
                    }
                } // : onActive
            )
            }//if-else
        }){
            
            HStack(spacing: 0){
                
                Spacer()
                
                Text("스팟 추가하기")
                    .foregroundColor(.white)
                    .font(.pretendardSemiBold(size: 16))
                    .frame(height: 22)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.gray5)
            .cornerRadius(10)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 18)
        .shadow(color: .white.opacity(0.8), radius: 8, x: 0, y: -14)
    } // : spotAddButton
    
    private var detailImage: some View {
        VStack(alignment: .leading, spacing: 0){
            VStack(alignment: .leading, spacing: 0) {
                if let first = detailViewModel.detailData?.firstimage,
                   !first.isEmpty {
                    AsyncImage(url: URL(string: first)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        defaultImage
                    }
                    .onTapGesture {
                        modalManager.showImageZoom()
                    }
                } else if let second = detailViewModel.detailData?.firstimage2,
                          !second.isEmpty {
                    AsyncImage(url: URL(string: second)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        defaultImage
                    }
                    .onTapGesture {
                        modalManager.showImageZoom()
                    }
                } else {
                    defaultImage
                }
            } // : VStack
            .frame(height: 390)
            .frame(maxWidth: screenWidth)
        
            Spacer()
            
        } // : VStack
    }
    
    private var defaultImage: some View {
        VStack{
            Image("defaultImage_empty")
                .padding(.top, 43)
        } // : VStack
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray2)
    }

}
