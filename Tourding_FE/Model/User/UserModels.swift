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

// MARK: - 라이딩 프로필(온보딩 설문) 요청/응답 모델
// PUT · GET /user/{id}/riding-profile
//
// 옵션 타입은 `RouteOptionModel` 하나다. 예전엔 필드가 똑같은 `RouteOptionDto`가
// 따로 있어서, 프로필에서 읽은 옵션을 POST /routes에 실으려면 변환이 필요했다.

struct UpdateRidingProfileRequest: Codable {
    let routeOption: RouteOptionModel
}

struct UserRidingProfileResponse: Codable {
    let userId: Int
    let routeOption: RouteOptionModel
}
