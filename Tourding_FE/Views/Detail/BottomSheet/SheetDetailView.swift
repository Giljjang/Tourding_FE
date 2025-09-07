//
//  SheetDetailView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import SwiftUI

struct SheetDetailView: View {
    @ObservedObject private var detailViewModel: DetailSpotViewModel
    
    init(detailViewModel: DetailSpotViewModel) {
        self.detailViewModel = detailViewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    
                    if detailViewModel.mapTypeCodeToImageName() != "" {
                        tag
                            .padding(.bottom, 4)
                    }
                    
                    // 제목
                    titleText
                        .padding(.bottom, 14)
                    
                    divider
                    
                    // 아래 아이콘 섹션
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // 공통 정보
                        commonDetailInfo
                        
                        //typeCode별
                        
                    } // : VStack
                    .padding(.vertical, 22)
                    
                    // 스팟 안내 - 더보기
                    overviewIfletView
                    
                    //숙소일 경우 환불규정 - 더보기
                    refundregulationView
                    
                    bottomSpacer
                    
                } // : VStack
            } // : ScrollView
            .background(.white)
            .padding(.horizontal, 16)
            
            Spacer()
        } // : VStack
        .padding(.top, 8)
    }
    
    //MARK: - View
    
    private var tag: some View {
        // 태그
        HStack(alignment: .center, spacing: 2) {
            Image(detailViewModel.mapTypeCodeToImageName())
                .padding(.vertical, 6)
                .padding(.leading, 6)
            
            Text(detailViewModel.mapTypeCodeToName())
                .foregroundColor(.gray4)
                .font(.pretendardMedium(size: 14))
                .padding(.trailing, 12)
        } // : HStack
        .background(Color.gray1)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 6)
    }
    
    private var titleText: some View {
        Text(detailViewModel.detailData?.title ?? "")
            .foregroundColor(.gray6)
            .font(.pretendardSemiBold(size: 24))
            .frame(height: 34)
    }
    
    private var divider: some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(maxWidth: .infinity)
            .frame(height: 1)
            .background(Color.gray1)
    }
    
    private var refundregulationView: some View {
        Group {
            if let refundregulation = detailViewModel.detailData?.refundregulation,
               detailViewModel.mapTypeCodeToName() == "숙박",
               !refundregulation.isEmpty
            {
                VStack(alignment: .leading, spacing: 0) {
                    divider
                        .padding(.bottom, 18)
                    
                    Text("환불 규정")
                        .foregroundColor(.gray5)
                        .font(.pretendardMedium(size: 20))
                        .padding(.bottom, 8)
                    
                    ExpandableTextView(
                        text: refundregulation,
                        lineLimit: 5,
                        font: .pretendardRegular(size: 15),
                        color: .gray5
                    )
                    .padding(.bottom, 18)
                } // : VStack
            } // : if let refundregulation
        } // : Group
    }
    
    private var overviewIfletView : some View {
        Group {
            if let overview = detailViewModel.detailData?.overview {
                VStack(alignment: .leading, spacing: 0) {
                    divider
                        .padding(.bottom, 18)
                    
                    Text("스팟 안내")
                        .foregroundColor(.gray5)
                        .font(.pretendardMedium(size: 20))
                        .padding(.bottom, 8)
                    
                    ExpandableTextView(
                        text: detailViewModel.formatOverview(overview),
                        lineLimit: 5,
                        font: .pretendardRegular(size: 15),
                        color: .gray5
                    )
                    .padding(.bottom, 18)
                }// : VStack
            }
        } // : Group
    }
    
    private var bottomSpacer: some View {
        if detailViewModel.currentPosition == .large {
            Spacer()
                .frame(height: 300)
        } else {
            Spacer()
                .frame(height: 500)
        }
    }
    
    private func detailInfoLine(image: String, text: String, type: String? = nil)-> some View {
        HStack(spacing: 8) {
            Image(image)
            
            if let type = type,
               type == "link"
            {
                Link("\(text)", destination: URL(string: text)!)
                    .font(.pretendardRegular(size: 15))
            } else {
                Text(text)
                    .foregroundColor(.gray5)
                    .font(.pretendardRegular(size: 15))
            }
        } // : HStack
    }
    
    private var commonDetailInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 주소 - 더보기 address
            if let address = detailViewModel.detailData?.address,
               address != "" {
                DetailInfoLine(image: "icon_Address", text: address, type: nil)
            }
            
            // 전화번호 tel
            if let tel = detailViewModel.detailData?.tel,
               tel != "" {
                DetailInfoLine(image: "icon_Phone number", text: tel, type: nil)
            }
            
            // 홈페이지 주소 homepage
            if let homepage = detailViewModel.detailData?.homepage,
               homepage != "",
               let link = detailViewModel.extractURL(from:homepage)
            {
                DetailInfoLine(image: "icon_Web site", text: link, type: "link")
            }
        }
        .padding(.bottom, 10)
    }
    
    //관광지
    private var tourDetailInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            //개장일/쉬는날/이용시간
            
        }
        .padding(.bottom, 10)
    }
}
