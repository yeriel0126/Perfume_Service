import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: UserResponse?
    @Published var isAuthenticated = false
    @Published var error: Error?
    @Published var isLoading = false
    @Published var isInitializing = true
    
    private let apiClient = APIClient.shared
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Firebase Auth 상태 리스너 설정
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            Task { @MainActor in
                guard let self = self else { return }
                
                print("🔍 Firebase Auth 상태 변경: \(user?.email ?? "로그아웃")")
                
                if let firebaseUser = user {
                    // Firebase 사용자가 있으면 ID 토큰 갱신 및 저장
                    do {
                        let idToken = try await firebaseUser.getIDToken()
                        UserDefaults.standard.set(idToken, forKey: "authToken")
                        
                        // 백엔드에서 사용자 정보 가져오기
                        let backendUser = try await self.apiClient.getCurrentUser()
                        self.user = backendUser
                        self.isAuthenticated = true
                        
                                    // 사용자 정보를 UserDefaults에 저장
            UserDefaults.standard.set(backendUser.data.uid, forKey: "userId")
            UserDefaults.standard.set(backendUser.data.name ?? "사용자", forKey: "userName")
            // 시향 일기용 키도 추가로 저장
            UserDefaults.standard.set(backendUser.data.uid, forKey: "currentUserId")
            UserDefaults.standard.set(backendUser.data.name ?? "사용자", forKey: "currentUserName")
            UserDefaults.standard.set(backendUser.data.picture ?? "", forKey: "currentUserProfileImage")
                        
                        print("✅ 자동 로그인 성공: \(backendUser.data.name ?? "사용자")")
                    } catch {
                        print("❌ 사용자 정보 가져오기 실패: \(error)")
                        // 백엔드 오류 시 Firebase 로그아웃
                        try? Auth.auth().signOut()
                        self.user = nil
                        self.isAuthenticated = false
                        UserDefaults.standard.removeObject(forKey: "authToken")
                    }
                } else {
                    // Firebase 사용자가 없으면 로그아웃 상태
                    self.user = nil
                    self.isAuthenticated = false
                    UserDefaults.standard.removeObject(forKey: "authToken")
                    UserDefaults.standard.removeObject(forKey: "userId")
                    UserDefaults.standard.removeObject(forKey: "userName")
                    // 시향 일기용 키도 삭제
                    UserDefaults.standard.removeObject(forKey: "currentUserId")
                    UserDefaults.standard.removeObject(forKey: "currentUserName")
                    UserDefaults.standard.removeObject(forKey: "currentUserProfileImage")
                    print("🔍 로그아웃 상태")
                }
                
                self.isInitializing = false
            }
        }
    }
    
    func signInWithEmail(email: String, password: String) async {
        guard !email.isEmpty && !password.isEmpty else {
            self.error = APIError.invalidInput("이메일과 비밀번호를 입력해주세요.")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Firebase 이메일/비밀번호 로그인
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let idToken = try await authResult.user.getIDToken()
            
            // Firebase ID 토큰 저장
            UserDefaults.standard.set(idToken, forKey: "authToken")
            
            // 사용자 정보 가져오기
            let user = try await apiClient.getCurrentUser()
            self.user = user
            self.isAuthenticated = true
            
            // 사용자 정보를 UserDefaults에 저장
            UserDefaults.standard.set(user.data.uid, forKey: "userId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "userName")
            // 시향 일기용 키도 추가로 저장
            UserDefaults.standard.set(user.data.uid, forKey: "currentUserId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "currentUserName")
            UserDefaults.standard.set(user.data.picture ?? "", forKey: "currentUserProfileImage")
            // 시향일기 데이터 동기화 알림
            NotificationCenter.default.post(name: Notification.Name("UserLoggedIn"), object: nil)
            print("📢 [로그인] 데이터 동기화 알림 발송")
            
        } catch let apiError as APIError {
            print("❌ API 에러: \(apiError.localizedDescription)")
            
            // 502 에러의 경우 더 친화적인 메시지 제공
            if apiError.localizedDescription.contains("502") {
                self.error = APIError.serverError("현재 서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요.")
            } else {
                self.error = apiError
            }
            
            // 502 에러가 아닌 경우에만 토큰 삭제 (일시적 서버 문제로 인한 로그아웃 방지)
            if !apiError.localizedDescription.contains("502") {
                UserDefaults.standard.removeObject(forKey: "authToken")
            }
        } catch {
            self.error = APIError.serverError("로그인 중 오류가 발생했습니다: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        error = nil
        
        print("🔵 구글 로그인 시작")
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ Firebase 설정을 찾을 수 없음")
            self.error = APIError.serverError("Firebase 설정을 찾을 수 없습니다.")
            isLoading = false
            return
        }
        
        print("✅ Firebase 클라이언트 ID: \(clientID)")
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ 뷰 컨트롤러를 찾을 수 없음")
            self.error = APIError.serverError("앱의 뷰 컨트롤러를 찾을 수 없습니다.")
            isLoading = false
            return
        }
        
        do {
            print("🔵 구글 로그인 시도")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ 구글 ID 토큰을 받지 못함")
                self.error = APIError.serverError("구글 로그인 토큰을 받지 못했습니다.")
                isLoading = false
                return
            }
            
            print("✅ 구글 로그인 성공, ID 토큰 획득")
            
            // Firebase 인증
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: result.user.accessToken.tokenString)
            
            print("🔵 Firebase 인증 시도")
            let authResult = try await Auth.auth().signIn(with: credential)
            print("✅ Firebase 인증 성공")
            
            // Firebase ID 토큰 저장
            let firebaseIdToken = try await authResult.user.getIDToken()
            UserDefaults.standard.set(firebaseIdToken, forKey: "authToken")
            print("✅ Firebase ID 토큰 저장 완료")
            
            // 사용자 정보 가져오기
            print("🔵 사용자 정보 가져오기 시도")
            let user = try await apiClient.getCurrentUser()
            self.user = user
            self.isAuthenticated = true
            
            // 사용자 정보를 UserDefaults에 저장
            UserDefaults.standard.set(user.data.uid, forKey: "userId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "userName")
            // 시향 일기용 키도 추가로 저장
            UserDefaults.standard.set(user.data.uid, forKey: "currentUserId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "currentUserName")
            UserDefaults.standard.set(user.data.picture ?? "", forKey: "currentUserProfileImage")
            
            print("✅ 사용자 정보 가져오기 성공")
            
        } catch let error as APIError {
            print("❌ API 에러: \(error.localizedDescription)")
            
            // 502 에러의 경우 더 친화적인 메시지 제공
            if error.localizedDescription.contains("502") {
                self.error = APIError.serverError("현재 서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요.")
            } else {
                self.error = error
            }
            
            // 502 에러가 아닌 경우에만 토큰 삭제 (일시적 서버 문제로 인한 로그아웃 방지)
            if !error.localizedDescription.contains("502") {
                UserDefaults.standard.removeObject(forKey: "authToken")
            }
        } catch {
            print("❌ 구글 로그인 에러: \(error.localizedDescription)")
            self.error = APIError.serverError("구글 로그인 중 오류가 발생했습니다: \(error.localizedDescription)")
            // 인증 실패 시 토큰 삭제
            UserDefaults.standard.removeObject(forKey: "authToken")
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, name: String) async {
        print("🚀 [회원가입] 시작 - 이메일: \(email), 이름: \(name)")
        
        guard !email.isEmpty && !password.isEmpty && !name.isEmpty else {
            print("❌ [회원가입] 필수 필드 누락")
            self.error = APIError.invalidInput("모든 필드를 입력해주세요.")
            return
        }
        
        guard password.count >= 6 else {
            print("❌ [회원가입] 비밀번호 길이 부족: \(password.count)자")
            self.error = APIError.invalidInput("비밀번호는 6자 이상이어야 합니다.")
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            print("❌ [회원가입] 잘못된 이메일 형식: \(email)")
            self.error = APIError.invalidInput("올바른 이메일 형식이 아닙니다.")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            print("🔄 [회원가입] Firebase 계정 생성 중...")
            // Firebase 이메일/비밀번호 회원가입
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ [회원가입] Firebase 계정 생성 성공 - UID: \(authResult.user.uid)")
            
            print("🔄 [회원가입] 사용자 프로필 업데이트 중...")
            // 사용자 프로필 업데이트
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            print("✅ [회원가입] 사용자 프로필 업데이트 성공")
            
            print("🔄 [회원가입] Firebase ID 토큰 생성 중...")
            // Firebase ID 토큰 가져오기
            let idToken = try await authResult.user.getIDToken()
            print("✅ [회원가입] Firebase ID 토큰 생성 성공")
            
            // Firebase ID 토큰 저장
            UserDefaults.standard.set(idToken, forKey: "authToken")
            print("✅ [회원가입] 토큰 저장 완료")
            
            print("🔄 [회원가입] 서버에서 사용자 정보 가져오는 중...")
            // 사용자 정보 가져오기
            let user = try await apiClient.getCurrentUser()
            print("✅ [회원가입] 서버에서 사용자 정보 가져오기 성공")
            
            self.user = user
            self.isAuthenticated = true
            
            // 사용자 정보를 UserDefaults에 저장
            UserDefaults.standard.set(user.data.uid, forKey: "userId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "userName")
            // 시향 일기용 키도 추가로 저장
            UserDefaults.standard.set(user.data.uid, forKey: "currentUserId")
            UserDefaults.standard.set(user.data.name ?? "사용자", forKey: "currentUserName")
            UserDefaults.standard.set(user.data.picture ?? "", forKey: "currentUserProfileImage")
            
            print("✅ [회원가입] 전체 과정 완료 성공!")
            
        } catch let authError as NSError {
            print("❌ [회원가입] Firebase 인증 오류: \(authError.localizedDescription)")
            print("❌ [회원가입] 오류 코드: \(authError.code)")
            print("❌ [회원가입] 오류 도메인: \(authError.domain)")
            
            // Firebase Auth 오류 처리
            if authError.code == 17007 { // EMAIL_ALREADY_IN_USE
                self.error = APIError.invalidInput("이미 가입된 이메일입니다.")
            } else if authError.code == 17008 { // INVALID_EMAIL
                self.error = APIError.invalidInput("올바르지 않은 이메일 형식입니다.")
            } else if authError.code == 17026 { // WEAK_PASSWORD
                self.error = APIError.invalidInput("비밀번호가 너무 약합니다. 더 강한 비밀번호를 사용해주세요.")
            } else {
                self.error = APIError.serverError("회원가입 중 오류가 발생했습니다: \(authError.localizedDescription)")
            }
            
        } catch let apiError as APIError {
            print("❌ [회원가입] API 오류: \(apiError.localizedDescription)")
            self.error = apiError
            
        } catch {
            print("❌ [회원가입] 알 수 없는 오류: \(error.localizedDescription)")
            self.error = APIError.serverError("회원가입 중 알 수 없는 오류가 발생했습니다.")
        }
        
        isLoading = false
        print("🏁 [회원가입] 프로세스 종료")
    }
    
    func signOut() {
        print("🚪 [로그아웃] 시작...")
        
        // Firebase 로그아웃
        do {
            try Auth.auth().signOut()
            print("✅ [로그아웃] Firebase 로그아웃 완료")
        } catch {
            print("❌ [로그아웃] Firebase 로그아웃 실패: \(error)")
        }
        
        // 인증 관련 데이터만 삭제 (일기 데이터는 보존)
        let keysToRemove = [
            "authToken",
            "userId",
            "userName",
            "currentUserId",
            "currentUserName",
            "currentUserProfileImage"
            // "localDiaries"와 "diaryEntries" 제거하여 데이터 보존
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
            print("🗑️ [로그아웃] \(key) 삭제")
        }
        
        UserDefaults.standard.synchronize()
        
        // 상태 초기화
        self.isAuthenticated = false
        self.user = nil
        self.error = nil
        
        print("✅ [로그아웃] 완전 로그아웃 완료")
        // 로그아웃 알림 발송
        NotificationCenter.default.post(name: Notification.Name("UserLoggedOut"), object: nil)
        print("📢 [로그아웃] 알림 발송")
    }
    
    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil
        
        print("🍎 Apple 로그인 시작")
        
        do {
            let authorization = try result.get()
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                print("❌ Apple 인증 토큰을 가져올 수 없음")
                self.error = APIError.invalidInput("Apple 인증 토큰을 가져올 수 없습니다.")
                isLoading = false
                return
            }
            
            print("✅ Apple ID 토큰 획득")
            
            // 사용자 이름 처리 (첫 로그인시에만 제공됨)
            var userName = "사용자"
            if let fullName = appleIDCredential.fullName {
                let formatter = PersonNameComponentsFormatter()
                formatter.style = .long
                userName = formatter.string(from: fullName)
                print("🍎 사용자 이름: \(userName)")
                
                // Apple 사용자 정보 저장
                AppleSignInUtils.saveAppleUserInfo(
                    userID: appleIDCredential.user,
                    fullName: fullName,
    
                    
                    email: appleIDCredential.email
                )
            }
            
            
            // Firebase 인증 (nonce 없이 진행 - 개발 단계)
            let credential = OAuthProvider.credential(providerID: AuthProviderID.apple,
                                                    idToken: tokenString,
                                                    rawNonce: "")

            print("🔵 Firebase Apple 인증 시도")
            let authResult = try await Auth.auth().signIn(with: credential)
            print("✅ Firebase Apple 인증 성공")
            
            // Firebase ID 토큰 저장
            let firebaseIdToken = try await authResult.user.getIDToken()
            UserDefaults.standard.set(firebaseIdToken, forKey: "authToken")
            print("✅ Firebase ID 토큰 저장 완료")
            
            // 백엔드에 Apple 로그인 요청
            print("🔵 백엔드 Apple 로그인 요청")
            let _ = try await apiClient.appleLogin(idToken: tokenString)
            print("✅ 백엔드 Apple 로그인 성공")
            
            // 사용자 정보 가져오기
            print("🔵 사용자 정보 가져오기")
            let user = try await apiClient.getCurrentUser()
            self.user = user
            self.isAuthenticated = true
            
            // 사용자 정보를 UserDefaults에 저장
            UserDefaults.standard.set(user.data.uid, forKey: "userId")

            // ✅ 수정: 사용자가 직접 변경한 이름이 있으면 보호
            let userEditedName = UserDefaults.standard.string(forKey: "userEditedName")
            if userEditedName == nil || userEditedName!.isEmpty {
                // 사용자가 직접 변경한 이름이 없을 때만 Apple/서버 이름 사용
                UserDefaults.standard.set(user.data.name ?? userName, forKey: "userName")
                UserDefaults.standard.set(user.data.name ?? userName, forKey: "currentUserName")
                print("📝 [Apple 로그인] 서버 이름 사용: \(user.data.name ?? userName)")
            } else {
                print("🔒 [Apple 로그인] 사용자 편집 이름 보호: \(userEditedName!)")
                // currentUserName은 업데이트 (일기 작성 등에서 사용)
                UserDefaults.standard.set(userEditedName!, forKey: "currentUserName")
            }

            // 시향 일기용 키도 저장 (사용자 편집 이름 우선)
            UserDefaults.standard.set(user.data.uid, forKey: "currentUserId")
            let finalUserName = userEditedName ?? user.data.name ?? userName
            UserDefaults.standard.set(finalUserName, forKey: "currentUserName")
            UserDefaults.standard.set(user.data.picture ?? "", forKey: "currentUserProfileImage")

            print("✅ Apple 로그인 완료: \(finalUserName)")
            
        } catch let error as APIError {
            print("❌ Apple 로그인 API 에러: \(error.localizedDescription)")
            
            // 502 에러의 경우 더 친화적인 메시지 제공
            if error.localizedDescription.contains("502") {
                self.error = APIError.serverError("현재 서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요.")
            } else {
                self.error = error
            }
            
            // 502 에러가 아닌 경우에만 토큰 삭제
            if !error.localizedDescription.contains("502") {
                UserDefaults.standard.removeObject(forKey: "authToken")
            }
        } catch {
            print("❌ Apple 로그인 에러: \(error.localizedDescription)")
            self.error = APIError.serverError("Apple 로그인 중 오류가 발생했습니다: \(error.localizedDescription)")
            // 인증 실패 시 토큰 삭제
            UserDefaults.standard.removeObject(forKey: "authToken")
        }
        
        isLoading = false
            }
            
            func checkAuthStatus() async {
                print("🔐 [인증상태] 확인 시작...")
                
                guard let token = UserDefaults.standard.string(forKey: "authToken"),
                      !token.isEmpty else {
                    print("❌ [인증상태] 토큰 없음")
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.isLoading = false
                    }
                    return
                }
                
                print("🔐 [인증상태] 토큰 존재, 서버 검증 시도...")
                
                do {
                    // 서버에서 사용자 정보 가져와서 토큰 유효성 검증
                    let user = try await apiClient.getCurrentUser()
                    
                    await MainActor.run {
                        self.user = user
                        self.isAuthenticated = true
                        self.isLoading = false
                    }
                    
                    print("✅ [인증상태] 유효한 토큰, 자동 로그인 완료")
                    
                } catch {
                    print("❌ [인증상태] 토큰 무효, 로그아웃 처리: \(error)")
                    
                    // 무효한 토큰 삭제
                    let keysToRemove = [
                        "authToken",
                        "userId",
                        "userName",
                        "currentUserId",
                        "currentUserName",
                        "currentUserProfileImage"
                    ]
                    
                    for key in keysToRemove {
                        UserDefaults.standard.removeObject(forKey: key)
                    }
                    UserDefaults.standard.synchronize()
                    
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.isLoading = false
                        self.error = nil
                    }
                }
            }
}
