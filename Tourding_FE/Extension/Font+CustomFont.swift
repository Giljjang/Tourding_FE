//
//  Font+CustomFont.swift
//  Starter-SwiftUI
//
//  Created by 이유현 on 4/17/25.
//

import SwiftUI

extension Font {
    static func pretendardBlack(size: CGFloat) -> Font {
        .custom("Pretendard-Black", size: size)
    }

    static func pretendardBold(size: CGFloat) -> Font {
        .custom("Pretendard-Bold", size: size)
    }

    static func pretendardExtraBold(size: CGFloat) -> Font {
        .custom("Pretendard-ExtraBold", size: size)
    }

    static func pretendardExtraLight(size: CGFloat) -> Font {
        .custom("Pretendard-ExtraLight", size: size)
    }

    static func pretendardLight(size: CGFloat) -> Font {
        .custom("Pretendard-Light", size: size)
    }

    static func pretendardMedium(size: CGFloat) -> Font {
        .custom("Pretendard-Medium", size: size)
    }

    static func pretendardRegular(size: CGFloat) -> Font {
        .custom("Pretendard-Regular", size: size)
    }

    static func pretendardSemiBold(size: CGFloat) -> Font {
        .custom("Pretendard-SemiBold", size: size)
    }

    static func pretendardThin(size: CGFloat) -> Font {
        .custom("Pretendard-Thin", size: size)
    }
}
