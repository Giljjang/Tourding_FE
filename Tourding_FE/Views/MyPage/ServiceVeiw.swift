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
            HStack {
                Button(action: {
                    navigationManager.pop()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .padding()
                }

                Spacer()
                
                Text("이용약관")
                    .font(.pretendardMedium(size: 18))
                    .foregroundColor(Color.gray5)
                
                Spacer()
                
                Spacer().frame(width: 44)
            }
            .padding(.top, 20)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            
            // MARK: - Terms Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("서비스 이용 약관")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                        Text("제 1장 총칙")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(dummyTermsText)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                }
                .padding(.top, 20)
                .padding(20)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
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
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus a efficitur sem, vel luctus est. Praesent non lectus fermentum, elementum leo non, mollis tellus. Suspendisse fringilla ut diam nec molestie. ...
"""
