import SwiftUI
import FirebaseCore
import GoogleSignIn

// AppDelegate 클래스 활성화
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        print("🚀 === Whiff 앱 시작 ===")
        print("🚀 Firebase 설정 시작")
        
        FirebaseApp.configure()
        
        print("✅ Firebase 설정 완료")
        print("🔍 === Apple Sign In 상세 진단 시작 ===")
        
        // 1. 기본 설정 정보 출력
        AppleSignInConfig.printConfig()
        
        // 2. 설정 검증
        AppleSignInConfig.validateConfig()
        
        // 3. 키 파일 정보 출력
        AppleSignInKeyManager.printKeyFileInfo()
        
        // 4. 상세 디버그 정보 출력
        AppleSignInKeyManager.printDetailedDebugInfo()
        
        // 5. Apple 로그인 유틸리티 디버그 정보
        AppleSignInUtils.printAppleSignInDebugInfo()
        
        // 6. 종합 상태 리포트
        AppleSignInConfig.printStatusReport()
        
        print("🔍 === Apple Sign In 상세 진단 완료 ===")
        print("🚀 === Whiff 앱 시작 완료 ===")
        
        return true
    }
    
    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("🔗 URL 열기 요청: \(url)")
        let handled = GIDSignIn.sharedInstance.handle(url)
        print("🔗 Google Sign In 처리 결과: \(handled)")
        return handled
    }
}

@main
struct WhiffApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var dailyPerfumeManager = DailyPerfumeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .background(Color.whiffMainBackground)
                .environmentObject(projectStore)
                .environmentObject(authViewModel)
                .environmentObject(dailyPerfumeManager)
                .onAppear {
                    print("📱 ContentView 나타남")
                    
                    // 추가 런타임 체크
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        print("🔄 === 런타임 체크 (앱 시작 1초 후) ===")
                        AppleSignInConfig.printStatusReport()
                        print("🔄 === 런타임 체크 완료 ===")
                    }
                }
        }
    }
}
