# Apple Sign In 설정 가이드

## 1. Apple Developer Console 설정

### 1.1 App ID 설정
1. [Apple Developer Console](https://developer.apple.com) 접속
2. **Certificates, Identifiers & Profiles** → **Identifiers**
3. 앱의 App ID 선택 또는 새로 생성
4. **Sign In with Apple** capability 활성화
5. **Configure** 클릭하여 설정 완료

### 1.2 Private Key 생성
1. **Certificates, Identifiers & Profiles** → **Keys**
2. **+** 버튼 클릭
3. **Key Name** 입력 (예: "Whiff Apple Sign In Key")
4. **Sign In with Apple** 체크
5. **Configure** 클릭하여 App ID 선택
6. **Register** 클릭
7. **Download** 버튼으로 `.p8` 파일 다운로드
8. **Key ID** 기록 (Firebase 설정에 필요)

### 1.3 Team ID 확인
1. **Membership** 탭에서 **Team ID** 확인
2. 10자리 영숫자 (예: ABC123DEF4)

## 2. Firebase Console 설정

### 2.1 Apple Provider 활성화
1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택 → **Authentication** → **Sign-in method**
3. **Apple** provider 선택
4. **Enable** 활성화

### 2.2 Apple 설정 정보 입력
- **Service ID**: Apple Developer Console에서 생성한 Service ID
- **Apple Team ID**: Apple Developer Team ID (10자리)
- **Key ID**: 생성한 Private Key의 Key ID
- **Private Key**: 다운로드한 `.p8` 파일 내용

## 3. 앱에 키 파일 추가 (선택사항)

### 3.1 키 파일 추가
1. Xcode에서 프로젝트 열기
2. **Project Navigator**에서 프로젝트 폴더 우클릭
3. **Add Files to "Whiff"** 선택
4. 다운로드한 `.p8` 파일 선택
5. **Add** 클릭

### 3.2 키 파일명 설정
`AppleSignInKeyManager.swift`에서 키 파일명을 실제 파일명으로 변경:

```swift
private static let keyFileName = "AuthKey_XXXXXXXXXX.p8" // 실제 키 ID로 변경
```

### 3.3 설정 정보 업데이트
`AppleSignInConfig` 구조체에서 실제 값으로 변경:

```swift
struct AppleSignInConfig {
    static let teamID = "YOUR_TEAM_ID" // 실제 Team ID
    static let keyID = "YOUR_KEY_ID"   // 실제 Key ID
    static let serviceID = "YOUR_SERVICE_ID" // 실제 Service ID
    static let bundleID = "com.whiff.main" // 앱 Bundle ID
}
```

## 4. Xcode 프로젝트 설정

### 4.1 Sign In with Apple Capability 추가
1. Xcode에서 프로젝트 선택
2. **Signing & Capabilities** 탭
3. **+ Capability** 버튼 클릭
4. **Sign In with Apple** 추가

### 4.2 Bundle ID 확인
- **Bundle Identifier**가 Apple Developer Console의 App ID와 일치하는지 확인

## 5. 테스트

### 5.1 시뮬레이터 테스트
- Apple Sign In은 실제 기기에서만 작동
- 시뮬레이터에서는 테스트 불가

### 5.2 실제 기기 테스트
1. 실제 iOS 기기에서 앱 실행
2. Apple ID로 로그인 시도
3. 콘솔 로그 확인

## 6. 문제 해결

### 6.1 일반적인 오류
- **"Invalid client"**: Bundle ID 불일치
- **"Invalid key"**: Private Key 잘못됨
- **"Invalid team"**: Team ID 잘못됨

### 6.2 디버그 정보 확인
앱 실행 시 콘솔에서 다음 정보 확인:
```
🍎 === Apple Sign In 디버그 정보 ===
🍎 사용 가능 여부: true
🍎 === Apple Sign In 키 파일 정보 ===
🍎 키 파일 존재: true/false
```

## 7. 보안 주의사항

### 7.1 키 파일 보안
- `.p8` 파일은 절대 공개 저장소에 업로드하지 마세요
- `.gitignore`에 키 파일 추가:
```
# Apple Sign In Keys
*.p8
AuthKey_*.p8
```

### 7.2 환경별 설정
- 개발/스테이징/프로덕션 환경별로 다른 키 사용 권장
- Firebase 프로젝트도 환경별로 분리 권장 
