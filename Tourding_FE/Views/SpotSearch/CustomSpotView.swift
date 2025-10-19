//
//  CustomSpotView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/7/25.
//

// 이건 스팟 검색 첫 화면
import SwiftUI

// MARK: - 동적 스팟 리스트 뷰
struct CustomSpotView: View {
    let spots: [SpotData]
    let errorMessage: String?
    let navigationDetail: (String, String) -> Void
    let isVertical: Bool?
    
    var body: some View {
        if isVertical! {
            spotListViewVertical
        } else {
            spotListView
        }
    }
    
    // MARK: - 스팟 리스트
    private var spotListView: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(spots) { spot in
                SpotCardView(spot: spot)
                    .onTapGesture {
                        navigationDetail(spot.contentid, spot.contenttypeid)
                    } // : onTapGesture
            }
        }
        .frame(maxHeight: 290)
        .background(Color.gray1)
    }
    
    // MARK: - 스팟 리스트 (새로운 Vertical)
    private var spotListViewVertical: some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(spots) { spot in
                SpotCardView2(spot: spot)
                    .onTapGesture {
                        navigationDetail(spot.contentid, spot.contenttypeid)
                    }
            }
        }
        .background(Color.white)
    }
}


// MARK: - 기본 스팟 카드 뷰
struct SpotCardView: View {
    let spot: SpotData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 이미지 섹션
            ZStack(alignment: .topLeading) {
                spotImage
                categoryTag
                    .padding(12)
            }
            
            // 텍스트 정보 섹션
            VStack(alignment: .leading, spacing: 6) {
                Text(truncatedAddress(spot.title))
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundColor(.gray6)
                    .lineLimit(1)
                    .truncationMode(.tail)   // ✅ 뒤에 … 처리
                
                HStack(spacing: 3) {
                    Image("WhiteIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12)
                    
                    Text(spot.addr1.split(separator: " ").prefix(3).joined(separator: " "))
                        .font(.pretendardRegular(size: 14))
                        .foregroundColor(.gray4)
                        .lineLimit(1)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 5)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.02), radius: 20, x: 0, y: 6)
    }
    
    // MARK: - 스팟 이미지
    private var spotImage: some View {
        Group {
            if !spot.firstimage.isEmpty {
                AsyncImage(url: URL(string: spot.firstimage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 170, height: 170)
//                        .frame(maxWidth: 204, maxHeight: 204)
                        .background(.white)
                } placeholder: {
                    defaultImage
                }
            } else if !spot.firstimage2.isEmpty {
                AsyncImage(url: URL(string: spot.firstimage2)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    defaultImage
                }
            } else {
                defaultImage
            }
        }
        .frame(width: 170, height: 170)  // 고정 크기 설정
        .background(Color.white)  // 전체 배경도 하얀색
        .clipped()
        .cornerRadius(14)
    }
    
    // MARK: - 기본 이미지
    private var defaultImage: some View {
        Image("common")
            .resizable()
            .scaledToFill()
            .frame(height: 170)
    }
    
    // MARK: - 카테고리 태그
    private var categoryTag: some View {
        HStack(spacing: 2) {
            Image(categoryIcon)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 18, maxHeight: 18)
            
            Text(categoryText)
                .font(.pretendardRegular(size: 12))
                .foregroundColor(.gray5)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(Color.white)
        .cornerRadius(8)
    }
    
    //MARK: - 글자 자르기
    private func truncatedAddress(_ addr: String, limit: Int = 10) -> String {
        let trimmed = addr.split(separator: " ").prefix(3).joined(separator: " ")
        if trimmed.count > limit {
            let endIndex = trimmed.index(trimmed.startIndex, offsetBy: limit)
            return String(trimmed[..<endIndex]) + "…"
        } else {
            return trimmed
        }
    }
    
    // MARK: - 카테고리별 아이콘과 텍스트
    private var categoryIcon: String {
        switch spot.typeCode {
        case "A01": return "nature" // 자연
        case "A02": return "humon" // 문화,예술,역사
        case "A03": return "leport" // 레포츠
        case "A04": return "shoping" // 쇼핑
        case "A05": return "food" // 음식
        case "B02": return "sleep" // 숙박
        default: return "humon"
        }
    }
    
    private var categoryText: String {
        switch spot.typeCode {
        case "A01": return "자연" // 자연
        case "A02": return "인문(문화/예술/역사)" // 문화,예술,역사
        case "A03": return "레포츠" // 레포츠
        case "A04": return "쇼핑" // 쇼핑
        case "A05": return "음식" // 음식
        case "B02": return "숙박" // 숙박
        default: return "관광지"
        }
    }
}

// MARK: - 더보기 스팟 카드 뷰
struct SpotCardView2: View {
    let spot: SpotData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            spotImage
            
            // 텍스트 정보 섹션
            VStack(alignment: .leading, spacing: 6) {
                Text(truncatedAddress(spot.title))
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundColor(.gray6)
                    .lineLimit(1)
                    .truncationMode(.tail)   // ✅ 뒤에 … 처리
                
                Text(spot.addr1.split(separator: " ").prefix(3).joined(separator: " "))
                    .font(.pretendardRegular(size: 14))
                    .foregroundColor(.gray4)
                    .lineLimit(1)
                
                Text(categoryText)
                    .font(.pretendardRegular(size: 12))
                    .foregroundColor(.gray4)
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 2)
                    .background(Color.gray1)
                    .cornerRadius(6)
            }
            .padding(.top, 10)
            .padding(.bottom, 5)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.02), radius: 20, x: 0, y: 6)
    }
    
    // MARK: - 스팟 이미지
    private var spotImage: some View {
        Group {
            if !spot.firstimage.isEmpty {
                AsyncImage(url: URL(string: spot.firstimage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 170, height: 170)
//                        .frame(maxWidth: 204, maxHeight: 204)
                        .background(.white)
                } placeholder: {
                    defaultImage
                }
            } else if !spot.firstimage2.isEmpty {
                AsyncImage(url: URL(string: spot.firstimage2)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    defaultImage
                }
            } else {
                defaultImage
            }
        }
        .frame(width: 170, height: 170)  // 고정 크기 설정
        .background(Color.white)  // 전체 배경도 하얀색
        .clipped()
        .cornerRadius(14)
    }
    
    // MARK: - 기본 이미지
    private var defaultImage: some View {
        Image("common")
            .resizable()
            .scaledToFill()
            .frame(height: 170)
    }

    //MARK: - 글자 자르기
    private func truncatedAddress(_ addr: String, limit: Int = 10) -> String {
        let trimmed = addr.split(separator: " ").prefix(3).joined(separator: " ")
        if trimmed.count > limit {
            let endIndex = trimmed.index(trimmed.startIndex, offsetBy: limit)
            return String(trimmed[..<endIndex]) + "…"
        } else {
            return trimmed
        }
    }
    
    // MARK: - 카테고리별 텍스트
    
    private var categoryText: String {
        switch spot.typeCode {
        case "A01": return "자연" // 자연
        case "A02": return "인문(문화/예술/역사)" // 문화,예술,역사
        case "A03": return "레포츠" // 레포츠
        case "A04": return "쇼핑" // 쇼핑
        case "A05": return "음식" // 음식
        case "B02": return "숙박" // 숙박
        default: return "관광지"
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleSpots = [
        SpotData(
            title: "해피치즈스마일",
            addr1: "경북 경산시 조영동",
            typeCode: "A02",
            contentid: "1",
            contenttypeid: "39",
            firstimage: "",
            firstimage2: "",
            mapx: "128.123",
            mapy: "35.456"
        ),
//        SpotData(
//            title: "경산 한옥마을",
//            addr1: "경북 경산시 중앙동",
//            typeCode: "A02",
//            contentid: "2",
//            contenttypeid: "12",
//            firstimage: "https://example.com/image.jpg",
//            firstimage2: "",
//            mapx: "128.124",
//            mapy: "35.457"
//        )
    ]
    
    ScrollView {
        CustomSpotView(spots: sampleSpots, errorMessage: nil,  navigationDetail: { lon, lat in
            print("경도: \(lon), 위도: \(lat)")
        }, isVertical: false)
            .padding()
    }
    .background(Color.gray1)
}

