//
//  CustomTabView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct CustomTabView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    let currentView: ViewType
    
    var body: some View {
        HStack(alignment: .top, spacing: 0){
            
            Button(action: {
                navigationManager.currentTab = .RidingView
            }){
                VStack(spacing:4){
                    Image(currentView == .RidingView ? "riding_on": "riding_off")
                    
                    Text("라이딩")
                        .foregroundStyle(currentView == .RidingView ? Color.white : Color.gray4)
                        .font(.pretendardSemiBold(size: 12))
                    
                    Spacer()
                }
            } // : Button
            .padding(.leading, 33.5)
            
            Spacer()
            
            Button(action: {
                navigationManager.currentTab = .SpotSearchView
            }){
                VStack(spacing:4){
                    Image(currentView == .SpotSearchView ? "spot_on" : "spot_off")
                    
                    Text("스팟 탐색")
                        .foregroundStyle(currentView == .SpotSearchView ? Color.white : Color.gray4)
                        .font(.pretendardSemiBold(size: 12))
                    
                    Spacer()
                }
            } // : Button
            
            Spacer()
            
            Button(action: {
                navigationManager.currentTab = .MyPageView
            }){
                VStack(spacing:4){
                    Image(currentView == .MyPageView ? "user_on" : "user_off")
                    
                    Text("내 정보")
                        .foregroundStyle(currentView == .MyPageView ? Color.white : Color.gray4)
                        .font(.pretendardSemiBold(size: 12))
                    
                    Spacer()
                }
            } // :  Button
            .padding(.trailing, 35)
            
        } // : HStack
        .padding(.top, 12)
        .padding(.bottom, 11)
        .frame(width: 274, height: 70, alignment: .top)
        .background(Color.gray5)
        .cornerRadius(50)
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 5)
        
    }
}

#Preview {
    CustomTabView(currentView: .RidingView)
        .environmentObject(NavigationManager())
}
