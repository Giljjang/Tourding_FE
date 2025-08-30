//
//  SearchHeaderComponent.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/22/25.
//

import SwiftUI

struct SearchHeaderComponent: View {
    @Binding var searchText: String
    @Binding var hasSearched: Bool
    let onBack: () -> Void
    let onSearchSubmit: () -> Void
    let onTextChange: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 16)
            
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.gray5)
                    .frame(width: 24, height: 24)
            }
            
            SearchBar(
                text: $searchText,
                hasSearched: $hasSearched,
                onSubmit: onSearchSubmit,
                onTextChange: onTextChange
            )
            
            Spacer()
                .frame(width: 4)
        }
        .padding(.top, 8)
    }
}
