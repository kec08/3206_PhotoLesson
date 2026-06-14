import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let fullName: String
    let profileImageUrl: String?
    let role: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case email
        case fullName
        case profileImageUrl
        case role
        case createdAt
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let userId: Int
    let email: String
    let expiresIn: Int
}

struct SignupRequest: Codable {
    let email: String
    let password: String
    let fullName: String
}

struct SignupResponse: Codable {
    let userId: Int
    let email: String
    let fullName: String
    let createdAt: String
}
