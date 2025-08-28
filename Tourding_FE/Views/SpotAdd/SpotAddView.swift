//
//  SpotAddView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/28/25.
//

import SwiftUI

struct SpotAddView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject var spotAddViewModel: SpotAddViewModel
    
    init(spotAddViewModel: SpotAddViewModel) {
        self.spotAddViewModel = spotAddViewModel
    }
    
    var body: some View {
        VStack(alignment: .leading,spacing:0){
            
            header
            
            section
            
            Spacer()
        } // : VStack
        .navigationBarBackButtonHidden()
        .background(Color.gray1)
    }
    
    //MARK: - View
    private var header: some View {
        HStack(spacing: 0) {
            Button(action:{
                navigationManager.pop()
                //뒤로갈 때 전달
            }){
                Image("spotAdd_back")
                    .padding(.leading, 16)
            }
            
            Spacer()
            
            Text("스팟 추가")
                .foregroundColor(.gray5)
                .font(.pretendardMedium(size: 18))
            
            Spacer()
            
            Button(action:{}){
                Image("spotAdd_search")
                    .padding(.trailing, 16)
            }
            
        } // : HStack
        .frame(height: 56)
        .padding(.top, 24)
    } // : header
    
    private var section: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("들르기 좋은 스팟")
                    .foregroundColor(.gray6)
                    .font(.pretendardSemiBold(size: 26))
                
                Text("출발지와 도착지 사이 스팟을 모았어요")
                    .foregroundColor(.gray4)
                    .font(.pretendardMedium(size: 16))
            } // : VStack
            .padding(.top, 46)
            .padding(.trailing, 27)
            
            Image("illust_Recommended spot")
                .padding(.top, 14)
        } // : HStack
        .padding(.leading, 16)
    }
}

#Preview {
    SpotAddView(spotAddViewModel: SpotAddViewModel())
        .environmentObject(NavigationManager())
}
