//
//  DetailInfoLine.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/7/25.
//

import SwiftUI

struct DetailInfoLine: View {
    let image: String
    let text: String
    let type: String?
    
    @State private var isExpanded = false
    @State private var shouldShowIcon = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(image)
            
            if let type = type, type == "link", let url = URL(string: text) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Link(destination: url) {
                            Text(text)
                                .font(.pretendardRegular(size: 15))
                                .foregroundColor(.blue) // 링크 색상
                                .lineLimit(isExpanded ? nil : 1)
                                .multilineTextAlignment(.leading)
                        }
                        
                        if shouldShowIcon {
                            Image("icon_chevron-down")
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .foregroundColor(.gray)
                                .onTapGesture {
                                    withAnimation {
                                        isExpanded.toggle()
                                    }
                                }
                        }
                    }
                    .padding(.top, 3)
                }
                .contentShape(Rectangle()) // VStack 전체 클릭 영역
                .onTapGesture {
                    if shouldShowIcon {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                }
                .onAppear {
                    shouldShowIcon = checkIfTextIsMultiline()
                    print("링크: '\(text)', 여러줄 여부: \(shouldShowIcon)")
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Text(text)
                            .foregroundColor(.gray5)
                            .font(.pretendardRegular(size: 15))
                            .lineLimit(isExpanded ? nil : 1)
                            .multilineTextAlignment(.leading)
                        
                        if shouldShowIcon {
                            Image("icon_chevron-down")
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .foregroundColor(.gray)
                                .onTapGesture {
                                    withAnimation {
                                        isExpanded.toggle()
                                    }
                                }
                        }
                    }
                    .padding(.top, 3)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if shouldShowIcon {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                }
                .onAppear {
                    shouldShowIcon = checkIfTextIsMultiline()
                    print("텍스트: '\(text)', 여러줄 여부: \(shouldShowIcon)")
                }
            }
        }
    }
    
    // MARK: - Utils
    private func checkIfTextIsMultiline() -> Bool {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 32 - 24 - 8 - 20 // 패딩, 아이콘, 간격, 여백
        
        let size = label.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
        let lineHeight = label.font.lineHeight
        
        return size.height > lineHeight + 2
    }
}
