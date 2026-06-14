import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 헤더
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.mainCoral.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.mainCoral)
                        }

                        Text("회원가입")
                            .font(.system(size: 24, weight: .bold))
                        Text("PhotoLesson과 함께 시작하세요")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)

                    // 입력 필드
                    VStack(spacing: 24) {
                        fieldRow(label: "이름", placeholder: "이름을 입력해주세요", text: $fullName)
                        fieldRow(label: "이메일", placeholder: "이메일을 입력해주세요", text: $email, keyboard: .emailAddress)
                        secureFieldRow(label: "비밀번호", placeholder: "비밀번호를 입력해주세요", text: $password)
                        secureFieldRow(label: "비밀번호 확인", placeholder: "비밀번호를 다시 입력해주세요", text: $confirmPassword)
                    }
                    .padding(.horizontal, 28)

                    // 에러
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .padding(.top, 16)
                            .transition(.opacity)
                    }

                    // 가입 버튼
                    Button {
                        Task { await signup() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("가입하기")
                                    .font(.system(size: 17, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isFormValid ? Color.mainCoral : Color(.systemGray4))
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .animation(.easeInOut(duration: 0.2), value: isFormValid)
                    }
                    .disabled(isLoading || !isFormValid)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert("가입 완료", isPresented: $showSuccess) {
            Button("로그인하기") { dismiss() }
        } message: {
            Text("회원가입이 완료되었습니다.\n로그인해주세요.")
        }
    }

    // MARK: - 필드 컴포넌트

    private func fieldRow(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .font(.system(size: 17))
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .padding(.bottom, 8)
            Rectangle()
                .fill(text.wrappedValue.isEmpty ? Color(.systemGray4) : Color.mainCoral)
                .frame(height: 1.5)
                .animation(.easeInOut(duration: 0.2), value: text.wrappedValue.isEmpty)
        }
    }

    private func secureFieldRow(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            SecureField(placeholder, text: text)
                .font(.system(size: 17))
                .padding(.bottom, 8)
            Rectangle()
                .fill(text.wrappedValue.isEmpty ? Color(.systemGray4) : Color.mainCoral)
                .frame(height: 1.5)
                .animation(.easeInOut(duration: 0.2), value: text.wrappedValue.isEmpty)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !fullName.isEmpty && password == confirmPassword && confirmPassword.count >= 1
    }

    private func signup() async {
        isLoading = true
        errorMessage = nil

        guard password == confirmPassword else {
            errorMessage = "비밀번호가 일치하지 않습니다."
            isLoading = false
            return
        }

        do {
            _ = try await APIService.shared.signup(email: email, password: password, fullName: fullName)
            showSuccess = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "회원가입에 실패했습니다."
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        SignupView()
    }
}
