//
//  MockAPIConfiguration.swift
//  Tourding_FE
//

import Foundation

enum MockAPIConfiguration {
    private static let launchArgument = "-UseMockAPI"
    private static let userDefaultsKey = "UseMockAPI"

    static var useMockAPI: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(launchArgument) {
            return true
        }
        if UserDefaults.standard.bool(forKey: userDefaultsKey) {
            return true
        }
        return false
        #else
        return false
        #endif
    }

    #if DEBUG
    static func enableMockAPI() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
    }

    static func disableMockAPI() {
        UserDefaults.standard.set(false, forKey: userDefaultsKey)
    }
    #endif
}
