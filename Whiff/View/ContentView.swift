import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var appSettings = AppSettings.shared
    @State private var showOnboarding: Bool
    
    init() {
        // 초기화 시 AppSettings의 상태를 가져와서 @State에 설정
        self._showOnboarding = State(initialValue: AppSettings.shared.isFirstLaunch)
    }
    
    var body: some View {
        Group {
            if authViewModel.isInitializing {
                // Firebase Auth 초기화 중일 때 로딩 화면
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("앱을 시작하는 중...")
                        .font(.headline)
                        .foregroundColor(.whiffSecondaryText2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.whiffMainBackground)
            } else if showOnboarding {
                // 온보딩 화면
                OnboardingView(isFirstLaunch: $showOnboarding)
                    .onChange(of: showOnboarding) { oldValue, newValue in
                        // showOnboarding이 변경되면 AppSettings도 업데이트
                        appSettings.isFirstLaunch = newValue
                    }
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isInitializing)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
    }
}
