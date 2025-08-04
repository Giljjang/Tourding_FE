//
//  Color+Hex.swift
//  Starter-SwiftUI
//
//  Created by 이유현 on 4/17/25.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    //디자인 시스템
    static let customwhite = Color(hex: "#FFFFFF")

    static let gray1 = Color(hex: "#F5F5F5")
    static let gray2 = Color(hex: "#E1E5EB")
    static let gray3 = Color(hex: "#C4CDD5")
    static let gray4 = Color(hex: "#87929D")
    static let gray5 = Color(hex: "#4B535B") // Secondary
    static let gray6 = Color(hex: "#2F353A")
    
    static let customblack = Color(hex: "#000000")
    
    static let yellowkakao = Color(hex: "#FEE820")

    static let main = Color(hex: "#00E1FF")       // 밝은 청록색
    static let mainCalm = Color(hex: "#00D7F3")   // 차분한 청록색
    
    static let warningRed = Color(hex: "FF4949")
}
