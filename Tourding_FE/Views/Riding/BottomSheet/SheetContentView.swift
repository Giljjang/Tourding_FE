//
//  SheetContentView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/6/25.
//

import SwiftUI

struct SheetContentView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @ObservedObject private var ridingViewModel: RidingViewModel
    
    @State private var draggedItem: LocationNameModel? // 드래그된 아이템

    init(ridingViewModel: RidingViewModel) {
        self.ridingViewModel = ridingViewModel
    }
    
    var body: some View {
        VStack(alignment: .leading,spacing: 0) {
            
            header
            
            Divider()
                .frame(maxWidth:.infinity)
                .frame(height:1)
                .foregroundColor(.gray1)
                .padding(.horizontal, 16)
//                .padding(.bottom, 20)
            
            // 컨텐츠
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    startPointView
                        .padding(.top, 20)
                    
                    if ridingViewModel.routeLocation.count <= 2 {
                        Spacer()
                            .frame(height: 14)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(ridingViewModel.routeLocation.dropFirst().dropLast()), id: \.sequenceNum) { item in
                                spotRow(item: item)
                                    .onDrag({
                                        self.draggedItem = item
                                        return NSItemProvider(item: nil, typeIdentifier: String(item.sequenceNum))
                                    }) // : onDrag
                                    .onDrop(
                                        of: [String(item.sequenceNum)],
                                        delegate: RouteLocationDropDelegate(
                                            ridingViewModel: ridingViewModel,
                                            currentItem: item,
                                            draggedItem: $draggedItem
                                        )
                                    ) // : onDrop
                            } // : ForEach
                        } // : VStack
                        .padding(.leading, 54)
                        .padding(.trailing, 16)
                        .padding(.vertical, 12)
                        .overlay {
                            let middleCount = max(0, ridingViewModel.routeLocation.count - 2)
                            let lineHeight = Double((middleCount * 66) + (middleCount + 1) * 8)
                            Divider()
                                .frame(
                                    width: 1, 
                                    height: lineHeight)
                                .background(Color(hex: "#EDF0F6"))
                                .position(x: 32, y: 6 + (lineHeight/2))

                        } // : overlay
                        .overlay {
                            let middleCount = max(0, ridingViewModel.routeLocation.count - 2)
                            ForEach(1...middleCount, id: \.self) { index in
                                Text("\(index)")
                                    .foregroundColor(.white)
                                    .font(.pretendardMedium(size: 10.5))
                                    .frame(height:17)
                                    .padding(.horizontal, 6.5)
                                    .padding(.vertical, 0.5)
                                    .background(Color(hex: "#2C333A"))
                                    .clipShape(Circle())
                                    .position(x: 32, y: 45 + Double((index-1) * (56+18)))
                            } // : ForEach
                        } // : overlay
                    } // : if - else
                    
                    endPointView
                } // : VStack
            } // : ScrollView
            
            Spacer()
        } // : VStack
        .padding(.top, 8)
        .background(.white)
    }
    
    //MARK: - View
    
    private var header: some View {
        HStack(alignment: .top , spacing: 0) {
            Text("라이딩 코스")
                .foregroundColor(.gray6)
                .font(.pretendardSemiBold(size: 20))
                .padding(.leading, 17)
            
            Spacer()
            
            Button(action:{
                if let lastLocation = ridingViewModel.routeLocation.last {
                    navigationManager.push(.SpotAddView(
                        lat: lastLocation.lat,
                        lon: lastLocation.lon
                    ))
                }
            }){
                Image("icon_plus")
                Text("스팟 추가")
                    .foregroundColor(.gray6)
                    .font(.pretendardSemiBold(size: 16))
            }
            .padding(.top, 1)
            .padding(.trailing, 16)
        } // : HStack
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 19)
    } // : header
    
    private var startPointView: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 1.72) {
                Image("icon_point")
                    .padding(.top, 1.5)
                
                Text("출발")
                    .foregroundColor(Color.main)
                    .font(.pretendardRegular(size: 12))
            } // : VStack
            .padding(.horizontal, 4)
            .padding(.trailing, 6)
            
            Text(ridingViewModel.routeLocation.first?.name.truncated(limit: 21) ?? "출발지")
                .foregroundColor(.gray6)
                .font(.pretendardSemiBold(size: 16))
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
        } // : HStack
        .padding(.horizontal, 16)
    } // : startpointView
    
    private var endPointView: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 2.96) {
                Image("icon_destination")
                    .padding(.top, 2)
                
                Text("도착")
                    .foregroundColor(Color.main)
                    .font(.pretendardRegular(size: 12))
            } // : VStack
            .padding(.horizontal, 4)
            .padding(.trailing, 6)
            
            Text(ridingViewModel.routeLocation.last?.name.truncated(limit: 21) ?? "도착지")
                .foregroundColor(.gray6)
                .font(.pretendardSemiBold(size: 16))
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
        } // : HStack
        .padding(.horizontal, 16)
    } // : endPointView
    
    @ViewBuilder
    private func spotRow(item: LocationNameModel) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing:2) {
                Text(item.name.truncated(limit: 16))
                    .foregroundColor(.gray6)
                    .font(.pretendardSemiBold(size: 16))
                    .frame(height:22)
                
                Text(ridingViewModel.matchTitle(item.typeCode))
                    .foregroundColor(.gray4)
                    .font(.pretendardRegular(size: 14))
                    .frame(height:20)
            } // : VStack
            .padding(.vertical, 11)
            
            Spacer()
            
            Button(action:{
                modalManager.showModal(
                    title: "스팟을 삭제할까요?",
                    subText: "제작 중인 코스에서 스팟이 삭제돼요",
                    activeText: "삭제하기",
                    showView: .ridingView,
                    onCancel: {
                        print("취소됨")
                    },
                    onActive: {
                        print("삭제됨")
                    }
                )
            }){
                Text("삭제")
                    .foregroundColor(.gray4)
                    .font(.pretendardMedium(size: 14))
                    .padding(.vertical, 8)
                    .padding(.horizontal,12)
                    .background(Color.gray1)
                    .cornerRadius(8)
            }
            .padding(.vertical, 18)
        } // : HStack
        .padding(.horizontal, 14)
        .background(.white)
        .cornerRadius(10)
        .shadow(color: Color(red: 0.84, green: 0.87, blue: 0.92).opacity(0.4),
                radius: 3.5, x: 1, y: 1)
    } // : spotRow
    
}

#Preview {
    SheetContentView(ridingViewModel: RidingViewModel(routeRepository: RouteRepository()))
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
