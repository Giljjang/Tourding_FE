//
//  PlaceRowItemComponent.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/22/25.
//

import SwiftUI
import CoreLocation

struct PlaceRowItemComponent: View {
    let place: Place
    var currentLocation: CLLocationCoordinate2D?
    var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // 위치 아이콘
                Image("spot")
                    .resizable()
                    .renderingMode(.original)          // 템플릿 변환 방지(색 유지)
                    .aspectRatio(1, contentMode: .fit) // 정사각 유지
                    .frame(width: 18, height: 20)
                    .fixedSize()
                
                // 장소 정보
                VStack(alignment: .leading, spacing: 5) {
                    // 장소명 (하이라이트 적용)
                    place.placeName.highlightedText(
                        searchText: searchText,
                        highlightColor: .blue, // 원하는 하이라이트 색상
                        normalColor: Color.gray6
                    )
                    .font(.pretendardMedium(size: 16))
                    .lineLimit(1)
                    
                    // 주소
                    Text(place.roadAddressName.isEmpty ? place.addressName : place.roadAddressName)
                        .font(.pretendardRegular(size: 14))
                        .foregroundColor(Color.gray4)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 거리 표시
                if let formattedDistance = place.formattedDistance {
                    Text(formattedDistance)
                        .font(.pretendardMedium(size: 14))
                        .foregroundColor(Color.gray5)
                }
            } // : HStack
            .padding(.vertical, 16)
            .padding(.leading, 18)
            .padding(.trailing, 16)
            
            // 커스텀 구분선
            Divider()
                .frame(height: 1)
                .overlay(Color.gray1)
                .padding(.horizontal, 16)
        } // : VStack
        .contentShape(Rectangle())
    }
}
