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
    
    var body: some View {
            spotListView
    }
    
    // MARK: - 스팟 리스트
    private var spotListView: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(spots) { spot in
                SpotCardView(spot: spot)
            }
        }
        .frame(maxHeight: 290)
    }
}

// MARK: - 개별 스팟 카드 뷰
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
            VStack(alignment: .leading, spacing: 10) {
                Text(spot.title)
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundColor(.gray6)
                    .lineLimit(2)
                
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
            .padding(.top, 17)
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
                        .frame(maxWidth: 204, maxHeight: 204)
                } placeholder: {
                    defaultImage
                }
            } else if !spot.firstimage2.isEmpty {
                AsyncImage(url: URL(string: spot.firstimage2)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    defaultImage
                }
            } else {
                defaultImage
            }
        }
        .frame(height: 180)
        .clipped()
        .cornerRadius(14)
    }
    
    // MARK: - 기본 이미지
    private var defaultImage: some View {
        Image("common")
            .resizable()
            .scaledToFill()
            .frame(height: 204)
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
    
    // MARK: - 카테고리별 아이콘과 텍스트
    private var categoryIcon: String {
        switch spot.contenttypeid {
        case "12": return "humon" // 관광지
        case "14": return "humon" // 문화시설
        case "15": return "humon" // 축제공연행사
        case "25": return "humon" // 여행코스
        case "28": return "leport" // 레포츠
        case "32": return "sleep" // 숙박
        case "38": return "shoping" // 쇼핑
        case "39": return "food" // 음식점
        default: return "관광지"
        }
    }
    
    private var categoryText: String {
        switch spot.contenttypeid {
        case "12": return "관광지"
        case "14": return "문화시설"
        case "15": return "축제행사"
        case "25": return "여행코스"
        case "28": return "레포츠"
        case "32": return "숙박"
        case "38": return "쇼핑"
        case "39": return "음식"
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
            typeCode: "A01",
            contentid: "1",
            contenttypeid: "39",
            firstimage: "",
            firstimage2: "",
            mapx: "128.123",
            mapy: "35.456"
        ),
        SpotData(
            title: "경산 한옥마을",
            addr1: "경북 경산시 중앙동",
            typeCode: "A01",
            contentid: "2",
            contenttypeid: "12",
            firstimage: "https://example.com/image.jpg",
            firstimage2: "",
            mapx: "128.124",
            mapy: "35.457"
        )
    ]
    
    ScrollView {
        CustomSpotView(spots: sampleSpots, errorMessage: nil)
            .padding()
    }
    .background(Color.gray1)
}

