//
//  ServiceVeiw.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/5/25.
//

import SwiftUI

struct ServiceView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            
            // MARK: - Top Navigation Bar
            ZStack {
                HStack {
                    Button(action: {
                        navigationManager.pop()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.gray5)
                            .padding()
                    }
                    Spacer()
                }

                Text("이용약관")
                    .font(.pretendardMedium(size: 18))
                    .foregroundColor(Color.gray5)
            }
            .frame(height: 56)
            .padding(.bottom, 29)
            
            // MARK: - Terms Content
            ScrollView {
                VStack(alignment: .leading) {
                    Text("서비스 이용 약관")
                        .font(.pretendardSemiBold(size: 16))
                        .foregroundColor(Color.gray5)
                        .padding(.bottom, 19)
                    
                        Text("제 1장 총칙")
                        .font(.pretendardRegular(size: 14))
                        .foregroundColor(Color.gray5)
                        .padding(.bottom, 1)
                        
                        Text(dummyTermsText)
                        .font(.pretendardRegular(size: 14))
                        .foregroundColor(Color.gray4)
                            .lineSpacing(1.4)
                }
                .padding(22)
                .background(Color.gray1)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray2, lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .background(Color(.white).ignoresSafeArea())
        .navigationBarHidden(true)  // ✅ 시스템 네비게이션 바 숨김
    }
}

// MARK: - 안전한 Preview
#Preview {
    NavigationStack {
        ServiceView()
            .environmentObject(NavigationManager())
    }
}

// Dummy Text
let dummyTermsText = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus a efficitur sem, vel luctus est. Praesent non lectus fermentum, elementum leo non, mollis tellus. Suspendisse fringilla ut diam nec molestie. Praesent quam ligula, faucibus a ligula mollis, rutrum cursus felis. Nulla et elit nec felis consectetur aliquet. Morbi odio sapien, venenatis id fringilla id, pulvinar nec sem. Mauris lorem metus, vulputate et ligula et, fermentum molestie nibh. Aenean lacinia, nibh nec viverra porttitor, ipsum ligula luctus velit, sit amet bibendum orci risus eget ligula. Etiam non gravida justo, eu suscipit est. Nulla aliquet ultrices mi, sed molestie nunc congue a.
Vestibulum pretium tempor orci, ut sollicitudin ante congue eu. Praesent at suscipit dui. Aenean convallis sed eros in sollicitudin. Nullam ut aliquet dolor. Suspendisse iaculis neque a sapien ornare, sed bibendum metus sollicitudin. Cras sed metus sed felis aliquam porta. Phasellus cursus ex a turpis ultricies, in maximus eros euismod. Quisque nunc orci, imperdiet eget orci id, accumsan pharetra justo. Nam feugiat, leo et rutrum porta, libero magna euismod arcu, et elementum purus tellus nec lacus. Proin eget mollis nulla. Suspendisse ligula lectus, rhoncus ac dictum sed, imperdiet id nibh. Donec dapibus turpis ac lacus dictum mollis. Quisque ut interdum sem. Aenean nisi nibh, sagittis eget feugiat in, eleifend nec nunc.
"""
