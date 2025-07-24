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
            Color.yellow.ignoresSafeArea()

            VStack {
                Text("Tourding")
                    .font(.largeTitle)
                    .bold()
            }
        } // ZStack
    }
}

#Preview {
    SplashView()
}
