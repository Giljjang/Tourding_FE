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
    static func save(key: String, value: String) {
        if let data = value.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]
            SecItemDelete(query as CFDictionary)
            SecItemAdd(query as CFDictionary, nil)
        }
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
}

func saveKakaoToken(token: OAuthToken) {
    KeychainHelper.save(key: "accessToken", value: token.accessToken)
    KeychainHelper.save(key: "refreshToken", value: token.refreshToken)
    print("✅ Token saved in Keychain")
}

func loadKakaoToken(completion: @escaping (Bool) -> Void) {
    if let accessToken = KeychainHelper.load(key: "accessToken") {
        print("🔐 Loaded AccessToken: \(accessToken)")
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
