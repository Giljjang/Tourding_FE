//
//  RecentSearchSectionComponent.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/22/25.
//

import SwiftUI

struct RecentSearchSectionComponent: View {
    let recentSearchItems: [String]
    let onChipTap: (String) -> Void
    let onChipDelete: (String) -> Void
    let onClearAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Text("최근 검색")
                    .font(.pretendardMedium(size: 18))
                    .foregroundColor(.gray6)
                
                Spacer()
                
                Button("전체삭제") {
                    onClearAll()
                }
                .font(.pretendardMedium(size: 14))
                .foregroundColor(.gray5)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            
            // 최근 검색어 칩들 (가로 스크롤)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recentSearchItems, id: \.self) { searchTerm in
                        RecentChip(
                            title: searchTerm,
                            onTap: {
                                onChipTap(searchTerm)
                            },
                            onDelete: {
                                onChipDelete(searchTerm)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }
}
