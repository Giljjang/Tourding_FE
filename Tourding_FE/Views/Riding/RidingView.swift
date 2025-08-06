//
//  RidingView.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import SwiftUI

struct RidingView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject private var viewModel: RidingViewModel
    
    init(viewModel: RidingViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 배경 컨텐츠
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                CustomBottomSheet(
                    content: sheetContent,
                    screenHeight: geometry.size.height
                )
                
                backButton
                
                ridingStartButtom
                
            } // : ZStack
        } // : GeometryReader
        .navigationBarBackButtonHidden()
    }
    
    //MARK: - View
    private var backButton: some View {
        Button(action:{
            navigationManager.pop()
        }){
            Image("riding_back")
                .padding(.vertical, 8)
                .padding(.leading, 6)
                .padding(.trailing,10)
                .background(Color.white)
                .cornerRadius(30)
        }
        .position(x: 36, y: 53)
    } // : backButton
    
    private var ridingStartButtom: some View {
        Button(action:{}){
            Text("라이딩 시작하기")
                .foregroundColor(.white)
                .font(.pretendardSemiBold(size: 16))
                .frame(height: 22)
                .padding(.vertical, 16)
                .padding(.horizontal, 130.5)
                .background(Color.gray5)
                .cornerRadius(10)
        }
        .padding(.bottom, 18)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .white.opacity(0), location: 0.00),
                    Gradient.Stop(color: .white, location: 0.15),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        ) // : background
    } // : ridingStartButtom
    
    private var sheetContent: some View {
        VStack(alignment: .leading,spacing: 0) {
            // 헤더
            HStack(alignment: .top , spacing: 0) {
                Text("라이딩 코스")
                    .foregroundColor(.gray6)
                    .font(.pretendardSemiBold(size: 20))
                    .padding(.leading, 17)
                    
                Spacer()
                
                Button(action:{}){
                    Image("icon_plus")
                    Text("스팟 추가")
                        .foregroundColor(.gray6)
                        .font(.pretendardSemiBold(size: 16))
                }
                .padding(.top, 1)
                .padding(.trailing, 16)
            } // : HStack
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 19)
            
            Divider()
                .frame(maxWidth:.infinity)
                .foregroundColor(.gray1)
                .padding(.horizontal, 16)
            
            // 컨텐츠
            
            Spacer()
        } // : VStack
        .padding(.top, 8)
    } // : sheetContent
}

#Preview {
    RidingView(viewModel: RidingViewModel())
        .environmentObject(NavigationManager())
}
