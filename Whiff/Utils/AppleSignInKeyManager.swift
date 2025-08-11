import Foundation
import CryptoKit

class AppleSignInKeyManager {
    
    /// 키 파일 경로 (Bundle에서 찾기)
    private static var keyFileName: String {
        return AppleSignInConfig.keyFileName
    }
    
    /// 키 파일에서 Private Key 읽기
    static func getPrivateKey() -> String? {
        print("🔍 [AppleSignInKeyManager] Private Key 로드 시작")
        print("🔍 [AppleSignInKeyManager] 예상 키 파일명: \(keyFileName)")
        
        let resourceName = keyFileName.replacingOccurrences(of: ".p8", with: "")
        print("🔍 [AppleSignInKeyManager] Bundle에서 찾을 리소스명: \(resourceName)")
        
        guard let path = Bundle.main.path(forResource: resourceName, ofType: "p8") else {
            print("❌ [AppleSignInKeyManager] 키 파일을 찾을 수 없습니다")
            print("❌ [AppleSignInKeyManager] 찾는 파일: \(keyFileName)")
            print("❌ [AppleSignInKeyManager] 리소스명: \(resourceName)")
            print("❌ [AppleSignInKeyManager] 파일 타입: p8")
            
            // Bundle의 모든 .p8 파일 목록 출력
            let allP8Files = Bundle.main.paths(forResourcesOfType: "p8", inDirectory: nil)
            print("🔍 [AppleSignInKeyManager] Bundle 내 모든 .p8 파일:")
            if allP8Files.isEmpty {
                print("   - .p8 파일이 없습니다")
            } else {
                for file in allP8Files {
                    print("   - \(URL(fileURLWithPath: file).lastPathComponent)")
                }
            }
            return nil
        }
        
        print("✅ [AppleSignInKeyManager] 키 파일 경로 찾음: \(path)")
        
        do {
            let privateKey = try String(contentsOfFile: path, encoding: .utf8)
            print("✅ [AppleSignInKeyManager] 키 파일 로드 성공")
            print("✅ [AppleSignInKeyManager] 키 파일 길이: \(privateKey.count) 문자")
            
            // 키 파일 내용 검증
            validatePrivateKeyFormat(privateKey)
            
            return privateKey
        } catch {
            print("❌ [AppleSignInKeyManager] 키 파일 읽기 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Private Key 포맷 검증
    private static func validatePrivateKeyFormat(_ privateKey: String) {
        print("🔍 [AppleSignInKeyManager] Private Key 포맷 검증 시작")
        
        let hasBeginMarker = privateKey.contains("-----BEGIN PRIVATE KEY-----")
        let hasEndMarker = privateKey.contains("-----END PRIVATE KEY-----")
        
        print("🔍 [AppleSignInKeyManager] BEGIN PRIVATE KEY 마커 존재: \(hasBeginMarker ? "✅" : "❌")")
        print("🔍 [AppleSignInKeyManager] END PRIVATE KEY 마커 존재: \(hasEndMarker ? "✅" : "❌")")
        
        if hasBeginMarker && hasEndMarker {
            print("✅ [AppleSignInKeyManager] Private Key 포맷이 올바릅니다")
            
            // 실제 키 데이터 부분 추출
            let lines = privateKey.components(separatedBy: .newlines)
            let keyDataLines = lines.filter {
                !$0.contains("-----BEGIN") &&
                !$0.contains("-----END") &&
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            
            print("🔍 [AppleSignInKeyManager] 키 데이터 라인 수: \(keyDataLines.count)")
            
            if let firstLine = keyDataLines.first {
                print("🔍 [AppleSignInKeyManager] 첫 번째 키 데이터 라인 길이: \(firstLine.count)")
            }
        } else {
            print("❌ [AppleSignInKeyManager] Private Key 포맷이 올바르지 않습니다")
        }
    }
    
    /// JWT 토큰 생성 (필요한 경우)
    static func generateJWTToken() -> String? {
        print("🔍 [AppleSignInKeyManager] JWT 토큰 생성 요청됨")
        print("ℹ️ [AppleSignInKeyManager] JWT 생성은 현재 구현되지 않음 (라이브러리 필요)")
        // JWT 토큰 생성 로직
        // 실제 구현에서는 JWT 라이브러리 사용 권장
        return nil
    }
    
    /// 키 파일 존재 여부 확인
    static func isKeyFileExists() -> Bool {
        let resourceName = keyFileName.replacingOccurrences(of: ".p8", with: "")
        let exists = Bundle.main.path(forResource: resourceName, ofType: "p8") != nil
        print("🔍 [AppleSignInKeyManager] 키 파일 존재 여부: \(exists ? "✅" : "❌")")
        return exists
    }
    
    /// 키 파일 정보 출력
    static func printKeyFileInfo() {
        print("🍎 === Apple Sign In 키 파일 정보 ===")
        print("🍎 키 파일명: \(keyFileName)")
        print("🍎 키 파일 존재: \(isKeyFileExists())")
        
        if let privateKey = getPrivateKey() {
            print("🍎 키 파일 로드: ✅ 성공")
            print("🍎 키 파일 길이: \(privateKey.count) 문자")
        } else {
            print("🍎 키 파일 로드: ❌ 실패")
        }
        print("🍎 =================================")
    }
    
    /// 상세 디버그 정보 출력
    static func printDetailedDebugInfo() {
        print("🔍 === Apple Sign In 상세 디버그 정보 ===")
        
        // Bundle 정보
        print("🔍 [Bundle] 메인 번들 경로: \(Bundle.main.bundlePath)")
        print("🔍 [Bundle] 번들 식별자: \(Bundle.main.bundleIdentifier ?? "없음")")
        
        // 키 파일 관련 정보
        let resourceName = keyFileName.replacingOccurrences(of: ".p8", with: "")
        print("🔍 [파일] 찾는 키 파일명: \(keyFileName)")
        print("🔍 [파일] 리소스명: \(resourceName)")
        print("🔍 [파일] 파일 확장자: p8")
        
        // Bundle 내 모든 파일 목록
        let allFiles = Bundle.main.paths(forResourcesOfType: nil, inDirectory: nil)
        let p8Files = allFiles.filter { $0.hasSuffix(".p8") }
        
        print("🔍 [Bundle] 총 파일 수: \(allFiles.count)")
        print("🔍 [Bundle] .p8 파일 수: \(p8Files.count)")
        
        if p8Files.isEmpty {
            print("⚠️ [Bundle] .p8 파일이 Bundle에 없습니다!")
        } else {
            print("🔍 [Bundle] 발견된 .p8 파일들:")
            for file in p8Files {
                let fileName = URL(fileURLWithPath: file).lastPathComponent
                print("   - \(fileName)")
            }
        }
        
        // 설정 값들
        print("🔍 [설정] Team ID: \(AppleSignInConfig.teamID)")
        print("🔍 [설정] Key ID: \(AppleSignInConfig.keyID)")
        print("🔍 [설정] Service ID: \(AppleSignInConfig.serviceID)")
        print("🔍 [설정] Bundle ID: \(AppleSignInConfig.bundleID)")
        
        print("🔍 ========================================")
    }
}

// MARK: - Apple Sign In 설정 정보
/// Apple Sign In 설정 정보
/// Apple Developer Console 담당자로부터 받은 정보를 여기에 입력하세요
struct AppleSignInConfig {
    
    // MARK: - Apple Developer Console 정보
    /// Apple Developer Team ID (10자리 영숫자)
    /// 예: ABC123DEF4
    static let teamID = "8BJS54K55Z"
    
    /// Apple Developer Key ID (10자리 영숫자)
    /// 예: XYZ789ABC1
    static let keyID = "43ZM224LTP"
    
    /// 앱의 Bundle ID
    static let bundleID = "com.whiff.main"
    
    /// Apple Developer Service ID
    /// 일반적으로 Bundle ID + .signin 형태
    static let serviceID = "com.whiff.signin"  // 수정됨: singin -> signin
    
    // MARK: - Firebase 정보
    /// Firebase 프로젝트 ID
    static let firebaseProjectID = "whiff-1cd2b"
    
    /// Firebase Web API Key
    static let firebaseAPIKey = "AIzaSyBuyRbKSrmdJRCmbFH43NcExWVSzqSVwMI"
    
    // MARK: - 키 파일 정보
    /// Private Key 파일명 (실제 파일명으로 변경)
    /// 예: AuthKey_XYZ789ABC1.p8
    static let keyFileName = "AuthKey_43ZM224LTP.p8"
    
    // MARK: - 설정 검증
    /// 모든 필수 정보가 입력되었는지 확인
    static var isConfigured: Bool {
        let result = teamID != "YOUR_TEAM_ID_HERE" &&
                    keyID != "YOUR_KEY_ID_HERE" &&
                    keyFileName != "AuthKey_YOUR_KEY_ID_HERE.p8" &&
                    !teamID.isEmpty &&
                    !keyID.isEmpty &&
                    !serviceID.isEmpty &&
                    !bundleID.isEmpty
        
        print("🔍 [설정검증] Team ID 설정됨: \(teamID != "YOUR_TEAM_ID_HERE" ? "✅" : "❌")")
        print("🔍 [설정검증] Key ID 설정됨: \(keyID != "YOUR_KEY_ID_HERE" ? "✅" : "❌")")
        print("🔍 [설정검증] 키 파일명 설정됨: \(keyFileName != "AuthKey_YOUR_KEY_ID_HERE.p8" ? "✅" : "❌")")
        print("🔍 [설정검증] Team ID 비어있지 않음: \(!teamID.isEmpty ? "✅" : "❌")")
        print("🔍 [설정검증] Key ID 비어있지 않음: \(!keyID.isEmpty ? "✅" : "❌")")
        print("🔍 [설정검증] Service ID 비어있지 않음: \(!serviceID.isEmpty ? "✅" : "❌")")
        print("🔍 [설정검증] Bundle ID 비어있지 않음: \(!bundleID.isEmpty ? "✅" : "❌")")
        print("🔍 [설정검증] 전체 설정 완료: \(result ? "✅" : "❌")")
        
        return result
    }
    
    /// 설정 정보 출력
    static func printConfig() {
        print("🍎 === Apple Sign In 설정 정보 ===")
        print("🍎 Team ID: \(teamID)")
        print("🍎 Key ID: \(keyID)")
        print("🍎 Bundle ID: \(bundleID)")
        print("🍎 Service ID: \(serviceID)")
        print("🍎 Key File: \(keyFileName)")
        print("🍎 Firebase 프로젝트 ID: \(firebaseProjectID)")
        print("🍎 Firebase API Key: \(firebaseAPIKey.prefix(20))...") // 보안상 일부만 표시
        print("🍎 설정 완료: \(isConfigured ? "✅" : "❌")")
        print("🍎 =================================")
    }
    
    /// 설정 검증 및 경고
    static func validateConfig() {
        print("🔍 [검증] Apple Sign In 설정 검증 시작")
        
        if !isConfigured {
            print("⚠️ Apple Sign In 설정이 완료되지 않았습니다!")
            print("⚠️ AppleSignInKeyManager.swift에서 다음 정보를 입력하세요:")
            print("⚠️ - teamID: Apple Developer Team ID")
            print("⚠️ - keyID: Apple Developer Key ID")
            print("⚠️ - keyFileName: Private Key 파일명")
        } else {
            print("✅ [검증] Apple Sign In 기본 설정이 완료되었습니다")
        }
        
        // 키 파일 존재 여부 추가 검증
        if AppleSignInKeyManager.isKeyFileExists() {
            print("✅ [검증] Private Key 파일이 존재합니다")
        } else {
            print("❌ [검증] Private Key 파일이 Bundle에 없습니다!")
            print("❌ [검증] Xcode에서 \(keyFileName) 파일을 프로젝트에 추가해주세요")
        }
        
        // Bundle ID 검증
        if let bundleId = Bundle.main.bundleIdentifier {
            if bundleId == bundleID {
                print("✅ [검증] Bundle ID가 일치합니다: \(bundleId)")
            } else {
                print("⚠️ [검증] Bundle ID 불일치!")
                print("   - 설정된 Bundle ID: \(bundleID)")
                print("   - 실제 Bundle ID: \(bundleId)")
            }
        } else {
            print("❌ [검증] Bundle ID를 가져올 수 없습니다")
        }
        
        print("🔍 [검증] Apple Sign In 설정 검증 완료")
    }
    
    /// 종합 상태 리포트
    static func printStatusReport() {
        print("📊 === Apple Sign In 종합 상태 리포트 ===")
        
        let keyFileExists = AppleSignInKeyManager.isKeyFileExists()
        let configComplete = isConfigured
        let bundleIdMatch = Bundle.main.bundleIdentifier == bundleID
        
        print("📊 [상태] 설정 완료: \(configComplete ? "✅" : "❌")")
        print("📊 [상태] 키 파일 존재: \(keyFileExists ? "✅" : "❌")")
        print("📊 [상태] Bundle ID 일치: \(bundleIdMatch ? "✅" : "❌")")
        
        let overallStatus = configComplete && keyFileExists && bundleIdMatch
        print("📊 [상태] 전체 준비 상태: \(overallStatus ? "✅ 완료" : "❌ 미완료")")
        
        if !overallStatus {
            print("📊 [조치] 해결해야 할 문제:")
            if !configComplete {
                print("   - Apple Developer Console 정보 입력 필요")
            }
            if !keyFileExists {
                print("   - Private Key 파일(.p8)을 Xcode 프로젝트에 추가 필요")
            }
            if !bundleIdMatch {
                print("   - Bundle ID 설정 확인 필요")
            }
        }
        
        print("📊 =====================================")
    }
}
