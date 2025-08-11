import Foundation
import AuthenticationServices

class AppleSignInUtils {
    
    /// Apple Sign In이 사용 가능한지 확인
    static func isAppleSignInAvailable() -> Bool {
        print("🔍 [AppleSignInUtils] Apple Sign In 사용 가능 여부 확인 시작")
        
        if #available(iOS 13.0, *) {
            print("✅ [AppleSignInUtils] iOS 13.0+ 지원됨")
            return true
        } else {
            print("❌ [AppleSignInUtils] iOS 버전이 13.0 미만")
            return false
        }
    }
    
    /// 현재 Apple ID 상태 확인
    static func checkAppleIDState(completion: @escaping (ASAuthorizationAppleIDProvider.CredentialState, Error?) -> Void) {
        print("🔍 [AppleSignInUtils] Apple ID 상태 확인 시작")
        
        let provider = ASAuthorizationAppleIDProvider()
        
        // UserDefaults에서 저장된 Apple ID 가져오기
        if let appleUserID = UserDefaults.standard.string(forKey: "appleUserID") {
            print("🔍 [AppleSignInUtils] 저장된 Apple User ID 발견: \(appleUserID)")
            
            provider.getCredentialState(forUserID: appleUserID) { state, error in
                print("🔍 [AppleSignInUtils] Apple ID 상태 확인 완료")
                print("🔍 [AppleSignInUtils] 상태: \(getAppleIDStateDescription(state))")
                
                if let error = error {
                    print("❌ [AppleSignInUtils] Apple ID 상태 확인 에러: \(error.localizedDescription)")
                } else {
                    print("✅ [AppleSignInUtils] Apple ID 상태 확인 성공")
                }
                
                DispatchQueue.main.async {
                    completion(state, error)
                }
            }
        } else {
            print("🔍 [AppleSignInUtils] 저장된 Apple User ID 없음")
            // 저장된 Apple ID가 없으면 .notFound 상태
            DispatchQueue.main.async {
                completion(.notFound, nil)
            }
        }
    }
    
    /// Apple ID 상태를 한국어로 변환
    static func getAppleIDStateDescription(_ state: ASAuthorizationAppleIDProvider.CredentialState) -> String {
        switch state {
        case .authorized:
            return "인증됨"
        case .revoked:
            return "취소됨"
        case .notFound:
            return "찾을 수 없음"
        case .transferred:
            return "이전됨"
        @unknown default:
            return "알 수 없음"
        }
    }
    
    /// Apple 로그인 요청 생성 (상세 로깅 포함)
    static func createAppleIDRequest() -> ASAuthorizationAppleIDRequest {
        print("🔍 [AppleSignInUtils] Apple ID 로그인 요청 생성 시작")
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        print("🔍 [AppleSignInUtils] 요청 스코프: fullName, email")
        print("✅ [AppleSignInUtils] Apple ID 로그인 요청 생성 완료")
        
        return request
    }
    
    /// ASAuthorizationController 시작 로깅
    static func logAuthorizationControllerStart() {
        print("🚀 [ASAuthorizationController] 인증 컨트롤러 시작")
        print("🚀 [ASAuthorizationController] 현재 시간: \(Date())")
        
        // 기기 정보 로깅
        print("📱 [기기정보] 모델: \(UIDevice.current.model)")
        print("📱 [기기정보] iOS 버전: \(UIDevice.current.systemVersion)")
        print("📱 [기기정보] 기기명: \(UIDevice.current.name)")
    }
    
    /// 인증 성공 시 상세 로깅
    static func logAuthorizationSuccess(_ credential: ASAuthorizationAppleIDCredential) {
        print("🎉 [Apple 로그인] 인증 성공!")
        print("🔍 [Apple 로그인] User ID: \(credential.user)")
        print("🔍 [Apple 로그인] Email: \(credential.email ?? "제공되지 않음")")
        print("🔍 [Apple 로그인] Full Name: \(credential.fullName?.description ?? "제공되지 않음")")
        print("🔍 [Apple 로그인] Identity Token 존재: \(credential.identityToken != nil)")
        print("🔍 [Apple 로그인] Authorization Code 존재: \(credential.authorizationCode != nil)")
        
        if let identityToken = credential.identityToken,
           let tokenString = String(data: identityToken, encoding: .utf8) {
            print("🔍 [Apple 로그인] Identity Token 길이: \(tokenString.count)자")
            print("🔍 [Apple 로그인] Identity Token 시작: \(String(tokenString.prefix(50)))...")
        }
        
        if let authCode = credential.authorizationCode,
           let codeString = String(data: authCode, encoding: .utf8) {
            print("🔍 [Apple 로그인] Authorization Code 길이: \(codeString.count)자")
            print("🔍 [Apple 로그인] Authorization Code 시작: \(String(codeString.prefix(50)))...")
        }
        
        // Real User Status 로깅
        if #available(iOS 13.0, *) {
            switch credential.realUserStatus {
            case .likelyReal:
                print("✅ [Apple 로그인] 실제 사용자 가능성: 높음")
            case .unknown:
                print("⚠️ [Apple 로그인] 실제 사용자 가능성: 알 수 없음")
            case .unsupported:
                print("⚠️ [Apple 로그인] 실제 사용자 감지 지원 안됨")
            @unknown default:
                print("❓ [Apple 로그인] 실제 사용자 가능성: 알 수 없는 상태")
            }
        }
    }
    
    /// 인증 실패 시 상세 로깅
    static func logAuthorizationFailure(_ error: Error) {
        print("❌ [Apple 로그인] 인증 실패")
        print("❌ [Apple 로그인] 에러: \(error.localizedDescription)")
        print("❌ [Apple 로그인] 에러 코드: \((error as NSError).code)")
        print("❌ [Apple 로그인] 에러 도메인: \((error as NSError).domain)")
        
        // 에러 코드별 상세 분석
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                print("📊 [Apple 로그인] 사용자가 취소함")
            case .failed:
                print("📊 [Apple 로그인] 인증 실패")
            case .invalidResponse:
                print("📊 [Apple 로그인] 잘못된 응답")
            case .notHandled:
                print("📊 [Apple 로그인] 처리되지 않음")
            case .unknown:
                print("📊 [Apple 로그인] 알 수 없는 에러")
            @unknown default:
                print("📊 [Apple 로그인] 알 수 없는 에러 코드")
            }
        }
        
        // UserInfo 로깅
        let userInfo = (error as NSError).userInfo
        if !userInfo.isEmpty {
            print("📊 [Apple 로그인] 에러 세부정보:")
            for (key, value) in userInfo {
                print("   - \(key): \(value)")
            }
        }
    }
    
    /// Apple ID 사용자 정보 저장 (상세 로깅 포함)
    static func saveAppleUserInfo(userID: String, fullName: PersonNameComponents?, email: String?) {
        print("💾 [사용자정보] Apple 사용자 정보 저장 시작")
        print("💾 [사용자정보] User ID: \(userID)")
        
        UserDefaults.standard.set(userID, forKey: "appleUserID")
        
        if let fullName = fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .long
            let name = formatter.string(from: fullName)
            
            // ✅ 수정: 사용자 편집 이름이 있으면 Apple 원본 이름만 저장
            UserDefaults.standard.set(name, forKey: "appleUserName")
            print("💾 [사용자정보] Apple 원본 이름 저장: \(name)")
            
            // 사용자가 직접 변경한 이름이 없을 때만 userName 업데이트
            let userEditedName = UserDefaults.standard.string(forKey: "userEditedName")
            if userEditedName == nil || userEditedName!.isEmpty {
                UserDefaults.standard.set(name, forKey: "userName")
                UserDefaults.standard.set(name, forKey: "currentUserName")
                print("💾 [사용자정보] 사용자 이름도 업데이트: \(name)")
            } else {
                print("🔒 [사용자정보] 사용자 편집 이름 보호: \(userEditedName!)")
            }
        } else {
            print("💾 [사용자정보] 이름 정보 없음 (이후 로그인일 가능성)")
        }
        
        if let email = email {
            UserDefaults.standard.set(email, forKey: "appleUserEmail")
            print("💾 [사용자정보] 이메일 저장: \(email)")
        } else {
            print("💾 [사용자정보] 이메일 정보 없음 (이후 로그인일 가능성)")
        }
        
        print("✅ [사용자정보] Apple 사용자 정보 저장 완료")
    }
    
    /// 저장된 Apple 사용자 정보 가져오기
    static func getSavedAppleUserInfo() -> (userID: String?, name: String?, email: String?) {
        let userID = UserDefaults.standard.string(forKey: "appleUserID")
        let name = UserDefaults.standard.string(forKey: "appleUserName")
        let email = UserDefaults.standard.string(forKey: "appleUserEmail")
        
        print("🔍 [저장된정보] User ID: \(userID ?? "없음")")
        print("🔍 [저장된정보] 이름: \(name ?? "없음")")
        print("🔍 [저장된정보] 이메일: \(email ?? "없음")")
        
        return (userID, name, email)
    }
    
    /// Apple 사용자 정보 삭제
    static func clearAppleUserInfo() {
        print("🗑️ [사용자정보] Apple 사용자 정보 삭제 시작")
        
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        
        print("✅ [사용자정보] Apple 사용자 정보 삭제 완료")
    }
    
    /// Apple 로그인 상태 디버그 정보 출력
    static func printAppleSignInDebugInfo() {
        print("🍎 === Apple Sign In 디버그 정보 ===")
        print("🍎 사용 가능 여부: \(isAppleSignInAvailable())")
        
        let savedInfo = getSavedAppleUserInfo()
        print("🍎 저장된 Apple ID: \(savedInfo.userID ?? "없음")")
        print("🍎 저장된 이름: \(savedInfo.name ?? "없음")")
        print("🍎 저장된 이메일: \(savedInfo.email ?? "없음")")
        
        checkAppleIDState { state, error in
            if let error = error {
                print("🍎 Apple ID 상태 확인 오류: \(error.localizedDescription)")
            } else {
                print("🍎 Apple ID 상태: \(getAppleIDStateDescription(state))")
            }
        }
        print("🍎 =================================")
    }
    
    /// 실제 기기 환경 확인
    static func checkRealDeviceEnvironment() {
        print("📱 === 실제 기기 환경 확인 ===")
        
        // 시뮬레이터 vs 실제 기기 확인
        #if targetEnvironment(simulator)
        print("⚠️ [환경] 현재 시뮬레이터에서 실행 중!")
        print("⚠️ [환경] Apple Sign In은 실제 기기에서만 작동합니다.")
        #else
        print("✅ [환경] 실제 기기에서 실행 중")
        #endif
        
        // 기기 정보
        print("📱 [기기] 모델: \(UIDevice.current.model)")
        print("📱 [기기] iOS 버전: \(UIDevice.current.systemVersion)")
        print("📱 [기기] 기기명: \(UIDevice.current.name)")
        
        // Apple ID 로그인 상태 확인
        if let appleUserID = UserDefaults.standard.string(forKey: "appleUserID") {
            print("🔐 [Apple ID] 이전 로그인 기록 있음: \(appleUserID)")
        } else {
            print("🔐 [Apple ID] 첫 로그인 시도")
        }
        
        print("📱 ========================")
    }
    
    /// Firebase 연동 전 체크
    static func preFirebaseCheck() {
        print("🔥 === Firebase 연동 전 체크 ===")
        
        // Firebase 설정 확인
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("✅ [Firebase] GoogleService-Info.plist 존재")
            print("✅ [Firebase] 파일 경로: \(path)")
        } else {
            print("❌ [Firebase] GoogleService-Info.plist 없음")
        }
        
        // 네트워크 연결 상태 (간단한 체크)
        print("🌐 [네트워크] 연결 상태 확인 필요")
        
        print("🔥 =========================")
    }
    
}
// MARK: - UserDefaults 확장

extension UserDefaults {
    /// 사용자가 직접 편집한 이름 저장
    static func setUserEditedName(_ name: String) {
        standard.set(name, forKey: "userEditedName")
        standard.set(name, forKey: "userName")
        standard.set(name, forKey: "currentUserName")
        standard.synchronize()
        print("✅ [이름 변경] 사용자 편집 이름 저장: \(name)")
    }
    
    /// 현재 표시할 사용자 이름 가져오기 (우선순위 적용)
    static func getCurrentDisplayName() -> String {
        let priorities = ["userEditedName", "currentUserName", "userName", "appleUserName"]
        
        for key in priorities {
            if let name = standard.string(forKey: key), !name.isEmpty {
                print("🔍 [이름 조회] \(key)에서 발견: \(name)")
                return name
            }
        }
        
        print("⚠️ [이름 조회] 저장된 이름 없음, 기본값 사용")
        return "사용자"
    }
    
    /// 사용자 편집 이름 삭제 (Apple 원본 이름으로 복원)
    static func clearUserEditedName() {
        standard.removeObject(forKey: "userEditedName")
        
        // Apple 원본 이름으로 복원
        if let appleName = standard.string(forKey: "appleUserName"), !appleName.isEmpty {
            standard.set(appleName, forKey: "userName")
            standard.set(appleName, forKey: "currentUserName")
            print("🔄 [이름 복원] Apple 원본 이름으로 복원: \(appleName)")
        }
        
        standard.synchronize()
    }
}
