//
//  KeychainSessionTests.swift
//  Tourding_FETests
//
//  로그아웃 시 Keychain에 세션 흔적이 남지 않아야 한다.
//
//  이전에는 MyPageViewModel.AppleLogout이 플래그만 내리고 uid·appleUserId·loginProvider를
//  그대로 남겨서, 앱을 재실행하면 checkExistingLogin()이 로그인 상태로 복귀시켰다.
//  계정을 바꿔 로그인하면 이전 계정 uid로 API를 호출하는 창도 생겼다.
//
//  전역 Keychain을 만지므로 직렬 실행한다.
//

import Foundation
import Security
import Testing
@testable import Tourding_FE

@Suite(.serialized)
struct KeychainSessionTests {

    private func removeAllTestItems() {
        KeychainHelper.clearSession()
        KeychainHelper.delete(key: "appleUserName")
        KeychainHelper.delete(key: "appleUserEmail")
    }

    private func accessibility(ofAccount account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let attributes = result as? [String: Any] else { return nil }
        return attributes[kSecAttrAccessible as String] as? String
    }

    // MARK: - 세션 정리

    @Test func clearSessionRemovesEverySessionItem() {
        KeychainHelper.save(key: "accessToken", value: "at")
        KeychainHelper.save(key: "refreshToken", value: "rt")
        KeychainHelper.saveUid(key: 777_777)
        KeychainHelper.save(key: "appleUserId", value: "apple-uid")
        KeychainHelper.save(key: "appleAuthorizationCode", value: "code")
        KeychainHelper.save(key: "loginProvider", value: "apple")

        KeychainHelper.clearSession()

        #expect(KeychainHelper.load(key: "accessToken") == nil)
        #expect(KeychainHelper.load(key: "refreshToken") == nil)
        #expect(KeychainHelper.loadUid() == nil)
        #expect(KeychainHelper.load(key: "appleUserId") == nil)
        #expect(KeychainHelper.load(key: "appleAuthorizationCode") == nil)
        #expect(KeychainHelper.load(key: "loginProvider") == nil)
    }

    /// 애플은 최초 인증 때만 이름·이메일을 준다. 재로그인 시 표시하려면 보존해야 한다.
    @Test func clearSessionKeepsAppleDisplayInfo() {
        KeychainHelper.save(key: "appleUserName", value: "홍길동")
        KeychainHelper.save(key: "appleUserEmail", value: "a@b.c")

        KeychainHelper.clearSession()

        #expect(KeychainHelper.load(key: "appleUserName") == "홍길동")
        #expect(KeychainHelper.load(key: "appleUserEmail") == "a@b.c")

        removeAllTestItems()
    }

    // MARK: - 저장 속성

    /// 암호화 백업으로 토큰이 다른 기기에 복원되면 안 된다
    @Test func storedItemsAreNotRestorableToAnotherDevice() throws {
        KeychainHelper.save(key: "accessToken", value: "at")

        let accessible = try #require(accessibility(ofAccount: "accessToken"))
        #expect(accessible == (kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String))

        removeAllTestItems()
    }

    @Test func storedUidIsNotRestorableToAnotherDevice() throws {
        KeychainHelper.saveUid(key: 777_777)

        let accessible = try #require(accessibility(ofAccount: "uid"))
        #expect(accessible == (kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String))

        removeAllTestItems()
    }

    /// 저장 실패를 조용히 삼키면 이후 loadUid()가 nil이어도 아무 신호가 없다
    @Test func saveReportsItsStatus() {
        #expect(KeychainHelper.save(key: "accessToken", value: "at") == errSecSuccess)
        #expect(KeychainHelper.saveUid(key: 777_777) == errSecSuccess)

        removeAllTestItems()
    }

    @Test func savedValueRoundTrips() {
        KeychainHelper.save(key: "accessToken", value: "round-trip")

        #expect(KeychainHelper.load(key: "accessToken") == "round-trip")

        removeAllTestItems()
    }
}
