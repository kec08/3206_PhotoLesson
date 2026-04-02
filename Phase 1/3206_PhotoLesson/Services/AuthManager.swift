import Foundation
import SwiftUI
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isLoggedIn = false
    @Published var currentUserId: Int?
    @Published var accessToken: String?

    private let tokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"

    init() {
        self.accessToken = UserDefaults.standard.string(forKey: tokenKey)
        self.currentUserId = UserDefaults.standard.object(forKey: userIdKey) as? Int
        self.isLoggedIn = accessToken != nil
    }

    func saveLoginInfo(response: LoginResponse) {
        self.accessToken = response.accessToken
        self.currentUserId = response.userId
        self.isLoggedIn = true
        UserDefaults.standard.set(response.accessToken, forKey: tokenKey)
        UserDefaults.standard.set(response.refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(response.userId, forKey: userIdKey)
    }

    func logout() {
        self.accessToken = nil
        self.currentUserId = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
}
