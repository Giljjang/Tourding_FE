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
            
            filterSection
                .padding(.bottom, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    //Row Cell
                    HStack(alignment: .top, spacing: 0){
                        VStack{
                            Image("empty")
                        }
                        .frame(width: 52, height: 52)
                        .background(Color.gray1)
                        .cornerRadius(10)
                        
    
                        VStack(alignment: .leading, spacing: 2) {
                            Text("불국사")
                                .foregroundColor(.gray6)
                                .font(.pretendardSemiBold(size: 16))
                            
                            Text("경북 경산시 조영동")
                                .foregroundColor(.gray4)
                                .font(.pretendardRegular(size: 14))
                        }
                        .padding(.leading, 12)
                        .padding(.top, 5)
                        
                        Spacer()
                        
                        Button(action:{}){
                            Text("추가")
                                .foregroundColor(.gray4)
                                .padding(.vertical, 9.2)
                                .padding(.horizontal, 12)
                                .background(Color.gray1)
                                .cornerRadius(10)
                        }
                        .padding(.vertical, 10)
                        
                    } // : HStack
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    
                } //: VStack
                .padding(.top, 4)
                .background(.white)
                .cornerRadius(16)
                .padding(.horizontal, 16)
            } // : ScrollView
            
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
        .padding(.bottom, 16)
    }
    
    private func toggleFilterButton(
        title: String
    ) -> some View {
        Button(action:{}){
            HStack(spacing: 0) {
                Image(spotAddViewModel.matchImageName(for: title))
                
                Text(title)
                    .foregroundColor(.gray4)
                    .font(.pretendardMedium(size: 14))
            }
            .padding(.vertical, 6)
            .padding(.leading, 10)
            .padding(.trailing, 12)
            .background(Color.white)
            .cornerRadius(10)
        }
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(spotAddViewModel.tagFilter, id:\.self){ tag in
                    toggleFilterButton(title: tag)
                }
            } // : HStack
            .padding(.leading, 16)
            .padding(.bottom, 14)
        } // : ScrollView
    }
}

#Preview {
    SpotAddView(spotAddViewModel: SpotAddViewModel())
        .environmentObject(NavigationManager())
}
