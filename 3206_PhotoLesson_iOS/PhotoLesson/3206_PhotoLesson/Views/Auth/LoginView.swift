import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // 로고
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.mainCoral.opacity(0.12))
                                .frame(width: 100, height: 100)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.mainCoral)
                        }
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                        Text("PhotoLesson")
                            .font(.system(size: 28, weight: .bold))
                        Text("사진 촬영을 배워보세요")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 48)

                    // 입력 필드
                    VStack(spacing: 24) {
                        // 이메일
                        VStack(alignment: .leading, spacing: 10) {
                            Text("이메일")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            TextField("이메일을 입력해주세요", text: $email)
                                .font(.system(size: 17))
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding(.bottom, 8)
                            Rectangle()
                                .fill(email.isEmpty ? Color(.systemGray4) : Color.mainCoral)
                                .frame(height: 1.5)
                                .animation(.easeInOut(duration: 0.2), value: email.isEmpty)
                        }

                        // 비밀번호
                        VStack(alignment: .leading, spacing: 10) {
                            Text("비밀번호")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            SecureField("비밀번호를 입력해주세요", text: $password)
                                .font(.system(size: 17))
                                .textContentType(.password)
                                .padding(.bottom, 8)
                            Rectangle()
                                .fill(password.isEmpty ? Color(.systemGray4) : Color.mainCoral)
                                .frame(height: 1.5)
                                .animation(.easeInOut(duration: 0.2), value: password.isEmpty)
                        }
                    }
                    .padding(.horizontal, 28)

                    // 에러
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .padding(.top, 12)
                            .transition(.opacity)
                    }

                    Spacer()

                    // 회원가입 링크
                    HStack(spacing: 4) {
                        Text("계정이 없으신가요?")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Button("회원가입") {
                            showSignup = true
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.mainCoral)
                    }
                    .padding(.bottom, 16)

                    // 로그인 버튼
                    Button {
                        Task { await login() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("로그인")
                                    .font(.system(size: 17, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            (email.isEmpty || password.isEmpty)
                            ? Color(.systemGray4)
                            : Color.mainCoral
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .animation(.easeInOut(duration: 0.2), value: email.isEmpty || password.isEmpty)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    appeared = true
                }
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
