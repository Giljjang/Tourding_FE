//
//  CustomButtonView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/6/25.
//

import SwiftUI

// MARK: - 커스텀 메뉴 버튼 컴포넌트
struct CustomButtonView: View {
    let title: String
    let action: () -> Void
    
    // 옵셔널 커스터마이징 파라미터들
    let icon: String?
    let titleColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    // 기본 생성자
    init(
        title: String,
        icon: String? = "chevron-right",
        titleColor: Color = Color.gray6,
        backgroundColor: Color = Color.customwhite,
        cornerRadius: CGFloat = 20,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(title)
                    .foregroundColor(titleColor)
                    .font(.pretendardMedium(size: 16))
                    .frame(height: 26)
                    .padding(.leading, 24)
                    .padding(.vertical, 15)
                
                Spacer()
                
                if let icon = icon {
                    Image(icon)
                        .padding(.trailing, 16)
                }
            }
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
        }
    }
}

// MARK: - 편의 생성자들을 위한 익스텐션
extension CustomButtonView {
    
    // 네비게이션용 버튼
    static func withNavigation(
        title: String,
        destination: ViewType,
        navigationManager: NavigationManager
    ) -> CustomButtonView {
        CustomButtonView(title: title) {
            navigationManager.push(destination)
        }
    }
    
    // 단순 액션용 버튼
    static func withAction(
        title: String,
        action: @escaping () -> Void
    ) -> CustomButtonView {
        CustomButtonView(title: title, action: action)
    }
    
    // 위험한 액션용 버튼 (빨간색 텍스트)
    static func dangerAction(
        title: String,
        action: @escaping () -> Void
    ) -> CustomButtonView {
        CustomButtonView(
            title: title,
            titleColor: .red,
            action: action
        )
    }
    
    // 아이콘 없는 버튼
    static func withoutIcon(
        title: String,
        action: @escaping () -> Void
    ) -> CustomButtonView {
        CustomButtonView(
            title: title,
            icon: nil,
            action: action
        )
    }
}
