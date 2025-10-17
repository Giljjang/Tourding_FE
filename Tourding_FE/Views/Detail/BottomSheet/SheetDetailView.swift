//
//  SheetDetailView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import SwiftUI

struct SheetDetailView: View {
    @EnvironmentObject var navigationManager: NavigationManager
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
                        
                        //contenttypeid 별 뷰
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
        .interactiveDismissDisabled(false) // 네이티브 스와이프 백 제스처 활성화
        .gesture(
            DragGesture()
                .onEnded { value in
                    // 왼쪽에서 오른쪽으로 스와이프 감지
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        print("👈 스와이프 뒤로가기 감지")
                        navigationManager.pop()
                    }
                }
        ) // :gesture
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
                        fontSize: 15,
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
                    let text = "쉬는 날: \(restdate)\n이용시간: \(usetime)"
                    
                    DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
                } else {
                    DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(restdate), type: nil)
                }
            }
            
            //주차시설 parking
            if let parking = detailViewModel.detailData?.parking,
               parking != "" {
                let text = "주차시설: \(parking)"
                DetailInfoLine(image: "icon_parking", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            //이용시기 useseason
            if let useseason = detailViewModel.detailData?.useseason,
               useseason != "" {
                let text = "이용시기: \(useseason)"
                DetailInfoLine(image: "icon_time-of-use", text: detailViewModel.formatOverview(text), type: nil)
            }
            
        }
        .padding(.bottom, 10)
    }
    
    // 문화시설
    private var cultureInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            //문의 및 안내 infocenterculture
            if let infocenterculture = detailViewModel.detailData?.infocenterculture,
               infocenterculture != "" {
                let text = "문의 및 안내: \(infocenterculture)"
                DetailInfoLine(image: "icon_Phone number", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 주차시설/주차요금 parkingculture/parkingfee
            if let parkingculture = detailViewModel.detailData?.parkingInfo?.parkingculture,
               parkingculture != "" {
                let parkingculture2 = "주차시설: \(parkingculture)"
                
                if let parkingfee = detailViewModel.detailData?.parkingInfo?.parkingfee,
                   parkingfee != "" {
                    let text = "주차시설: \(parkingculture)\n주차요금: \(parkingfee)"
                    
                    DetailInfoLine(image: "icon_parking", text: detailViewModel.formatOverview(text), type: nil)
                } else {
                    DetailInfoLine(image: "icon_parking", text: detailViewModel.formatOverview(parkingculture2), type: nil)
                }
            }
            
            // 쉬는 날 restdateculture
            if let restdateculture = detailViewModel.detailData?.restdateculture,
               restdateculture != "" {
                let text = "쉬는 날: \(restdateculture)"
                DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 이용요금 usefee
            if let usefee = detailViewModel.detailData?.usefee,
               usefee != "" {
                let text = "이용요금: \(usefee)"
                DetailInfoLine(image: "icon_Price", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 규모 scale
            if let scale = detailViewModel.detailData?.scale,
               scale != "" {
                let text = "규모: \(scale)"
                DetailInfoLine(image: "icon_scale", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 관람소요시간 spendtime
            if let spendtime = detailViewModel.detailData?.spendtime,
               spendtime != "" {
                let text = "관람소요시간: \(spendtime)"
                
                DetailInfoLine(image: "icon_waiting-time", text: detailViewModel.formatOverview(text), type: nil)
            }
        }
    }
    
    // 행사공연축제
    private var festivalInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 예매처 bookingplace
            if let bookingplace = detailViewModel.detailData?.bookingplace,
               bookingplace != "" {
                let text = "예매처: \(bookingplace)"
                DetailInfoLine(image: "icon_reservation", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 할인정보 discountinfofestival
            if let discountinfofestival = detailViewModel.detailData?.discountinfofestival,
               discountinfofestival != "" {
                let text = "할인정보: \(discountinfofestival)"
                
                DetailInfoLine(image: "icon_discount-information", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 행사종료일/ 행사시작일 eventenddate/eventstartdate
            if let eventenddate = detailViewModel.detailData?.festivalDurationInfo?.eventenddate,
               eventenddate != "" {
                
                if let eventstartdate = detailViewModel.detailData?.festivalDurationInfo?.eventstartdate,
                   eventstartdate != "" {
                    let text = "행사종료일: \(eventenddate)\n행사시작일: \(eventstartdate)"
                    
                    DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
                } else {
                    let text = "행사종료일: \(eventenddate)"
                    DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
                }
            }
            
            // 행사장소 eventplace
            if let eventplace = detailViewModel.detailData?.eventplace,
               eventplace != "" {
                let text = "행사장소: \(eventplace)"
                DetailInfoLine(image: "Icon_event-spot", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 공연시간 playtime
            if let playtime = detailViewModel.detailData?.playtime,
               playtime != "" {
                let text = "공연시간: \(playtime)"
                DetailInfoLine(image: "icon_performance-time", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 행사 프로그램 program
            if let program = detailViewModel.detailData?.program,
               program != "" {
                let text = "프로그램: \(program)"
                DetailInfoLine(image: "icon_event-program", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 관람소요 시간 spendtimefestival
            if let spendtimefestival = detailViewModel.detailData?.spendtimefestival,
               spendtimefestival != "" {
                let text = "관람소요시간: \(spendtimefestival)"
                DetailInfoLine(image: "icon_waiting-time", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 이용 요금 usetimefestival
            if let usetimefestival = detailViewModel.detailData?.usetimefestival,
               usetimefestival != "" {
                let text = "이용요금: \(usetimefestival)"
                DetailInfoLine(image: "icon_Price", text: detailViewModel.formatOverview(text), type: nil)
            }
        }
    }
    
    // 여행코스
    private var travelCourseInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 코스 총 거리 distance
            if let distance = detailViewModel.detailData?.distance,
               distance != "" {
                let text = "코스 총 거리: \(distance)"
                DetailInfoLine(image: "icon_total distance-course", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 문의 및 안내 infocentertourcourse
            if let infocentertourcourse = detailViewModel.detailData?.infocentertourcourse,
               infocentertourcourse != "" {
                let text = "문의 및 안내: \(infocentertourcourse)"
                DetailInfoLine(image: "icon_Phone number", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 코스 일정 schedule
            if let schedule = detailViewModel.detailData?.schedule,
               schedule != "" {
                let text = "코스 일정: \(schedule)"
                
                DetailInfoLine(image: "icon_course-schedule", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 코스총소요시간 taketime
            if let taketime = detailViewModel.detailData?.taketime,
               taketime != "" {
                let text = "코스 총 소요시간: \(taketime)"
                DetailInfoLine(image: "icon_waiting-time", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 코스테마 theme
            if let theme = detailViewModel.detailData?.theme,
               theme != "" {
                let text = "코스 테마: \(theme)"
                DetailInfoLine(image: "icon_course-theme", text: detailViewModel.formatOverview(text), type: nil)
            }
        }
    }
    
    // 레포츠
    private var leisureInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            //개장 기간/ 쉬는날/ 이용시간 openperiod/restdateleports/usetimeleports
            if let openperiod = detailViewModel.detailData?.leportsOpenInfo?.openperiod,
               openperiod != "" {
                
                if let restdateleports = detailViewModel.detailData?.leportsOpenInfo?.restdateleports,
                   restdateleports != "" {
                    let text = "개장 기간: \(openperiod)\n쉬는 날: \(restdateleports)"
                    
                    if let usetimeleports = detailViewModel.detailData?.leportsOpenInfo?.usetimeleports,
                       usetimeleports != "" {
                        let text2 = "개장 기간: \(openperiod)\n쉬는 날: \(restdateleports)\n이용시간:\(usetimeleports)"
                        
                        DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text2), type: nil)
                    } else {
                        DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
                    }
                } else {
                    let text = "개장 기간: \(openperiod)"
                    DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
                }
            }
            
            //주차요금/주차시설 parkingfeeleports/parkingleports
            if let parkingfeeleports = detailViewModel.detailData?.leportsParkingInfo?.parkingfeeleports,
               parkingfeeleports != "" {
                
                if let parkingleports = detailViewModel.detailData?.leportsParkingInfo?.parkingleports,
                   parkingleports != "" {
                    let text = "주차요금: \(parkingfeeleports)\n 주차시설: \(parkingleports)"
                    
                    DetailInfoLine(image: "icon_parking", text: detailViewModel.formatOverview(text), type: nil)
                } else {
                    let text = "주차요금: \(parkingfeeleports)"
                    DetailInfoLine(image: "icon_parking", text: detailViewModel.formatOverview(text), type: nil)
                }
            }
            
            // 예약안내 reservation
            if let reservation = detailViewModel.detailData?.reservation,
               !reservation.isEmpty {
                if reservation.contains("http") {
                    DetailInfoLine(
                        image: "icon_reservation",
                        text: detailViewModel.formatOverview(detailViewModel.extractURL(from: reservation) ?? reservation),
                        type: "link")
                } else {
                    DetailInfoLine(
                        image: "icon_reservation",
                        text: detailViewModel.formatOverview("예약안내: \(reservation)"),
                        type: nil)
                }
            }
            
            //규모 scaleleports
            if let scaleleports = detailViewModel.detailData?.scaleleports,
               scaleleports != "" {
                let text = "규모: \(scaleleports)"
                DetailInfoLine(image: "icon_scale", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            //입장료 usefeeleports
            if let usefeeleports = detailViewModel.detailData?.usefeeleports,
               usefeeleports != "" {
                let text = "입장료: \(usefeeleports)"
                DetailInfoLine(image: "icon_Price", text: detailViewModel.formatOverview(text), type: nil)
            }
            
        }
    }
    
    // 숙박
    private var lodgingInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            //입실 시간/ 퇴실 시간 checkintime/checkouttime
            if let checkintime = detailViewModel.detailData?.checkInOutInfo?.checkintime,
               checkintime != "" {
                
                if let checkouttime = detailViewModel.detailData?.checkInOutInfo?.checkouttime,
                   checkouttime != "" {
                    let text = "입실시간: \(checkintime)\n퇴실시간: \(checkouttime)"
                    
                    DetailInfoLine(image: "icon_check-in-time", text: detailViewModel.formatOverview(text), type: nil)
                } else {
                    let text = "입실시간: \(checkintime)"
                    DetailInfoLine(image: "icon_check-in-time", text: detailViewModel.formatOverview(text), type: nil)
                }
            }
            
            // 주차 시설 parkinglodging
            if let parkinglodging = detailViewModel.detailData?.parkinglodging,
               parkinglodging != "" {
                let text = "주차시설: \(parkinglodging)"
                DetailInfoLine(image: "icon_parking", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 예약안내 홈페이지 reservationurl
            if let reservationurl = detailViewModel.detailData?.reservationurl,
               reservationurl != "" {
                let text = detailViewModel.extractURL(from: reservationurl)
                
                DetailInfoLine(image: "icon_reservation", text: detailViewModel.formatOverview(text), type: "link")
            }
            
            // 바비큐장 여부 barbecue
            if let barbecue = detailViewModel.detailData?.barbecue,
               barbecue != "" {
                let text = "바비큐장: \(barbecue)"
                DetailInfoLine(image: "icon_barbecue-status", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 자전거 대여 여부 bicycle
            if let bicycle = detailViewModel.detailData?.bicycle,
               bicycle != "" {
                let text = "자전거 대여: \(bicycle)"
                DetailInfoLine(image: "icon_bicycle-rental-status", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            //캠프파이어 여부 campfire
            if let campfire = detailViewModel.detailData?.campfire,
               campfire != "" {
                let text = "캠프파이어: \(campfire)"
                DetailInfoLine(image: "icon_campfire", text: detailViewModel.formatOverview(text), type: nil)
            }
        }
    }
    
    // 쇼핑
    private var shoppingInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            //문의 및 안내 infocentershopping
            if let infocentershopping = detailViewModel.detailData?.infocentershopping,
               infocentershopping != "" {
                let text = "문의 및 안내: \(infocentershopping)"
                DetailInfoLine(image: "icon_Phone number", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 영업시간/ 쉬는 날 opentime/restdateshopping
            if let opentime = detailViewModel.detailData?.storeOpenInfo?.opentime,
               opentime != "" {
                
                if let restdateshopping = detailViewModel.detailData?.storeOpenInfo?.restdateshopping,
                   restdateshopping != "" {
                    let text = "영업시간: \(opentime)\n쉬는 날: \(restdateshopping)"
                    
                    DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
                } else {
                    let text = "영업시간: \(opentime)"
                    DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
                }
            }
            
            // 주차시설 parkingshopping
            if let parkingshopping = detailViewModel.detailData?.parkingshopping,
               parkingshopping != "" {
                let text = "주차시설: \(parkingshopping)"
                DetailInfoLine(image: "icon_parking", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 화장실 설명 restroom
            if let restroom = detailViewModel.detailData?.restroom,
               restroom != "" {
                let text = "화장실: \(restroom)"
                DetailInfoLine(image: "icon_toilet (2)", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 매장 안내 shopguide
            if let shopguide = detailViewModel.detailData?.shopguide,
               shopguide != "" {
                let text = "매장 안내: \(shopguide)"
                DetailInfoLine(image: "icon_store-information", text: detailViewModel.formatOverview(text), type: nil)
            }
        }
    }
    
    // 음식점
    private var foodInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 영업 시간 opentimefood
            if let opentimefood = detailViewModel.detailData?.foodOpenInfo?.opentimefood,
               opentimefood != "" {
                let text = "영업 시간: \(opentimefood)"
                DetailInfoLine(image: "icon_Operating hours", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 포장 가능 packing
            if let packing = detailViewModel.detailData?.packing,
               packing != "" {
                let text = "포장: \(packing)"
                DetailInfoLine(image: "icon_takeout", text: detailViewModel.formatOverview(text), type: nil)
            }
            
            // 주차시설 parkingfood
            if let parkingfood = detailViewModel.detailData?.parkingfood,
               parkingfood != "" {
                let text = "주차시설: \(parkingfood)"
                DetailInfoLine(image: "icon_parking", text: detailViewModel.formatOverview(text), type: nil)
            }
             
            // 취급 메뉴 treatmenu
            if let treatmenu = detailViewModel.detailData?.treatmenu,
               treatmenu != "" {
                DetailInfoLine(image: "icon_restaurant", text: detailViewModel.formatOverview(treatmenu), type: nil)
            }
        }
    }
}
