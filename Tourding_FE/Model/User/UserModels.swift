//
//  UserModels.swift
//  Tourding_FE
//
//  Created by 유재혁 on 9/6/25.
//

import Foundation

// MARK: - 서버 유저 등록 요청 모델
// UserModels.swift
struct CreateUserRequest: Codable {
    let username: String
    let password: String   // ✅ optional 아님
    let email: String

    init(username: String, email: String, password: String) {
        self.username = username
        self.password = password   // ✅ 서버가 "" 허용
        self.email = email
    }
}

// MARK: - 서버 유저 등록 응답 모델
struct CreateUserResponse: Codable {
    let id: Int
    let name: String
    let email: String
}

// MARK: - 유저 정보 모델
struct UserInfo: Codable {
    let id: Int
    let name: String
    let email: String
    let loginProvider: String // "kakao" 또는 "apple"
}
