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
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    Text("회원가입")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    TextField("이름", text: $fullName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)

                    TextField("이메일", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    SecureField("비밀번호", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)

                    SecureField("비밀번호 확인", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await signup() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("가입하기")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isLoading || !isFormValid)
            }
        }
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .alert("가입 완료", isPresented: $showSuccess) {
            Button("로그인하기") { dismiss() }
        } message: {
            Text("회원가입이 완료되었습니다.\n로그인해주세요.")
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !fullName.isEmpty && password == confirmPassword
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
