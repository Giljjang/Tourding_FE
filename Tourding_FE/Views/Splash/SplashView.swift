//
//  SplashView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            HStack(spacing: 0) {
                Image("bike")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 80)
                    .padding(.leading, 35)
                
                Spacer()
                
                    .frame(width: 12)
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 222)
                    .padding(.trailing, 35)
            } // HStack
            .frame(maxWidth: .infinity)
        } // ZStack
    }
}

#Preview {
    SplashView()
}
