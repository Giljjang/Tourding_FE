//
//  StartSearchView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/7/25.
//

import SwiftUI

struct DestinationSearchView : View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    @State private var searchText = ""
    
    var body: some View {
        HStack(spacing: 0){
            Spacer()
                .frame(width:16)
            Button(action: {
                navigationManager.pop()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.gray5)
                    .frame(width: 24, height: 24)
            }
            SearchBar(text: $searchText)
            Spacer()
                .frame(width: 4)
                .padding(.top, 68)
        }
        // 📌 결과 영역
        if searchText.isEmpty {
            VStack(spacing: 12) {
                Image("searchempty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 338)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        } else {
            // 📌 검색 결과 목록 예시
            List {
                Text("'\(searchText)'에 대한 검색 결과")
            }
            .listStyle(.plain)
        }
    }
    
}


#Preview {
    DestinationSearchView()
}
