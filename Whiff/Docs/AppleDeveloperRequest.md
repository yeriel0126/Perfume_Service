# Apple Developer Console 담당자 요청 메시지

## 📧 요청 메시지 템플릿

```
제목: [Whiff 앱] Apple Sign In 설정을 위한 정보 요청

안녕하세요,

Whiff iOS 앱에 Apple Sign In 기능을 구현하기 위해 다음 정보들이 필요합니다.

## 1. App ID 설정
- Bundle ID: com.whiff.main
- Sign In with Apple capability 활성화 필요

## 2. Private Key 생성
- Key Name: "Whiff Apple Sign In Key" (또는 원하는 이름)
- Sign In with Apple 권한 체크
- 위의 App ID와 연결

## 3. 필요한 정보
다음 정보들을 알려주세요:

### App ID 정보
- [ ] Bundle ID: com.whiff.main
- [ ] App ID: (생성된 App ID)
- [ ] Sign In with Apple 활성화 여부

### Private Key 정보  
- [ ] Key ID: (10자리 영숫자)
- [ ] Key Name: (생성한 키 이름)
- [ ] Private Key 파일 (.p8): 첨부 또는 다운로드 링크

### Team 정보
- [ ] Team ID: (10자리 영숫자)
- [ ] Team Name: (팀 이름)

## 4. 추가 요청사항
- Private Key 파일은 안전한 방법으로 전달해주세요
- 모든 정보가 정확한지 확인 부탁드립니다
- 혹시 모르는 부분이 있으면 언제든 연락주세요

감사합니다!
```

## 📋 체크리스트 (담당자용)

### App ID 설정
- [ ] Bundle ID: `com.whiff.main` 확인
- [ ] Sign In with Apple capability 활성화
- [ ] App ID 생성 완료

### Private Key 생성
- [ ] Key Name: "Whiff Apple Sign In Key" 입력
- [ ] Sign In with Apple 권한 체크
- [ ] App ID와 연결
- [ ] Key 생성 및 다운로드
- [ ] Key ID 기록

### 정보 전달
- [ ] Team ID 제공
- [ ] Key ID 제공  
- [ ] Private Key 파일 전달
- [ ] App ID 정보 제공

## 🔒 보안 주의사항

### Private Key 파일 전달 시
- 이메일 첨부는 권장하지 않음
- 안전한 파일 공유 서비스 사용 (Google Drive, Dropbox 등)
- 링크는 비밀번호 보호 권장
- 전달 후 링크 삭제 권장

### 정보 보관
- Private Key 파일은 안전한 곳에 백업
- Key ID와 Team ID는 안전하게 보관
- 필요시에만 접근 권한 부여 
