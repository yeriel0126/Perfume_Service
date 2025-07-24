import Foundation
import AuthenticationServices

/// Apple 로그인 시 받는 사용자 정보
struct AppleSignInUserData {
    let userID: String           // Apple 사용자 고유 ID
    let email: String?           // 사용자 이메일 (첫 로그인시에만 제공)
    let fullName: PersonNameComponents? // 사용자 이름 (첫 로그인시에만 제공)
    let identityToken: String    // JWT 토큰
    let authorizationCode: String? // 인증 코드
    let realUserStatus: String? // 실제 사용자 여부 (문자열로 저장)
    
    init(from credential: ASAuthorizationAppleIDCredential) {
        self.userID = credential.user
        self.email = credential.email
        self.fullName = credential.fullName
        self.identityToken = String(data: credential.identityToken!, encoding: .utf8) ?? ""
        self.authorizationCode = credential.authorizationCode != nil ? 
            String(data: credential.authorizationCode!, encoding: .utf8) : nil
        
        // iOS 13.0+에서만 사용 가능
        if #available(iOS 13.0, *) {
            switch credential.realUserStatus {
            case .likelyReal:
                self.realUserStatus = "likelyReal"
            case .unknown:
                self.realUserStatus = "unknown"
            case .unsupported:
                self.realUserStatus = "unsupported"
            @unknown default:
                self.realUserStatus = "unknown"
            }
        } else {
            self.realUserStatus = nil
        }
    }
}

/// Apple 로그인 응답 데이터
struct AppleSignInResponse {
    let success: Bool
    let userData: AppleSignInUserData?
    let error: Error?
    let isFirstLogin: Bool
    
    init(success: Bool, userData: AppleSignInUserData? = nil, error: Error? = nil, isFirstLogin: Bool = false) {
        self.success = success
        self.userData = userData
        self.error = error
        self.isFirstLogin = isFirstLogin
    }
}

/// Apple 로그인 상태 정보
struct AppleSignInStatus {
    let isAvailable: Bool
    let credentialState: ASAuthorizationAppleIDProvider.CredentialState?
    let savedUserID: String?
    let error: Error?
    
    init(isAvailable: Bool, credentialState: ASAuthorizationAppleIDProvider.CredentialState? = nil, savedUserID: String? = nil, error: Error? = nil) {
        self.isAvailable = isAvailable
        self.credentialState = credentialState
        self.savedUserID = savedUserID
        self.error = error
    }
}

/// Apple 로그인 디버그 정보
struct AppleSignInDebugInfo {
    let isAvailable: Bool
    let keyFileExists: Bool
    let savedUserInfo: (userID: String?, name: String?, email: String?)
    let credentialState: String?
    let firebaseConfigured: Bool
    
    func printDebugInfo() {
        print("🍎 === Apple Sign In 디버그 정보 ===")
        print("🍎 사용 가능 여부: \(isAvailable)")
        print("🍎 키 파일 존재: \(keyFileExists)")
        print("🍎 저장된 사용자 ID: \(savedUserInfo.userID ?? "없음")")
        print("🍎 저장된 이름: \(savedUserInfo.name ?? "없음")")
        print("🍎 저장된 이메일: \(savedUserInfo.email ?? "없음")")
        print("🍎 인증 상태: \(credentialState ?? "알 수 없음")")
        print("🍎 Firebase 설정: \(firebaseConfigured ? "완료" : "미완료")")
        print("🍎 =================================")
    }
} 