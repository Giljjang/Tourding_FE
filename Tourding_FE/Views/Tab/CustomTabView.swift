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
                VStack{
                    Image(currentView == .RidingView ? "riding_on": "riding_off")
                    
                    Text("라이딩")
                        .foregroundStyle(currentView == .RidingView ? Color.gray6 : Color.gray3)
                        .font(.pretendardMedium(size: 14))
                    
                    Spacer()
                }
            } // : Button
            .padding(.leading, 53)
            
            Spacer()
            
            Button(action: {
                navigationManager.currentTab = .SpotSearchView
            }){
                VStack{
                    Image(currentView == .SpotSearchView ? "spot_on" : "spot_off")
                    
                    Text("스팟 탐색")
                        .foregroundStyle(currentView == .SpotSearchView ? Color.gray6 : Color.gray3)
                        .font(.pretendardMedium(size: 14))
                    
                    Spacer()
                }
            } // : Button
            
            Spacer()
            
            Button(action: {
                navigationManager.currentTab = .MyPageView
            }){
                VStack{
                    Image(currentView == .MyPageView ? "user_on" : "user_off")
                    
                    Text("내 정보")
                        .foregroundStyle(currentView == .MyPageView ? Color.gray6 : Color.gray3)
                        .font(.pretendardMedium(size: 14))
                    
                    Spacer()
                }
            } // :  Button
            .padding(.trailing, 53)
            
        } // : HStack
        .padding(.top, 10)
        .frame(height:106)
        .background(.white)
        .cornerRadius(22, corners: [.topLeft, .topRight])
        .shadow(color: Color(red: 0.45, green: 0.52, blue: 0.59).opacity(0.06), radius: 18, x: 4, y: 0)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .inset(by: 0.5)
                .stroke(Color.gray1, lineWidth: 1)
            
        )
    }
}

#Preview {
    CustomTabView(currentView: .RidingView)
        .environmentObject(NavigationManager())
}
