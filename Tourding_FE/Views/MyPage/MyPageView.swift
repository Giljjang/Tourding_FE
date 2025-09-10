//
//  MyPageView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct MyPageView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel  // 글로벌 로그인 상태 ViewModel
    @ObservedObject var myPageViewModel: MyPageViewModel // 마이페이지 ViewModel
    @EnvironmentObject var modalManager: ModalManager
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject var recentSearchViewModel : RecentSearchViewModel
    @EnvironmentObject var routeSharedManager: RouteSharedManager

    
    init(viewModel: MyPageViewModel, recentSearchViewModel: RecentSearchViewModel) {
        self.myPageViewModel = viewModel
        self.recentSearchViewModel = recentSearchViewModel
    }
    
    var body: some View {
        ZStack{
            VStack(alignment: .leading, spacing: 0,) {
                
                headerText
                headerView
                    .padding(.bottom, 16)
                
                CustomButtonView.withNavigation(
                    title: "개인정보처리방침",
                    destination: .ServiceView,
                    navigationManager: navigationManager
                )
                .padding(.bottom, 6)
                
                Divider()
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .padding(.bottom, 6)
                    .foregroundColor(Color.gray1)
                
                CustomButtonView(title: "로그아웃") {
                    print("로그아웃 클릭됨")
                    modalManager.showModal(
                        title: "로그아웃하시겠어요?",
                        subText: "회원 정보는 그대로 보관돼요.",
                        activeText: "로그아웃",
                        showView: .tabView,
                        onCancel: {
                            print("취소됨")
                        },
                        onActive: {
                            if let provider = KeychainHelper.load(key: "loginProvider") {
                                
                                if provider == "kakao" {
                                    myPageViewModel.logout(globalLoginViewModel: loginViewModel)
                                } else {
                                    
                                    myPageViewModel.AppleLogout(globalLoginViewModel: loginViewModel)
                                }
                                navigationManager.currentTab = .HomewView
                                routeSharedManager.clearRoute()
                                print("로그아웃됨")
                            }
                        }
                    )
                }
                .padding(.bottom, 6)
                
                Divider()
                    .frame(height: 1)
//                    .foregroundColor(Color.gray1)
                    .background(Color.gray1)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .padding(.bottom, 6)
                
                CustomButtonView(title: "회원탈퇴") {
                    print("회원탈퇴 클릭됨")
                    modalManager.showModal(
                        title: "탈퇴하시겠어요?",
                        subText: "탈퇴시 삭제되는 정보는 복구 불가능해요.",
                        activeText: "탈퇴하기",
                        showView: .tabView,
                        onCancel: {
                            print("취소됨")
                        },
                        onActive: {
//                            myPageViewModel.withdraw(globalLoginViewModel: loginViewModel)
                            recentSearchViewModel.clear()
                            navigationManager.currentTab = .HomewView
                            routeSharedManager.clearRoute()
                            loginViewModel.revokeAccount()
                            print("회원탈퇴됨")
                        }
                    )
                }
                Spacer()
            } // : VStack
        }
        .background(Color.customwhite)
    }
    
    //MARK: - View
    
    private var headerText: some View {
        Text("내 정보")
            .foregroundColor(Color.gray6)
            .font(.pretendardSemiBold(size: 26))
            .padding(.bottom, 26)
            .padding(.top, 70)
            .padding(.leading, 16)
    } // : headerText
    
    var headerView: some View {
        HStack{
            VStack(alignment: .leading){
                Text("\(loginViewModel.userNickname)님, 반가워요!")
                    .font(.pretendardSemiBold(size: 20))
                    .foregroundColor(.white)
                    .padding(.bottom, 2)
                Text("\(loginViewModel.userEmail)")
                    .font(.pretendardRegular(size: 14))
                    .foregroundColor(.white)
            } // : VStack
            .padding(.leading, 18)
            
            Spacer()  // 여백을 밀어주기 위해 Spacer 사용
            
            VStack {
                Spacer()  // 이미지 위에 Spacer를 넣어서 아래로 밀기
                Image("my_bike")
            }
            .padding(.trailing, 30)
        } // : HStack
        .frame(height: 91)
        .frame(maxWidth: .infinity)
        .background(Color.gray5)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        
    }
}

#Preview {
    
    let myPageViewModel = MyPageViewModel() // 마이페이지 ViewModel
    let recentSearchViewModel = RecentSearchViewModel()

    MyPageView(viewModel: myPageViewModel, recentSearchViewModel: recentSearchViewModel)
        .environmentObject(NavigationManager())
        .environmentObject(LoginViewModel())
}
