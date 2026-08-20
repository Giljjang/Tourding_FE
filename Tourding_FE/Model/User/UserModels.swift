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
// PUT /user/{id}/riding-profile
struct RouteOptionDto: Codable {
    let cyclingProfile: String
    let fastRoute: Bool
    let avoidSteps: Bool
    let avoidFords: Bool
    let skillLevel: String

    init(cyclingProfile: String, fastRoute: Bool, avoidSteps: Bool, avoidFords: Bool, skillLevel: String) {
        self.cyclingProfile = cyclingProfile
        self.fastRoute = fastRoute
        self.avoidSteps = avoidSteps
        self.avoidFords = avoidFords
        self.skillLevel = skillLevel
    }

    init(bikeType: BikeType, skillLevel: RidingSkillLevel, fastRoute: Bool, avoidSteps: Bool, avoidFords: Bool) {
        self.init(
            cyclingProfile: bikeType.apiValue,
            fastRoute: fastRoute,
            avoidSteps: avoidSteps,
            avoidFords: avoidFords,
            skillLevel: skillLevel.apiValue
        )
    }
}

struct UpdateRidingProfileRequest: Codable {
    let routeOption: RouteOptionDto
}

struct UserRidingProfileResponse: Codable {
    let userId: Int
    let routeOption: RouteOptionDto
}
