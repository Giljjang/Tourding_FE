//
//  FilterBarView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/31/25.
//

import SwiftUI

// MARK: - 두 개의 필터와 초기화 버튼이 있는 메인 뷰
struct FilterBarView: View {
    @Binding var selectedRegion: String?
    @Binding var selectedTheme: String?
    let onFilterChanged: (String?, String?) -> Void
    let onResetFilters: () -> Void
    
    @State private var showFilterModal = false
    
    var hasActiveFilters: Bool {
        selectedRegion != nil || selectedTheme != nil
    }
    
    var filterCount: Int {
        var count = 0
        if selectedRegion != nil { count += 1 }
        if selectedTheme != nil { count += 1 }
        return count
    }
    
    var body: some View {
        HStack {
            // 두 개의 필터 버튼
            HStack(spacing: 8) {
                FilterView(
                    title: "지역",
                    selectedValue: $selectedRegion,
                    action: {
                        showFilterModal = true
                    }
                )
                
                FilterView(
                    title: "테마",
                    selectedValue: $selectedTheme,
                    action: {
                        showFilterModal = true
                    }
                )
            }
            
            Spacer()
            
            // 필터 초기화 버튼
            if hasActiveFilters {
                Button(action: onResetFilters) {
                    HStack(spacing: 4) {
                        Text("필터 \(filterCount)")
                            .font(.pretendardMedium(size: 14))
                            .foregroundColor(.gray4)
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.gray3)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 0)
        .background(Color.white)
        .sheet(isPresented: $showFilterModal) {
            FilterModal(
                selectedRegion: $selectedRegion,
                selectedTheme: $selectedTheme,
                isPresented: $showFilterModal,
                onFilterApplied: onFilterChanged  // 콜백 전달
            )
            .presentationDetents([.fraction(0.7)])
        }
    }
}

//// MARK: - 미리보기
//#Preview {
//    FilterBarView()
//}
