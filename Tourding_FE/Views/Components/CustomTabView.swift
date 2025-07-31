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
        HStack{
            Spacer()
            
            Button(action: {
                navigationManager.currentTab = .HomeView
            }){
                VStack{
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: currentView == .HomeView ? "fea443" : "DEDEDE"))
                    
                    Text("코스 찾기")
                        .foregroundStyle(Color(hex: currentView == .HomeView ? "fea443" : "DEDEDE"))
                }
            }
            
            Spacer()
            
            Button(action: {
                navigationManager.currentTab = .TourRecommendationView
            }){
                VStack{
                    Image(systemName: "house.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: currentView == .TourRecommendationView ? "fea443" : "DEDEDE"))
                    
                    Text("여행지 탐색")
                        .foregroundStyle(Color(hex: currentView == .TourRecommendationView ? "fea443" : "DEDEDE"))
                }
            }
            
            Spacer()
            
            Button(action: {
                navigationManager.currentTab = .MyPageView
            }){
                VStack{
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: currentView == .MyPageView ? "fea443" : "DEDEDE"))
                
                    Text("마이페이지")
                        .foregroundStyle(Color(hex: currentView == .MyPageView ? "fea443" : "DEDEDE"))
                }
            }
            
            Spacer()
            
        } // : HStack
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
}

#Preview {
    CustomTabView(currentView: .HomeView)
        .environmentObject(NavigationManager())
}
