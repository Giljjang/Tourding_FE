//
//  Keychain.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/2/25.
//

// Kakao Token Keychain 저장 및 불러오기 Helper
import Foundation
import Security
import KakaoSDKUser
import KakaoSDKAuth

struct KeychainHelper {
    /// 항목이 다른 기기로 복원되지 않도록 하는 접근 속성.
    /// `ThisDeviceOnly`가 없으면 암호화 백업을 통해 토큰이 다른 기기에서 되살아난다.
    private static let accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    private static func accountQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
    }

    @discardableResult
    private static func store(_ value: String, forAccount account: String) -> OSStatus {
        guard let data = value.data(using: .utf8) else { return errSecParam }

        let query = accountQuery(account)
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = accessibility

        return SecItemAdd(addQuery as CFDictionary, nil)
    }

    @discardableResult
    static func save(key: String, value: String) -> OSStatus {
        store(value, forAccount: key)
    }

    /// 로그아웃 시 지워야 하는 세션 항목 일체.
    /// 애플 표시용 이름·이메일은 최초 인증 때만 받을 수 있으므로 보존한다.
    static func clearSession() {
        clearAllTokens()
        deleteUid()
        delete(key: "appleUserId")
        delete(key: "appleAuthorizationCode")
        delete(key: "loginProvider")
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func clearAllTokens() {
        delete(key: "accessToken")
        delete(key: "refreshToken")
    }

    
    //MARK: - 이건 로컬 서버에서 받아온 uid 저장용
    
    @discardableResult
    static func saveUid(key: Int) -> OSStatus {
        store(String(key), forAccount: "uid")   // 항상 고정된 이름
    }

    static func loadUid() -> Int? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "uid", // 고정 이름
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data,
           let stringValue = String(data: data, encoding: .utf8),
           let intValue = Int(stringValue) {
            return intValue
        }
        return nil
    }

    static func deleteUid() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "uid"
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - 애플 로그인 정보 저장용
    
    static func saveAppleUserInfo(userId: String, name: String, email: String) {
        save(key: "appleUserId", value: userId)
        save(key: "appleUserName", value: name)
        save(key: "appleUserEmail", value: email)
        save(key: "loginProvider", value: "apple")
        print("✅ 애플 유저 정보 저장 완료")
    }
    
    static func loadAppleUserInfo() -> (userId: String?, name: String?, email: String?) {
        let userId = load(key: "appleUserId")
        let name = load(key: "appleUserName")
        let email = load(key: "appleUserEmail")
        return (userId, name, email)
    }
    
    static func clearAppleUserInfo() {
        delete(key: "appleUserId")
        delete(key: "appleUserName")
        delete(key: "appleUserEmail")
        delete(key: "loginProvider")
        print("🗑 애플 유저 정보 삭제 완료")
    }

    // MARK: - 온보딩 설문 완료 여부 저장용

    static func saveOnboardingCompleted() {
        save(key: "hasCompletedOnboarding", value: "true")
    }

    static func hasCompletedOnboarding() -> Bool {
        load(key: "hasCompletedOnboarding") == "true"
    }

    static func deleteOnboardingCompleted() {
        delete(key: "hasCompletedOnboarding")
    }

}

func saveKakaoToken(token: OAuthToken) {
    KeychainHelper.save(key: "accessToken", value: token.accessToken)
    KeychainHelper.save(key: "refreshToken", value: token.refreshToken)
    print("✅ Token saved in Keychain")
}

func loadKakaoToken(completion: @escaping (Bool) -> Void) {
    if let accessToken = KeychainHelper.load(key: "accessToken") {
        print("🔐 AccessToken 로드됨")
        UserApi.shared.accessTokenInfo { tokenInfo, error in
            if let _ = tokenInfo {
                print("✅ Token is valid. User is logged in.")
                completion(true)
            } else {
                print("❌ Token is invalid or expired.")
                completion(false)
            }
        }
    } else {
        print("❌ No AccessToken found in Keychain")
        completion(false)
    }
}

func clearKakaoTokens() {
    KeychainHelper.clearAllTokens()
    print("🗑 Tokens cleared from Keychain")
}
