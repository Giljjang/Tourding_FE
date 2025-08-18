//
//  String+Highlight.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/16/25.
//
// 검색어랑 똑같은 부분 색칠할때 사용
import SwiftUI

extension String {
    func highlightedText(searchText: String, highlightColor: Color = .blue, normalColor: Color = .primary) -> Text {
        guard !searchText.isEmpty else {
            return Text(self).foregroundColor(normalColor)
        }
        
        let lowercaseSelf = self.lowercased()
        let lowercaseSearch = searchText.lowercased()
        
        // 검색어가 포함되지 않으면 일반 텍스트 반환
        guard lowercaseSelf.contains(lowercaseSearch) else {
            return Text(self).foregroundColor(normalColor)
        }
        
        var result = Text("")
        var currentIndex = self.startIndex
        
        // 모든 매칭 위치 찾기
        while currentIndex < self.endIndex {
            if let range = lowercaseSelf[currentIndex...].range(of: lowercaseSearch) {
                let actualRange = self.index(self.startIndex, offsetBy: range.lowerBound.utf16Offset(in: lowercaseSelf))...self.index(self.startIndex, offsetBy: range.upperBound.utf16Offset(in: lowercaseSelf) - 1)
                
                // 매칭 이전 부분 (일반 색상)
                if currentIndex < actualRange.lowerBound {
                    let beforeText = String(self[currentIndex..<actualRange.lowerBound])
                    result = result + Text(beforeText).foregroundColor(normalColor)
                }
                
                // 매칭 부분 (하이라이트 색상)
                let matchedText = String(self[actualRange])
                result = result + Text(matchedText).foregroundColor(highlightColor)
                
                // 다음 검색을 위해 인덱스 업데이트
                currentIndex = self.index(after: actualRange.upperBound)
            } else {
                // 더 이상 매칭되는 부분이 없으면 나머지를 일반 색상으로
                let remainingText = String(self[currentIndex...])
                result = result + Text(remainingText).foregroundColor(normalColor)
                break
            }
        }
        
        return result
    }
}
