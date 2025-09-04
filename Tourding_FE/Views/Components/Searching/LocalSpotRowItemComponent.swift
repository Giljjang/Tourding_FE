//
//  LocalSpotRowItemComponent.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/31/25.
//

import SwiftUI

struct LocalSpotRowItemComponent: View {
    let spot: SpotData

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // 좌측 텍스트 블록
                VStack(alignment: .leading, spacing: 0) {

                    // 카테고리 칩 - typeCode를 사용하여 카테고리 결정
                    CategoryChip(typeCode: spot.typeCode)
                        .padding(.bottom, 6)

                    // 타이틀
                    Text(spot.title)
                        .font(.pretendardSemiBold(size: 16))
                        .foregroundColor(.gray6)
                        .lineLimit(1)
                        .padding(.bottom, 3)

                    // 주소
                    if !spot.addr1.isEmpty {
                        Text(spot.addr1.split(separator: " ").prefix(3).joined(separator: " "))
                            .font(.pretendardRegular(size: 14))
                            .foregroundColor(.gray4)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer(minLength: 0)

                // 우측 썸네일
                let url = URL(string: spot.firstimage.isEmpty ? spot.firstimage2 : spot.firstimage)

                Group {
                    if let url {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                            default:
                                Image("bicycle")
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                            }
                        }
                    } else {
                        Image("bicycle")
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // 커스텀 구분선 (좌측 텍스트 정렬 고려)
            Divider()
                .overlay(Color.gray1)
                .frame(height: 1)
                .padding(.horizontal, 20)
        }
        .background(Color.white)
    }
}

enum SpotCategory {
    case nature, culture, leisure, shopping, food, lodging, unknown

    var title: String {
        switch self {
        case .nature: "자연"
        case .culture: "인문(문화/예술/역사)"
        case .leisure: "레포츠"
        case .shopping: "쇼핑"
        case .food: "음식"
        case .lodging: "숙박"
        case .unknown: "기타"
        }
    }

    var symbol: String {
        switch self {
        case .nature: "nature"
        case .culture: "humon"
        case .leisure: "leport"
        case .shopping: "shoping"
        case .food: "food"
        case .lodging: "sleep"
        case .unknown: "mappin.and.ellipse"
        }
    }

    init(typeCode: String) {
        let code = typeCode.uppercased()
        switch code {
        case "A01": self = .nature
        case "A02": self = .culture
        case "A03": self = .leisure
        case "A04": self = .shopping
        case "A05": self = .food
        case "B02": self = .lodging
        default: self = .unknown
        }
    }
}

struct CategoryChip: View {
    let typeCode: String
    
    private var category: SpotCategory {
        SpotCategory(typeCode: typeCode)
    }
    
    var body: some View {
        HStack(spacing: 3) {
            Image(category.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                
            Text(category.title)
                .font(.pretendardRegular(size: 12))
                .foregroundColor(.gray5)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.gray1)
        )
    }
}
//
//#Preview {
//    CategoryChip(typeCode: "A05")
//}

#Preview {
    LocalSpotRowItemComponent(spot: .preview)
}

extension SpotData {
    static let preview = SpotData(
        title: "해피치즈스마일",
        addr1: "경북 경산시 조영동",
        typeCode: "A02",
        contentid: "12345",
        contenttypeid: "39",
        firstimage: "https://picsum.photos/200",
        firstimage2: "common",
        mapx: "128.5861797933",
        mapy: "35.8830627794"
    )
}
