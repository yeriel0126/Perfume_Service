# Sign In with Apple Capability 추가 방법

## 🔍 Sign In with Apple이 보이지 않는 경우

### 1. 정확한 이름 확인
Xcode에서 다음과 같은 이름들로 검색해보세요:
- **"Sign in with Apple"** (소문자 'in')
- **"Sign In with Apple"** (대문자 'In')
- **"Apple Sign In"**
- **"Apple"** (Apple로 검색 후 찾기)

### 2. 검색 방법
1. **+ Capability** 버튼 클릭
2. 검색창에 **"apple"** 입력
3. 또는 **"sign"** 입력
4. 또는 **"authentication"** 입력

### 3. 카테고리별 확인
Capability 목록에서 다음 카테고리들을 확인:
- **Authentication**
- **Apple Services**
- **Signing & Capabilities**

## 🚨 Bundle Identifier 문제 해결

### 현재 문제
프로젝트에서 Bundle Identifier가 불일치:
- Debug: `com.sinhuiyeong.Whiff`
- Release: `com.whiff.main`

### 해결 방법
1. Xcode에서 프로젝트 선택
2. **Signing & Capabilities** 탭
3. **Bundle Identifier**를 `com.whiff.main`로 통일
4. **Team** 설정 확인

## 🔧 수동으로 추가하는 방법

### 1. Info.plist에 직접 추가
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>AppleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.whiff.main</string>
        </array>
    </dict>
</array>
```

### 2. Entitlements 파일 생성
1. **File** → **New** → **File**
2. **Entitlements File** 선택
3. 파일명: `Whiff.entitlements`
4. 다음 내용 추가:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```

### 3. 프로젝트 설정에 Entitlements 연결
1. 프로젝트 선택 → **Signing & Capabilities**
2. **Code Signing Entitlements** 필드에 `Whiff.entitlements` 입력

## 📋 체크리스트

### Xcode 설정
- [ ] Bundle Identifier 통일: `com.whiff.main`
- [ ] Team 설정 완료
- [ ] Sign In with Apple Capability 추가
- [ ] Entitlements 파일 생성 (필요시)

### Apple Developer Console
- [ ] App ID: `com.whiff.main` 생성
- [ ] Sign In with Apple capability 활성화
- [ ] Bundle ID 일치 확인

## 🆘 여전히 문제가 있는 경우

### 1. Xcode 재시작
1. Xcode 완전 종료
2. Xcode 재시작
3. 프로젝트 다시 열기

### 2. 프로젝트 클린
1. **Product** → **Clean Build Folder**
2. **Product** → **Build**

### 3. Derived Data 삭제
1. **Xcode** → **Preferences** → **Locations**
2. **Derived Data** 옆 화살표 클릭
3. 폴더 열기 후 삭제
4. Xcode 재시작

### 4. 최신 Xcode 사용
- Xcode 15.0 이상 사용 권장
- 최신 버전으로 업데이트 
