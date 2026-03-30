import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // 로고
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    Text("PhotoLesson")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("사진 촬영을 배워보세요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // 입력 필드
                VStack(spacing: 16) {
                    TextField("이메일", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    SecureField("비밀번호", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }
                .padding(.horizontal)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // 로그인 버튼
                Button {
                    Task { await login() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("로그인")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                // 회원가입 링크
                Button("계정이 없으신가요? 회원가입") {
                    showSignup = true
                }
                .font(.subheadline)

                Spacer()
            }
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIService.shared.login(email: email, password: password)
            authManager.saveLoginInfo(response: response)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "로그인에 실패했습니다."
        }
        isLoading = false
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
