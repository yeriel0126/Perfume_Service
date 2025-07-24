import SwiftUI
import AuthenticationServices

struct AppleSignInTestView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Apple 로그인 테스트")
                .font(.title)
                .bold()
            
            Text("Apple ID로 로그인을 테스트해보세요")
                .font(.subheadline)
                .foregroundColor(.whiffPrimaryText)
                .multilineTextAlignment(.center)
            
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                    print("🍎 Apple 로그인 요청 설정 완료")
                },
                onCompletion: { result in
                    Task {
                        await handleAppleSignIn(result: result)
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(width: 280, height: 50)
            
            if authViewModel.isLoading {
                ProgressView("로그인 중...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            if let error = authViewModel.error {
                Text("오류: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.whiffMainBackground)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.whiffMainBackground)
        .alert("Apple 로그인", isPresented: $showAlert) {
            Button("확인") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        do {
            await authViewModel.signInWithApple(result: result)
            
            await MainActor.run {
                if authViewModel.isAuthenticated {
                    alertMessage = "Apple 로그인 성공! 사용자: \(authViewModel.user?.data.name ?? "알 수 없음")"
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    AppleSignInTestView()
        .environmentObject(AuthViewModel())
} 
