import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                Text("Whiff")
                    .font(.system(size: 36, weight: .bold)) // 안전한 사이즈 지정
                    .foregroundColor(.whiffLogo)
                    .padding(.top, 8)

                Text("나만의 향수를 찾아보세요")
                    .font(.subheadline)
                    .foregroundColor(.whiffSecondaryText1)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("이메일")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                        TextField("이메일을 입력하세요", text: $email)
                            .textFieldStyle(CustomWhiffTextFieldStyle())
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("비밀번호")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                        SecureField("비밀번호를 입력하세요", text: $password)
                            .textFieldStyle(CustomWhiffTextFieldStyle())
                            .textContentType(.password)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    Task {
                        await authViewModel.signInWithEmail(email: email, password: password)
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .whiffWhiteText))
                    } else {
                        Text("로그인")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.whiffPrimary)
                .foregroundColor(.whiffWhiteText)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(authViewModel.isLoading)

                Text("또는")
                    .foregroundColor(.whiffSecondaryText2)

                GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
                    Task {
                        await authViewModel.signInWithGoogle()
                    }
                }
                .frame(width: 280, height: 50)

                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            await authViewModel.signInWithApple(result: result)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(width: 280, height: 50)

                Button("계정이 없으신가요? 회원가입") {
                    showSignUp = true
                }
                .foregroundColor(.whiffSecondaryText1)

                if let error = authViewModel.error {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: error.localizedDescription.contains("서버") ? "network.slash" : "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                                .font(.caption)
                            Spacer()
                        }

                        if error.localizedDescription.contains("502") || error.localizedDescription.contains("일시적") {
                            VStack(spacing: 4) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.orange)
                                    Text("서버가 잠시 후 복구될 예정입니다")
                                        .foregroundColor(.orange)
                                        .font(.caption2)
                                    Spacer()
                                }

                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.whiffSecondaryText2)
                                    Text("무료 서버 사용으로 인한 일시적 지연일 수 있습니다")
                                        .foregroundColor(.whiffSecondaryText2)
                                        .font(.caption2)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.whiffSectionBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .background(Color.whiffMainBackground)
            .ignoresSafeArea(edges: .all)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}

