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
}

#Preview {
    SpotAddView(spotAddViewModel: SpotAddViewModel())
        .environmentObject(NavigationManager())
}
