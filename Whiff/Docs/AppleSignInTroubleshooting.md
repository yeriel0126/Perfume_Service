# Apple Sign In 에러 1000 해결 가이드

## 🚨 에러 1000 원인

에러 1000은 Apple Sign In 설정이 완료되지 않았을 때 발생하는 가장 일반적인 오류입니다.

## 🔧 해결 방법

### 1. Xcode에서 Sign In with Apple Capability 추가

#### 1.1 Xcode에서 설정
1. Xcode에서 프로젝트 열기
2. 프로젝트 선택 → **Signing & Capabilities** 탭
3. **+ Capability** 버튼 클릭
4. **Sign In with Apple** 검색 후 추가

#### 1.2 확인사항
- [ ] Sign In with Apple capability가 추가됨
- [ ] Bundle Identifier가 올바름: `com.whiff.main`
- [ ] Team이 올바르게 설정됨

### 2. Apple Developer Console 설정 확인

#### 2.1 App ID 설정
1. [Apple Developer Console](https://developer.apple.com) 접속
2. **Certificates, Identifiers & Profiles** → **Identifiers**
3. 앱의 App ID 선택
4. **Sign In with Apple** capability가 활성화되어 있는지 확인

#### 2.2 Bundle ID 확인
- Apple Developer Console의 App ID와 Xcode의 Bundle ID가 일치해야 함
- 현재 Bundle ID: `com.whiff.main`

### 3. Firebase Console 설정 확인

#### 3.1 Apple Provider 활성화
1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택 → **Authentication** → **Sign-in method**
3. **Apple** provider가 활성화되어 있는지 확인

#### 3.2 Apple 설정 정보
- Service ID: `com.whiff.main.signin`
- Apple Team ID: (Apple Developer Console에서 확인)
- Key ID: (Apple Developer Console에서 확인)
- Private Key: (Apple Developer Console에서 다운로드한 .p8 파일 내용)

### 4. 시뮬레이터 vs 실제 기기

#### 4.1 시뮬레이터 제한사항
- Apple Sign In은 **실제 기기에서만** 작동
- 시뮬레이터에서는 에러 1000이 정상적인 동작
- 실제 iOS 기기에서 테스트 필요

#### 4.2 실제 기기 테스트
1. 실제 iOS 기기 연결
2. Apple ID로 로그인된 상태인지 확인
3. 앱 실행 후 Apple 로그인 테스트

## 🔍 디버그 정보 확인

### 앱 실행 시 콘솔 확인
```
🍎 === Apple Sign In 디버그 정보 ===
🍎 사용 가능 여부: true
🍎 === Apple Sign In 설정 정보 ===
🍎 Team ID: YOUR_TEAM_ID_HERE
🍎 Key ID: YOUR_KEY_ID_HERE
🍎 Bundle ID: com.whiff.main
🍎 Service ID: com.whiff.main.signin
🍎 Key File: AuthKey_YOUR_KEY_ID_HERE.p8
🍎 설정 완료: ❌
🍎 ================================
```

### 설정이 완료되지 않은 경우
- `YOUR_TEAM_ID_HERE`, `YOUR_KEY_ID_HERE` 등이 기본값으로 남아있음
- Apple Developer Console 담당자로부터 실제 정보를 받아서 입력 필요

## 📋 체크리스트

### Xcode 설정
- [ ] Sign In with Apple Capability 추가됨
- [ ] Bundle Identifier 올바름
- [ ] Team 설정 올바름
- [ ] Provisioning Profile 설정됨

### Apple Developer Console
- [ ] App ID에 Sign In with Apple 활성화됨
- [ ] Bundle ID 일치함
- [ ] Private Key 생성됨
- [ ] Team ID 확인됨

### Firebase Console
- [ ] Apple Provider 활성화됨
- [ ] Service ID 설정됨
- [ ] Team ID 입력됨
- [ ] Key ID 입력됨
- [ ] Private Key 입력됨

### 테스트 환경
- [ ] 실제 iOS 기기 사용
- [ ] Apple ID 로그인됨
- [ ] 인터넷 연결됨

## 🚨 추가 문제 해결

### 여전히 에러 1000이 발생하는 경우
1. **Apple Developer Console에서 App ID 재설정**
2. **Firebase Console에서 Apple Provider 재설정**
3. **Xcode에서 Capability 재추가**
4. **앱 완전 삭제 후 재설치**

### 연락처
- Apple Developer Support: https://developer.apple.com/support/
- Firebase Support: https://firebase.google.com/support 
