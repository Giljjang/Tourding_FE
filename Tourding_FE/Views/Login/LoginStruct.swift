//
//  LoginStruct.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/3/25.
//

import Foundation

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image_sub: [String]// 들어갈 이미지들 이름 배열 (없으면 비워두기)
    let title: String
    let images: [String]
}

let onboardingPages = [
    OnboardingPage(image_sub: ["logo"], title: "내 맘대로 담는 라이딩 루트", images: ["illust_login_1"]),
    OnboardingPage(image_sub: [], title: "도착지 사이 스팟을 추천받아요", images: ["illust_login_2"]),
    OnboardingPage(image_sub: [], title: "원하는 순서로 스팟을 배치해\n 나만의 코스를 만들어요", images: ["illust_login_3"]),
    OnboardingPage(image_sub: [], title: "라이딩 중 근처 편의시설\n 정보를 확인할 수 있어요", images: ["illust_login_4"])
]
