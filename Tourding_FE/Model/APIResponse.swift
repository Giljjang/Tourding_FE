//
//  APIResponse.swift
//  5th-SwiftUI-URLSession
//
//  Created by 이유현 on 3/3/25.
//

import Foundation

// 서버로부터의 성공/실패 응답을 처리하는 구조체
struct APIResponse: Codable {
    let success: Bool
}
