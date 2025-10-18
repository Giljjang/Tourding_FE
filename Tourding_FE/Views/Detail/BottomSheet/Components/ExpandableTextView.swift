//
//  ExpandableTextView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/7/25.
//

import SwiftUI

struct ExpandableTextView: View {
    let text: String
    let lineLimit: Int
    let font: Font
    let fontSize: CGFloat
    let color: Color
    
    @State private var isExpanded = false
    @State private var isTruncated = false
    @State private var fullHeight: CGFloat = 0
    @State private var truncatedHeight: CGFloat = 0
    
    init(text: String,
         lineLimit: Int = 5,
         font: Font = .pretendardRegular(size: 15),
         fontSize: CGFloat = 15,
         color: Color = .gray5) {
        self.text = text
        self.lineLimit = lineLimit
        self.font = font
        self.fontSize = fontSize
        self.color = color
    }
    
    var body: some View {
        
        let spacing = fontSize * 0.6
        
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .foregroundColor(color)
                .font(font)
                .lineSpacing(spacing)
                .lineLimit(isExpanded ? nil : lineLimit)
                .multilineTextAlignment(.leading)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isTruncated {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }
                }
            
            // 더보기/접기 버튼
            if isTruncated {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "접기" : "더보기")
                        .foregroundColor(.gray3)
                        .font(.pretendardRegular(size: 15))
                }
            }
        }
        .background(
            // 텍스트 높이 측정을 위한 숨겨진 뷰들
            ZStack {
                // 전체 텍스트 높이 측정
                Text(text)
                    .font(font)
                    .lineSpacing(spacing)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    fullHeight = geometry.size.height
                                    checkTruncation()
                                }
                                .onChange(of: geometry.size.height) { newHeight in
                                    fullHeight = newHeight
                                    checkTruncation()
                                }
                        }
                    )
                    .hidden()
                
                // 제한된 텍스트 높이 측정
                Text(text)
                    .font(font)
                    .lineSpacing(spacing)
                    .multilineTextAlignment(.leading)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    truncatedHeight = geometry.size.height
                                    checkTruncation()
                                }
                                .onChange(of: geometry.size.height) { newHeight in
                                    truncatedHeight = newHeight
                                    checkTruncation()
                                }
                        }
                    )
                    .hidden()
            }
        )
    }
    
    private func checkTruncation() {
        // 두 높이가 모두 측정된 후에 비교
        if fullHeight > 0 && truncatedHeight > 0 {
            // 즉시 상태 업데이트 (비동기 처리 제거)
            isTruncated = fullHeight > truncatedHeight
            print("🔍 텍스트 높이 비교: 전체=\(fullHeight), 제한=\(truncatedHeight), 잘림=\(isTruncated)")
        }
    }
}
