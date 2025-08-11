import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showValidationErrors = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("회원가입")
                .font(.title)
                .bold()
                .foregroundColor(.whiffLogo)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("이름")
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                    TextField("이름을 입력하세요", text: $name)
                        .textFieldStyle(CustomWhiffTextFieldStyle())
                        .textContentType(.name)
                    
                    if showValidationErrors && name.isEmpty {
                        Text("이름을 입력해주세요")
                            .foregroundColor(.red)
                            .font(.caption2)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("이메일")
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                    TextField("이메일을 입력하세요", text: $email)
                        .textFieldStyle(CustomWhiffTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    if showValidationErrors && !isValidEmail(email) {
                        Text("올바른 이메일 형식을 입력해주세요")
                            .foregroundColor(.red)
                            .font(.caption2)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("비밀번호")
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                    SecureField("비밀번호 (6자 이상)", text: $password)
                        .textFieldStyle(CustomWhiffTextFieldStyle())
                        .textContentType(.newPassword)
                    
                    if showValidationErrors && password.count < 6 {
                        Text("비밀번호는 6자 이상이어야 합니다")
                            .foregroundColor(.red)
                            .font(.caption2)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("비밀번호 확인")
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                    SecureField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                        .textFieldStyle(CustomWhiffTextFieldStyle())
                        .textContentType(.newPassword)
                    
                    if showValidationErrors && password != confirmPassword {
                        Text("비밀번호가 일치하지 않습니다")
                            .foregroundColor(.red)
                            .font(.caption2)
                    }
                }
            }
            .padding(.horizontal)
            
            Button(action: {
                if isFormValid {
                    Task {
                        print("🚀 회원가입 시작 - 이메일: \(email), 이름: \(name)")
                        await authViewModel.signUp(email: email, password: password, name: name)
                        
                        if authViewModel.isAuthenticated {
                            print("✅ 회원가입 성공 - 자동 뒤로가기")
                            dismiss()
                        }
                    }
                } else {
                    showValidationErrors = true
                    print("❌ 폼 유효성 검사 실패")
                }
            }) {
                if authViewModel.isLoading {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("회원가입 중...")
                            .foregroundColor(.whiffWhiteText)
                    }
                } else {
                    Text("회원가입")
                        .fontWeight(.semibold)
                        .foregroundColor(.whiffWhiteText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.whiffNextCard : Color.whiffSecondaryText2)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(authViewModel.isLoading)
            
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("뒤로") {
                    dismiss()
                }
                .foregroundColor(.whiffSecondaryText1)
            }
        }
        .onAppear {
            authViewModel.error = nil
        }
    }
    
    private var isFormValid: Bool {
        let isValid = !name.isEmpty &&
                     isValidEmail(email) &&
                     password.count >= 6 &&
                     password == confirmPassword
        
        print("🔍 폼 유효성 검사 - 이름: \(name.isEmpty ? "❌" : "✅"), 이메일: \(isValidEmail(email) ? "✅" : "❌"), 비밀번호: \(password.count >= 6 ? "✅" : "❌"), 확인: \(password == confirmPassword ? "✅" : "❌")")
        
        return isValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

