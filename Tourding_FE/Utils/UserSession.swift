//
//  UserSession.swift
//  Tourding_FE
//
//  로그인된 사용자 식별자 공급자.
//  ViewModel이 KeychainHelper를 직접 호출하면 생성자가 전역 상태에 묶여
//  테스트가 시뮬레이터 Keychain 상태에 좌우된다.
//

import Foundation

protocol UserSessionProviding {
    var userId: Int? { get }
}

struct KeychainUserSession: UserSessionProviding {
    var userId: Int? { KeychainHelper.loadUid() }
}
