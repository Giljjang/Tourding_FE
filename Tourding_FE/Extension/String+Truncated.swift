//
//  String+Truncated.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/31/25.
//

import Foundation

extension String {
    func truncated(limit: Int, trailing: String = "...") -> String {
        if self.count > limit {
            let endIndex = self.index(self.startIndex, offsetBy: limit)
            return self[..<endIndex] + trailing
        } else {
            return self
        }
    }
}

/*
 사용법:
 
 let text1 = "이 문자열은 길이가 길어요"
 print(text1.truncated(limit: 5))
 */
