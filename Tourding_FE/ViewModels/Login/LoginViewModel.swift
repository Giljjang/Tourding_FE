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
                        Task { @MainActor in
                            switch credentialState {
                            case .authorized:
                                self?.isLoggedIn = true
                                self?.userNickname = appleUserInfo.name ?? "Apple User"
                                self?.userEmail = appleUserInfo.email ?? ""
                                // 서버에서 사용자 정보도 가져오기
                                self?.loadUserFromServer()
                            case .revoked, .notFound:
                                // 로그인 정보 삭제
                                KeychainHelper.clearAppleUserInfo()
                                self?.isLoggedIn = false
                            default:
                                self?.isLoggedIn = false
                            }
                        }
                    }
                } else {
                    self.isLoggedIn = false
                }
            }
        }
    }
    
    private func loadUserFromServer() {
        guard let uid = KeychainHelper.loadUid() else {
            print("❌ 서버에서 사용자 정보 로드 실패: UID 없음")
            return
        }
        
        // 서버에서 사용자 정보를 가져오는 로직
        // 현재는 키체인에 저장된 정보를 사용
        self.currentUser = CreateUserResponse(
            id: uid,
            name: userNickname,
            email: userEmail
        )
        print("✅ 서버에서 사용자 정보 로드 성공: \(String(describing: self.currentUser))")
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
            
            // 사용자 정보를 먼저 가져온 후 서버에 등록
            self.fetchUserInfoAndRegister()
        }
    }
    
    private func handleAppleLoginResult(authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            let authorizationCode = appleIDCredential.authorizationCode
            
            // 이름 처리 - 키체인에 저장된 정보 우선 사용
            var displayName = ""
            if let savedName = KeychainHelper.load(key: "appleUserName") {
                displayName = savedName
                print("📱 키체인에서 이름 로드: \(displayName)")
            } else if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                displayName = "\(familyName)\(givenName)"
            } else if let givenName = fullName?.givenName {
                displayName = givenName
            } else {
                displayName = "Apple User"
            }
            
            // 이메일 처리 - 키체인에 저장된 정보 우선 사용
            var userEmail = ""
            if let savedEmail = KeychainHelper.load(key: "appleUserEmail") {
                userEmail = savedEmail
                print("📱 키체인에서 이메일 로드: \(userEmail)")
            } else {
                userEmail = email ?? ""
            }
            
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
    
    /// 카카오 사용자 정보를 가져온 후 서버에 등록
    func fetchUserInfoAndRegister() {
        UserApi.shared.me { user, error in
            if let error = error {
                print("❌ 사용자 정보 요청 실패: \(error)")
            } else if let user = user {
                Task { @MainActor in
                    self.userNickname = user.kakaoAccount?.profile?.nickname ?? ""
                    self.userEmail = user.kakaoAccount?.email ?? ""
                    
                    print("✅ 사용자 정보 요청 성공")
                    print("닉네임: \(String(describing: user.kakaoAccount?.profile?.nickname))")
                    print("이메일: \(String(describing: user.kakaoAccount?.email))")
                    
                    // 사용자 정보 설정 후 서버에 등록
                    self.addUserToServer()
                }
            }
        }
    }
    
    func addUserToServer() {
          Task { [weak self] in
              do {
                  try Task.checkCancellation()
                  let req = CreateUserRequest(username: self?.userNickname ?? "", email: self?.userEmail ?? "")
                  let created = try await userRepository.createUser(req)
                  // 앱 전역에서 쓰도록 uid Keychain 저장
                  KeychainHelper.saveUid(key: created.id)

                  try Task.checkCancellation()
                  await MainActor.run {
                      self?.currentUser = CreateUserResponse(
                          id: created.id,
                          name: created.name,
                          email: created.email
                      )
                  }
                  print("✅ 서버 유저 등록 성공: \(String(describing: self?.currentUser))")
              } catch is CancellationError {
                  print("🚫 사용자 등록 Task 취소됨")
              } catch {
                  print("❌ 서버 유저 등록 실패: \(error)")
              }
          }
      }
    
    func addAppleUserToServer() {
        Task { [weak self] in
            do {
                try Task.checkCancellation()
                let req = CreateUserRequest(username: self?.userNickname ?? "", email: self?.userEmail ?? "")
                let created = try await userRepository.createUser(req)
                // 앱 전역에서 쓰도록 uid Keychain 저장
                KeychainHelper.saveUid(key: created.id)
                
                // 애플 로그인 provider 정보도 키체인에 저장
                KeychainHelper.save(key: "loginProvider", value: "apple")

                try Task.checkCancellation()
                await MainActor.run {
                    self?.currentUser = CreateUserResponse(
                        id: created.id,
                        name: created.name,
                        email: created.email
                    )
                }
                print("✅ 애플 서버 유저 등록 성공: \(String(describing: self?.currentUser))")
            } catch is CancellationError {
                print("🚫 애플 사용자 등록 Task 취소됨")
            } catch {
                print("❌ 애플 서버 유저 등록 실패: \(error)")
            }
        }
    }
    
    /// 서버에서 현재 사용자 삭제
      func deleteUserFromServer() {
          Task { [weak self] in
              guard let id = KeychainHelper.loadUid() else {
                  print("❌ 삭제 실패: currentUser.id 없음")
                  return
              }
              do {
                  try Task.checkCancellation()
                  try await userRepository.deleteUser(id: id)
                  KeychainHelper.deleteUid()
                  print("✅ 서버 유저 삭제 성공")
                  
              } catch is CancellationError {
                  print("🚫 사용자 삭제 Task 취소됨")
              } catch {
                  print("❌ 서버 유저 삭제 실패: \(error)")
              }
          }
      }
    
    /// 로그아웃 처리
    func logout() {
        print("🔍 현재 로그인 provider: '\(loginProvider)'")
        print("🔍 키체인에서 로드한 provider: '\(KeychainHelper.load(key: "loginProvider") ?? "nil")'")
        
        if loginProvider == "kakao" {
            print("📱 카카오 로그아웃 시작")
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
            print("🍎 애플 로그아웃 시작")
            // 애플 로그아웃 (이름과 이메일은 보존, 서버 관련 정보만 삭제)
            KeychainHelper.delete(key: "appleUserId")
            KeychainHelper.delete(key: "appleAuthorizationCode")
            // loginProvider도 삭제하여 로그인 상태 해제
            KeychainHelper.delete(key: "loginProvider")
        } else {
            print("❌ 알 수 없는 provider: '\(loginProvider)'")
            // provider가 설정되지 않은 경우 키체인에서 다시 확인
            if let savedProvider = KeychainHelper.load(key: "loginProvider") {
                print("🔄 키체인에서 provider 재설정: '\(savedProvider)'")
                self.loginProvider = savedProvider
                if savedProvider == "kakao" {
                    print("📱 카카오 로그아웃 시작 (재설정)")
                    UserApi.shared.logout { error in
                        if let error = error {
                            print("❌ 카카오 로그아웃 실패: \(error)")
                        } else {
                            print("✅ 카카오 로그아웃 성공")
                        }
                    }
                    clearKakaoTokens()
                } else if savedProvider == "apple" {
                    print("🍎 애플 로그아웃 시작 (재설정)")
                    KeychainHelper.delete(key: "appleUserId")
                    KeychainHelper.delete(key: "appleAuthorizationCode")
                    KeychainHelper.delete(key: "loginProvider")
                }
            }
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
    
    /// 통합 회원탈퇴 처리 (provider에 따라 다르게 처리)
    func revokeAccount() {
        print("🔍 현재 로그인 provider: '\(loginProvider)'")
        print("🔍 키체인에서 로드한 provider: '\(KeychainHelper.load(key: "loginProvider") ?? "nil")'")
        
        if loginProvider == "kakao" {
            print("📱 카카오 회원탈퇴 시작")
            revokeKakaoAccount()
        } else if loginProvider == "apple" {
            print("🍎 애플 회원탈퇴 시작")
            revokeAppleAccount()
        } else {
            print("❌ 알 수 없는 provider: '\(loginProvider)'")
            // provider가 설정되지 않은 경우 키체인에서 다시 확인
            if let savedProvider = KeychainHelper.load(key: "loginProvider") {
                print("🔄 키체인에서 provider 재설정: '\(savedProvider)'")
                self.loginProvider = savedProvider
                if savedProvider == "kakao" {
                    revokeKakaoAccount()
                } else if savedProvider == "apple" {
                    revokeAppleAccount()
                }
            }
        }
    }
    
    /// 카카오 회원탈퇴 처리
    private func revokeKakaoAccount() {
        Task {
            do {
                // 1. 서버에서 사용자 삭제
                guard let uid = KeychainHelper.loadUid() else {
                    print("❌ 카카오 회원탈퇴 실패: UID 없음")
                    return
                }
                
                try await userRepository.deleteUser(id: uid)
                print("✅ 서버에서 카카오 사용자 삭제 성공")
                
                // 2. 카카오 계정 연결 해제
                UserApi.shared.unlink { error in
                    if let error = error {
                        print("❌ 카카오 계정 연결 해제 실패: \(error)")
                    } else {
                        print("✅ 카카오 계정 연결 해제 성공")
                    }
                }
                
                // 3. 로컬 데이터 정리
                clearKakaoTokens()
                KeychainHelper.deleteUid()
                
                await MainActor.run {
                    isLoggedIn = false
                    userNickname = "홍길동"
                    userEmail = "Tourding@example.com"
                    loginProvider = ""
                    currentUser = nil
                }
                
                print("✅ 카카오 회원탈퇴 완료")
                
            } catch {
                print("❌ 카카오 회원탈퇴 실패: \(error)")
            }
        }
    }
    
    /// 애플 회원탈퇴 처리
    private func revokeAppleAccount() {
        Task {
            do {
                // 1. 서버에서 애플 계정 취소 요청
                guard let userId = KeychainHelper.loadUid(),
                      let authorizationCode = KeychainHelper.load(key: "appleAuthorizationCode") else {
                    print("❌ 애플 회원탈퇴 실패: 사용자 ID 또는 Authorization Code 없음")
                    return
                }
                
                try await userRepository.revokeUser(userId: userId, authorizationCode: authorizationCode)
                print("✅ 서버에서 애플 계정 취소 성공")
                
                // 2. 로컬 데이터 정리 (이름과 이메일은 보존)
                // 애플 로그인 특성상 기기에서 계속 기억하므로, 이름과 이메일은 유지
                KeychainHelper.delete(key: "appleUserId")
                KeychainHelper.delete(key: "appleAuthorizationCode")
                KeychainHelper.deleteUid()
                // loginProvider도 삭제하여 로그인 상태 해제
                KeychainHelper.delete(key: "loginProvider")
                
                await MainActor.run {
                    isLoggedIn = false
                    userNickname = "홍길동"
                    userEmail = "Tourding@example.com"
                    loginProvider = ""
                    currentUser = nil
                }
                
                print("✅ 애플 회원탈퇴 완료")
                
            } catch {
                print("❌ 애플 회원탈퇴 실패: \(error)")
            }
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
        // 안전한 윈도우 찾기
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        
        // 윈도우를 찾을 수 없는 경우 대체 윈도우 생성
        print("⚠️ 기본 윈도우를 찾을 수 없어 새 윈도우를 생성합니다.")
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let newWindow = UIWindow(windowScene: windowScene)
            newWindow.makeKeyAndVisible()
            return newWindow
        }
        
        // 최후의 수단: 임시 윈도우 생성
        print("⚠️ 윈도우 씬을 찾을 수 없어 임시 윈도우를 생성합니다.")
        let tempWindow = UIWindow(frame: UIScreen.main.bounds)
        tempWindow.makeKeyAndVisible()
        return tempWindow
    }
}

