//
//  LoginViewModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/4/25.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import AuthenticationServices

@MainActor
class LoginViewModel: NSObject, ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userNickname: String = "홍길동"
    @Published var userEmail: String = "Tourding@example.com"
    @Published var currentUser: CreateUserResponse? = nil   // ✅ 전역에서 쓰기 위한 모델
    @Published var loginProvider: String = ""  // "kakao" 또는 "apple"
    
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
        super.init()
        checkExistingLogin()
    }
    
    private func checkExistingLogin() {
        // 저장된 로그인 provider 확인
        if let provider = KeychainHelper.load(key: "loginProvider") {
            self.loginProvider = provider
            
            if provider == "kakao" {
                // 카카오 로그인 상태 확인
                loadKakaoToken { [weak self] isLoggedIn in
                    if isLoggedIn {
                        self?.isLoggedIn = true
                        self?.fetchUserInfo()
                    }
                }
            } else if provider == "apple" {
                // 애플 로그인 상태 확인
                let appleUserInfo = KeychainHelper.loadAppleUserInfo()
                if let userId = appleUserInfo.userId {
                    // 애플 ID 상태 확인
                    let appleIDProvider = ASAuthorizationAppleIDProvider()
                    appleIDProvider.getCredentialState(forUserID: userId) { [weak self] credentialState, error in
                        DispatchQueue.main.async {
                            switch credentialState {
                            case .authorized:
                                self?.isLoggedIn = true
                                self?.userNickname = appleUserInfo.name ?? "Apple User"
                                self?.userEmail = appleUserInfo.email ?? ""
                            case .revoked, .notFound:
                                // 로그인 정보 삭제
                                KeychainHelper.clearAppleUserInfo()
                                self?.isLoggedIn = false
                            default:
                                self?.isLoggedIn = false
                            }
                        }
                    }
                }
            }
        }
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
    
    func loginWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func handleLoginResult(oauthToken: OAuthToken?, error: Error?) {
        if let error = error {
            print("❌ 로그인 실패: \(error)")
        } else if let token = oauthToken {
            print("✅ 로그인 성공!")
            print("accessToken: \(token.accessToken)")
            saveKakaoToken(token: token)
            KeychainHelper.save(key: "loginProvider", value: "kakao")
            self.loginProvider = "kakao"
            self.isLoggedIn = true
            self.fetchUserInfo()
            self.addUserToServer()
        }
    }
    
    private func handleAppleLoginResult(authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            let authorizationCode = appleIDCredential.authorizationCode
            
            // 이름 처리 (fullName이 nil일 수 있음)
            var displayName = ""
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                displayName = "\(familyName)\(givenName)"
            } else if let givenName = fullName?.givenName {
                displayName = givenName
            } else {
                displayName = "Apple User"
            }
            
            // 이메일 처리 (첫 로그인에서만 제공됨)
            let userEmail = email ?? ""
            
            print("✅ 애플 로그인 성공!")
            print("User ID: \(userIdentifier)")
            print("Name: \(displayName)")
            print("Email: \(userEmail)")
            
            // authorizationCode 저장 (회원탈퇴 시 필요)
            if let authCode = authorizationCode {
                let authCodeString = String(data: authCode, encoding: .utf8) ?? ""
                KeychainHelper.save(key: "appleAuthorizationCode", value: authCodeString)
                print("Authorization Code 저장됨")
            }
            
            // 애플 로그인 정보를 키체인에 저장
            KeychainHelper.saveAppleUserInfo(userId: userIdentifier, name: displayName, email: userEmail)
            
            self.userNickname = displayName
            self.userEmail = userEmail
            self.loginProvider = "apple"
            self.isLoggedIn = true
            
            // 서버에 유저 추가
            self.addAppleUserToServer()
        }
    }
    
    func fetchUserInfo() {
        UserApi.shared.me { user, error in
            if let error = error {
                print("❌ 사용자 정보 요청 실패: \(error)")
            } else if let user = user {
                Task { @MainActor in
                    self.userNickname = user.kakaoAccount?.profile?.nickname ?? ""
                    self.userEmail = user.kakaoAccount?.email ?? ""
                }
                print("✅ 사용자 정보 요청 성공")
                print("닉네임: \(String(describing: user.kakaoAccount?.profile?.nickname))")
                print("이메일: \(String(describing: user.kakaoAccount?.email))")
                print("✅ 서버 유저 등록되어있는 아이디는: \(String(describing: self.currentUser?.id))")
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

                  await MainActor.run {
                      self.currentUser = CreateUserResponse(
                          id: created.id,
                          name: created.name,
                          email: created.email
                      )
                  }
                  print("✅ 서버 유저 등록 성공: \(String(describing: self.currentUser))")
              } catch {
                  print("❌ 서버 유저 등록 실패: \(error)")
              }
          }
      }
    
    func addAppleUserToServer() {
        Task {
            do {
                let req = CreateUserRequest(username: userNickname, email: userEmail)
                let created = try await userRepository.createUser(req)
                // 앱 전역에서 쓰도록 uid Keychain 저장
                KeychainHelper.saveUid(key: created.id)
                
                // 애플 로그인 provider 정보도 키체인에 저장
                KeychainHelper.save(key: "loginProvider", value: "apple")

                await MainActor.run {
                    self.currentUser = CreateUserResponse(
                        id: created.id,
                        name: created.name,
                        email: created.email
                    )
                }
                print("✅ 애플 서버 유저 등록 성공: \(String(describing: self.currentUser))")
            } catch {
                print("❌ 애플 서버 유저 등록 실패: \(error)")
            }
        }
    }
    
    /// 서버에서 현재 사용자 삭제
      func deleteUserFromServer() {
          Task {
              guard let id = KeychainHelper.loadUid() else {
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
    
    /// 로그아웃 처리
    func logout() {
        if loginProvider == "kakao" {
            // 카카오 로그아웃
            UserApi.shared.logout { error in
                if let error = error {
                    print("❌ 카카오 로그아웃 실패: \(error)")
                } else {
                    print("✅ 카카오 로그아웃 성공")
                }
            }
            clearKakaoTokens()
        } else if loginProvider == "apple" {
            // 애플 로그아웃 (로컬 데이터만 정리)
            KeychainHelper.clearAppleUserInfo()
        }
        
        // 공통 로그아웃 처리
        KeychainHelper.deleteUid()
        isLoggedIn = false
        userNickname = "홍길동"
        userEmail = "Tourding@example.com"
        loginProvider = ""
        currentUser = nil
        print("✅ 로그아웃 완료")
    }
    
    /// 애플 회원탈퇴 처리
    func revokeAppleAccount() {
        // 1. 서버에서 사용자 삭제
        deleteUserFromServer()
        
        // 2. 애플 계정 취소 요청
        if let appleUserId = KeychainHelper.load(key: "appleUserId") {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            // authorizationCode는 애플에서 제공하는 것이므로, 
            // 실제로는 로그인 시 받은 authorizationCode를 저장해두어야 합니다.
            // 여기서는 서버에서 처리하도록 하겠습니다.
            
            // 3. 로컬 데이터 정리
            KeychainHelper.clearAppleUserInfo()
            KeychainHelper.deleteUid()
            isLoggedIn = false
            userNickname = "홍길동"
            userEmail = "Tourding@example.com"
            loginProvider = ""
            currentUser = nil
            
            print("✅ 애플 회원탈퇴 완료")
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension LoginViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleAppleLoginResult(authorization: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ 애플 로그인 실패: \(error)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension LoginViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}
