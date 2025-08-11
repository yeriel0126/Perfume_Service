# Apple Sign In 구현 체크리스트

## 📋 프론트엔드 개발자가 받아야 하는 정보

### 1. Apple Developer Console 정보
- [ ] **Team ID**: `ABC123DEF4` (10자리 영숫자)
- [ ] **Key ID**: `XYZ789ABC1` (10자리 영숫자)
- [ ] **Private Key 파일**: `AuthKey_XYZ789ABC1.p8`
- [ ] **Bundle ID**: `com.whiff.main`
- [ ] **App ID**: Apple Developer Console에서 생성한 App ID

### 2. Firebase Console 설정 정보
- [ ] **Firebase 프로젝트 ID**: `whiff-1cd2b`
- [ ] **Firebase Web API Key**: `AIzaSyBuyRbKSrmdJRCmbFH43NcExWVSzqSVwMI`
- [ ] **Service ID**: `com.whiff.main.signin`
- [ ] **Apple Team ID**: 위의 Team ID와 동일
- [ ] **Key ID**: 위의 Key ID와 동일
- [ ] **Private Key 내용**: `.p8` 파일의 전체 내용

### 3. Xcode 프로젝트 설정
- [ ] **Sign In with Apple Capability** 추가
- [ ] **Bundle Identifier** 확인
- [ ] **Team** 설정 확인
- [ ] **Provisioning Profile** 설정

## 🔧 구현 단계

### 1단계: Apple Developer Console 설정
1. [Apple Developer Console](https://developer.apple.com) 접속
2. **Certificates, Identifiers & Profiles** → **Identifiers**
3. App ID에서 **Sign In with Apple** 활성화
4. **Keys**에서 Private Key 생성 및 다운로드
5. **Team ID** 확인

### 2단계: Firebase Console 설정
1. [Firebase Console](https://console.firebase.google.com) 접속
2. **Authentication** → **Sign-in method**
3. **Apple** provider 활성화
4. Apple Developer Console 정보 입력

### 3단계: 앱 구현
1. `AuthenticationServices` 프레임워크 import
2. `SignInWithAppleButton` UI 구현
3. `ASAuthorizationAppleIDCredential` 처리
4. Firebase 인증 연동

## 📊 받는 데이터 구조

### Apple 로그인 성공 시 받는 정보
```swift
struct AppleSignInUserData {
    let userID: String           // "001234.567890abcdef.1234"
    let email: String?           // "user@example.com" (첫 로그인시에만)
    let fullName: PersonNameComponents? // 이름 정보 (첫 로그인시에만)
    let identityToken: String    // JWT 토큰
    let authorizationCode: String? // 인증 코드
    let realUserStatus: ASUserDetectionType // 실제 사용자 여부
}
```

### Firebase 인증 후 받는 정보
```swift
struct FirebaseUserData {
    let uid: String              // Firebase 사용자 ID
    let email: String?           // 사용자 이메일
    let displayName: String?     // 사용자 이름
    let photoURL: String?        // 프로필 이미지 URL
    let idToken: String          // Firebase ID 토큰
}
```

## 🚨 주의사항

### 보안
- [ ] Private Key 파일을 Git에 업로드하지 않음
- [ ] `.gitignore`에 `*.p8` 추가
- [ ] 키 파일을 안전한 곳에 백업

### 사용자 정보
- [ ] 이메일과 이름은 **첫 로그인시에만** 제공됨
- [ ] 이후 로그인에서는 `userID`만 제공됨
- [ ] 사용자 정보를 앱에서 저장해야 함

### 테스트
- [ ] Apple Sign In은 **실제 기기에서만** 테스트 가능
- [ ] 시뮬레이터에서는 테스트 불가
- [ ] Apple Developer 계정 필요

## 🔍 디버그 정보

앱 실행 시 콘솔에서 확인할 수 있는 정보:
```
🍎 === Apple Sign In 디버그 정보 ===
🍎 사용 가능 여부: true
🍎 키 파일 존재: true
🍎 저장된 사용자 ID: 001234.567890abcdef.1234
🍎 저장된 이름: 홍길동
🍎 저장된 이메일: user@example.com
🍎 인증 상태: 인증됨
🍎 Firebase 설정: 완료
🍎 ================================
```

## 📞 문제 해결

### 일반적인 오류
- **"Invalid client"**: Bundle ID 불일치
- **"Invalid key"**: Private Key 잘못됨
- **"Invalid team"**: Team ID 잘못됨
- **"User not found"**: Apple ID 상태 확인 필요

### 연락처
- Apple Developer Support: https://developer.apple.com/support/
- Firebase Support: https://firebase.google.com/support 
