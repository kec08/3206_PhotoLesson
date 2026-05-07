import Foundation
import SwiftUI
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isLoggedIn = false
    @Published var currentUserId: Int?
    @Published var accessToken: String?
    @Published var currentRole: String = "STUDENT"

    private let tokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"
    private let roleKey = "userRole"

    var isAdmin: Bool { currentRole == "ADMIN" }
    var isTeacher: Bool { currentRole == "TEACHER" || currentRole == "ADMIN" }
    var isStudent: Bool { currentRole == "STUDENT" }

    init() {
        self.accessToken = UserDefaults.standard.string(forKey: tokenKey)
        self.currentUserId = UserDefaults.standard.object(forKey: userIdKey) as? Int
        self.currentRole = UserDefaults.standard.string(forKey: roleKey) ?? "STUDENT"
        self.isLoggedIn = accessToken != nil
    }

    func saveLoginInfo(response: LoginResponse) {
        self.accessToken = response.accessToken
        self.currentUserId = response.userId
        self.isLoggedIn = true
        UserDefaults.standard.set(response.accessToken, forKey: tokenKey)
        UserDefaults.standard.set(response.refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(response.userId, forKey: userIdKey)

        // JWT에서 role 추출
        if let role = extractRoleFromJWT(response.accessToken) {
            self.currentRole = role
            UserDefaults.standard.set(role, forKey: roleKey)
        }
    }

    func logout() {
        self.accessToken = nil
        self.currentUserId = nil
        self.isLoggedIn = false
        self.currentRole = "STUDENT"
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: roleKey)
    }

    /// 서버에서 현재 유저 정보를 다시 가져와 role 동기화
    func refreshCurrentUser() async {
        guard let userId = currentUserId else { return }
        do {
            let user = try await APIService.shared.getUser(userId: userId)
            if let role = user.role {
                self.currentRole = role
                UserDefaults.standard.set(role, forKey: roleKey)
            }
        } catch {}
    }

    /// JWT 토큰에서 role claim 추출
    private func extractRoleFromJWT(_ token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let role = json["role"] as? String else {
            return nil
        }
        return role
    }
}
