//
//  HomeView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var modalManager: ModalManager
    @EnvironmentObject var routeSharedManager: RouteSharedManager
    @EnvironmentObject private var ridingViewModel: RidingViewModel
    
    
    @ObservedObject private var viewModel: HomeViewModel
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }
    
    enum HomeMenu {
        case header
        case headerText
        case routeMaking
        case routeContinue
    }
    
    private let menus: [HomeMenu] = [
        .header,
        .headerText,
        .routeMaking,
        .routeContinue
    ]
    
    var body: some View {
        ZStack{
            VStack(alignment: .leading,spacing:0){
                
                ForEach(menus, id:\.self) { menu in
                    switch menu {
                    case .header:
                        header
                    case .headerText:
                        headerText
                    case .routeMaking:
                        routeMaking
                    case .routeContinue:
                        routeContinue
                    }
                }//ForEach
                
                Spacer()
                
            } // : VStack
            .padding(.horizontal, 16)
            .background(Color.gray1)
            
            if modalManager.isToastMessage {
                ToastMessageView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .offset(y: 243)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeInOut) {
                                modalManager.isToastMessage = false
                            }
                        }
                    }
            } // : if modalManager.isToastMessage
        } // :Zstack
        .animation(.easeInOut, value: modalManager.isToastMessage)
    }
    
    //MARK: - View
    
    private var header: some View {
        HStack(alignment: .top) {
            Image("home_logo")
                .padding(.top, 26)
            
            Spacer()
        } // : HStack
        .padding(.bottom, 67.93)
    } // : header
    
    private var headerText: some View {
        Text("여행할 곳을 선택하고\n라이딩을 시작해요")
            .foregroundColor(Color.gray6)
            .font(.pretendardSemiBold(size: 26))
            .padding(.bottom, 26)
    } // : headerText
    
    private var routeMaking: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image("startpoint")
                    .overlay {
                        Image("dot_line")
                            .offset(y:43)
                    } // :overlay
                
                Text("출발지")
                    .foregroundColor(.gray4)
                    .font(.pretendardMedium(size: 16))
                
                Spacer()
            } // :HStack
            .padding(.top, 29)
            .padding(.leading, 20)
            
            VStack(alignment: .leading) {
                Button(action:{
                    routeSharedManager.currentSelectionMode = .startLocation
                    navigationManager.push(.DestinationSearchView)
                }){
                    Text(routeSharedManager.routeData.startLocation.isEmpty ? "출발지를 입력해주세요" : "\(routeSharedManager.routeData.startLocation.name)")
                        .foregroundColor(routeSharedManager.routeData.startLocation.isEmpty ? .gray2 : .gray6)
                        .font(.pretendardMedium(size: 18))
                }
                .padding(.top, 11)
                
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 285, height: 2)
                    .background(Color.gray1)
                
            } // : VStack
            .frame(width: 288, height: 48)
            .padding(.leading, 48)
            .padding(.bottom, 17)
            
            HStack(spacing: 6) {
                Image("endpoint")
                
                Text("도착지")
                    .foregroundColor(.gray4)
                    .font(.pretendardMedium(size: 16))
                
                Spacer()
            } // :HStack
            .padding(.leading, 20)
            
            VStack(alignment: .leading) {
                Button(action:{
                    routeSharedManager.currentSelectionMode = .endLocation
                    navigationManager.push(.DestinationSearchView)
                }){
                    Text(routeSharedManager.routeData.endLocation.isEmpty ? "도착지를 입력해주세요" : "\(routeSharedManager.routeData.endLocation.name)")
                        .foregroundColor(routeSharedManager.routeData.endLocation.isEmpty ? .gray2 : .gray6)
                        .font(.pretendardMedium(size: 18))
                }
                .padding(.top, 11)
                
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 285, height: 2)
                    .background(Color.gray1)
                
            } // : VStack
            .frame(width: 288, height: 48)
            .padding(.leading, 48)
            .padding(.bottom, 31)
            
            Button(action: {
                routeSharedManager.printCurrentRouteState()
                navigationManager.push(.RidingView)
            }){
                Text("코스 만들기")
                    .foregroundColor(routeSharedManager.hasValidPoints ? .white : .gray3)
                    .font(.pretendardSemiBold(size: 16))
                    .padding(.vertical, 15)
                    .padding(.horizontal, 124)
                    .background(routeSharedManager.hasValidPoints ? .gray5 : Color.gray2)
                    .cornerRadius(10)
            } // :Button
            .disabled(!routeSharedManager.hasValidPoints)
            .padding(.leading, 20)
            .padding(.bottom, 20)
            
        } // : VStack
        .frame(height: 294)
        .background(.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 6)
        .padding(.bottom, 14)
    } // : routeMaking
    
    private var routeContinue: some View {
        Button(action: {
            //modal test code
            navigationManager.push(.RidingView)
        }) {
            HStack(alignment: .top, spacing: 0) {
                Image("route")
                    .padding(.vertical, 29)
                    .padding(.leading, 20)
                    .padding(.trailing, 14)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 2) {
                        Text("한동대")
                            .foregroundColor(.gray4)
                            .font(.pretendardMedium(size: 14))
                        
                        Image("icon_right")
                        
                        Text("영남대")
                            .foregroundColor(.gray4)
                            .font(.pretendardMedium(size: 14))
                        
                    } // : HStack
                    .frame(height: 22)
                    
                    Text("최근 경로 이어서 가기")
                        .foregroundColor(.gray6)
                        .font(.pretendardSemiBold(size: 16))
                        .frame(height: 22)
                } // : VStack
                .frame(height: 44)
                .padding(.vertical, 19)
                
                Spacer()
                
                Image("chevron-right")
                    .padding(.vertical, 27)
                    .padding(.trailing, 24)
            } // : HStack
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 6)
            
        } // :Button
    } // : routeContinue
    
    private var overlayBackground: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(testRepository: TestRepository()))
        .environmentObject(NavigationManager())
        .environmentObject(RouteSharedManager())
}
