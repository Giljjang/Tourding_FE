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
                        if let type = detailViewModel.mapTypeCodeToEnum() {
                            switch type {
                            case .touristSpot:
                                tourDetailInfo
                            case .culturalFacility:
                                cultureInfo
                            case .festival:
                                festivalInfo
                            case .travelCourse:
                                travelCourseInfo
                            case .leisure:
                                leisureInfo
                            case .lodging:
                                lodgingInfo
                            case .shopping:
                                shoppingInfo
                            case .restaurant:
                                foodInfo
                            }
                        }
                        
                        
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
            
            //쉬는날/이용시간 restdate/usetime
            if let restdate = detailViewModel.detailData?.openInfo?.restdate,
               restdate != "" {
                
                if let usetime = detailViewModel.detailData?.openInfo?.usetime,
                   usetime != "" {
                    let text = "\(restdate)\n\(usetime)"
                    
                    DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
                } else {
                    DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(restdate), type: nil)
                }
            }
            
            //주차시설 parking
            if let parking = detailViewModel.detailData?.parking,
               parking != "" {
                DetailInfoLine(image: "icon_parking", text: detailViewModel.formatOverview(parking), type: nil)
            }
            
            //이용시기 useseason
            if let useseason = detailViewModel.detailData?.useseason,
               useseason != "" {
                DetailInfoLine(image: "icon_time-of-use", text: detailViewModel.formatOverview(useseason), type: nil)
            }
            
        }
        .padding(.bottom, 10)
    }
    
    // 문화시설
    private var cultureInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            //문의 및 안내
            
            // 주차시설/주차요금
            
            // 쉬는 날
            
            // 이용요금
            
            // 규모
            
            // 관람소요시간
        }
        .padding(.bottom, 10)
    }
    
    // 행사공연축제
    private var festivalInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            //예매처
            
            // 할인정보
            
            // 행사종료일/ 행사시작일
            
            // 행사장소
            
            // 공연시간
            
            // 행사 프로그램
            
            // 관람소요 시간
            
            // 이용 요금
        }
        .padding(.bottom, 10)
    }
    
    // 여행코스
    private var travelCourseInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 코스 총 거리
            
            // 문의 및 안내
            
            // 코스 일정
            
            // 코스총소요시간
            
            // 코스테마
        }
        .padding(.bottom, 10)
    }
    
    // 레포츠
    private var leisureInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            //개강 기간/ 쉬는날/ 이용시간
            
            //주차요금/주차시설
            
            // 예약안내
            
            //규모
            
            //입장료
            
        }
        .padding(.bottom, 10)
    }
    
    // 숙박
    private var lodgingInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            //입실 시간/ 퇴실 시간
            
            // 주차 시설
            
            // 예약안내 홈페이지
            
            // 바비큐장 여부
            
            // 자전거 대여 여부
            
            //캠프파이어 여부
        }
        .padding(.bottom, 10)
    }
    
    // 쇼핑
    private var shoppingInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            //문의 및 안내
            
            // 영업시간/ 쉬는 날
            
            // 주차시설
            
            // 화장실 설명
            
            // 매장 안내
        }
        .padding(.bottom, 10)
    }
    
    // 음식점
    private var foodInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 영업 시간
            
            // 포장 가능
            
            // 주차시설
            
            // 취급 메뉴
        }
        .padding(.bottom, 10)
    }
}
