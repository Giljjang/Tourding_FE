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
                Link(text, destination: url)
                    .font(.pretendardRegular(size: 15))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Text(text)
                            .foregroundColor(.gray)
                            .font(.pretendardRegular(size: 15))
                            .lineLimit(isExpanded ? nil : 1)
                            .multilineTextAlignment(.leading)
                        
                        // 두 줄 이상일 때만 아이콘 표시
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
                    } // : HStack
                    .padding(.top, 3)
                } // : VStack
                .contentShape(Rectangle()) // VStack 전체를 클릭 영역으로
                .onTapGesture {
                    if shouldShowIcon {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                } // : onTapGesture
                .onAppear {
                    shouldShowIcon = checkIfTextIsMultiline()
                    print("텍스트: '\(text)', 여러줄 여부: \(shouldShowIcon)")
                }
            }
        }// : HStack
    }
    
    //MARK: - Utils
    // 텍스트가 여러 줄인지 확인하는 함수
    private func checkIfTextIsMultiline() -> Bool {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        // 화면 너비에서 아이콘과 패딩을 제외한 실제 텍스트 너비
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 32 - 24 - 8 - 20 // 패딩, 아이콘, 간격, 여백
        
        let size = label.sizeThatFits(CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude))
        let lineHeight = label.font.lineHeight
        
        // 실제 높이가 한 줄 높이보다 크면 여러 줄
        return size.height > lineHeight + 2 // 2pt 여유
    }
}
