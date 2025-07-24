import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var isFirstLaunch: Bool {
        didSet {
            UserDefaults.standard.set(!isFirstLaunch, forKey: "hasLaunchedBefore")
        }
    }
    
    private init() {
        // UserDefaults에서 앱을 이전에 실행했는지 확인
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        self.isFirstLaunch = !hasLaunchedBefore
    }
    
    // 온보딩을 다시 보여주고 싶을 때 사용
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasLaunchedBefore")
        isFirstLaunch = true
    }
} 