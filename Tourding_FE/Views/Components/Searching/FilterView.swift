//
//  Filter.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/31/25.
//

import SwiftUI

// MARK: - 재사용 가능한 FilterView 컴포넌트
struct FilterView: View {
    let title: String
    @Binding var selectedValue: String?
    let action: () -> Void  // 액션 클로저 추가
    
    // 선택 상태에 따른 색상 계산
    private var isSelected: Bool {
        selectedValue != nil
    }
    
    private var backgroundColor: Color {
        isSelected ? Color.gray5 : Color.white
    }
    
    private var textColor: Color {
        isSelected ? Color.white : Color.gray4
    }
    
    private var borderColor: Color {
        isSelected ? Color.gray5 : Color.gray2
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(selectedValue ?? title)
                    .font(.pretendardMedium(size: 14))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray3)
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10) // 모서리 둥근 사각형
                    .stroke(borderColor, lineWidth: 1) // 원하는 색, 두께
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // 선택되지 않은 상태
        FilterView(
            title: "필터 선택",
            selectedValue: .constant(nil),
            action: { print("필터 클릭됨") }
        )
        
        // 선택된 상태
        FilterView(
            title: "필터 선택",
            selectedValue: .constant("선택됨"),
            action: { print("필터 클릭됨") }
        )
    }
    .padding()
}
