//
//  DetailSpotView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import SwiftUI

struct DetailSpotView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    
    @StateObject private var detailViewModel: DetailSpotViewModel
    
    @State private var currentPosition: DetailBottomSheetPosition = .standard
    
    init(detailViewModel: DetailSpotViewModel) {
        self._detailViewModel = StateObject(wrappedValue: detailViewModel)
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
                
                DetailBottomSheet(
                    content: SheetDetailView(),
                    screenHeight: geometry.size.height,
                    currentPosition: $currentPosition
                )
                
                if currentPosition == .large {
                    largeTopBar(geometry: geometry)

                }
                
                backButton
                
                //커스텀 모달
                if modalManager.isPresented && modalManager.showView == .detail {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            modalManager.hideModal()
                        }
                    
                    CustomModalView(modalManager: modalManager)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
                
                if detailViewModel.isLoading {
                    Color.white.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack{
                        Spacer()
                        
                        DotsLoadingView()
                        
                        Spacer()
                    }
                }// if 로딩 상태
                
            } // :ZStack
        } // :GeometryReader
        .ignoresSafeArea()
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
        .position(x: 36, y: 73)
    } // : backButton
    
    private func largeTopBar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                
                Spacer()
            }
            .frame(
                height: geometry.size.height
                      - currentPosition.height(screenHeight: geometry.size.height)
                      + geometry.safeAreaInsets.top
            )
            .background(Color.white)
            .offset(y: geometry.safeAreaInsets.top)
            .shadow(color: Color(red: 0.71, green: 0.76, blue: 0.81).opacity(0.15), radius: 5, x: 0, y: 4)
            
            Rectangle()
                .fill(Color.white)
                .frame(height: 4)
                .offset(y: geometry.safeAreaInsets.top - 4)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    DetailSpotView(detailViewModel: DetailSpotViewModel())
        .environmentObject(NavigationManager())
        .environmentObject(ModalManager())
}
