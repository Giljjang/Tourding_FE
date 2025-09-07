//
//  LoginViewModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/4/25.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userNickname: String = "홍길동"
    @Published var userEmail: String = "Tourding@example.com"
    @Published var currentUser: CreateUserResponse? = nil   // ✅ 전역에서 쓰기 위한 모델
    
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
    }
    
    func loginWithKakao() {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                self.handleLoginResult(oauthToken: oauthToken, error: error)
            }
        } else {
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                self.handleLoginResult(oauthToken: oauthToken, error: error)
            }
        }
    }
    
    private func handleLoginResult(oauthToken: OAuthToken?, error: Error?) {
        if let error = error {
            print("❌ 로그인 실패: \(error)")
        } else if let token = oauthToken {
            print("✅ 로그인 성공!")
            print("accessToken: \(token.accessToken)")
            saveKakaoToken(token: token)
            self.isLoggedIn = true
            self.fetchUserInfo()
            self.addUserToServer()
        }
    }
    
    func fetchUserInfo() {
        UserApi.shared.me { user, error in
            if let error = error {
                print("❌ 사용자 정보 요청 실패: \(error)")
            } else if let user = user {
                self.userNickname = user.kakaoAccount?.profile?.nickname ?? ""
                self.userEmail = user.kakaoAccount?.email ?? ""
                print("✅ 사용자 정보 요청 성공")
                print("닉네임: \(String(describing: self.userNickname))")
                print("이메일: \(String(describing: self.userEmail))")
            }
        }
    }
    
    func addUserToServer() {
          Task {
              do {
                  let req = CreateUserRequest(username: userNickname, email: userEmail)
                  let created = try await userRepository.createUser(req)
                  // 앱 전역에서 쓰도록 uid Keychain 저장
                  KeychainHelper.saveUid(key: created.id)

                  self.currentUser = CreateUserResponse(
                      id: created.id,
                      name: created.name,
                      email: created.email
                  )
                  print("✅ 서버 유저 등록 성공: \(String(describing: self.currentUser))")
                  print("✅ 서버 유저 등록한 아이디는: \(String(describing: self.currentUser?.id))")
              } catch {
                  print("❌ 서버 유저 등록 실패: \(error)")
              }
          }
      }
    
    /// 서버에서 현재 사용자 삭제
      func deleteUserFromServer() {
          Task {
              guard let id = currentUser?.id else {
                  print("❌ 삭제 실패: currentUser.id 없음")
                  return
              }
              do {
                  try await userRepository.deleteUser(id: id)
                  KeychainHelper.deleteUid()
                  print("✅ 서버 유저 삭제 성공")
                  
              } catch {
                  print("❌ 서버 유저 삭제 실패: \(error)")
              }
          }
      }
}
