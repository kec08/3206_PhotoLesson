import Foundation

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case conflict(String)
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 URL입니다."
        case .invalidResponse: return "서버 응답 오류입니다."
        case .unauthorized: return "인증이 필요합니다."
        case .conflict(let msg): return msg
        case .serverError(let msg): return msg
        case .decodingError: return "데이터 처리 오류입니다."
        case .networkError(let err): return err.localizedDescription
        }
    }
}

class APIService {
    static let shared = APIService()

    // ngrok 공개 URL (Wi-Fi 변경 무관, https)
    private let serverHost = "https://nonpunitive-unsuperlatively-josefine.ngrok-free.dev"
    private var baseURL: String { serverHost + "/api/v1" }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    /// 상대 경로 이미지 URL을 절대 URL로 변환
    /// "/uploads/abc.jpg" → "http://172.28.15.240:8080/uploads/abc.jpg"
    func fullImageURL(_ path: String?) -> String? {
        guard let path = path, !path.isEmpty else { return nil }
        if path.hasPrefix("http") { return path }
        return serverHost + path
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true,
        isRetry: Bool = false
    ) async throws -> T {
        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = await AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200, 201:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            // 인증 불필요한 요청(로그인/회원가입)은 그냥 에러 반환
            if !requiresAuth {
                let errorResp = try? decoder.decode(ErrorResponse.self, from: data)
                throw APIError.serverError(errorResp?.message ?? "이메일 또는 비밀번호가 일치하지 않습니다.")
            }
            // 토큰 만료 → 재발급 시도 (1번만)
            if !isRetry {
                let refreshed = await refreshToken()
                if refreshed {
                    return try await request(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        queryItems: queryItems,
                        requiresAuth: requiresAuth,
                        isRetry: true
                    )
                }
            }
            // 재발급 실패 → 로그아웃
            await AuthManager.shared.logout()
            throw APIError.unauthorized
        case 409:
            let errorResp = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.conflict(errorResp?.message ?? "충돌이 발생했습니다.")
        default:
            let errorResp = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResp?.message ?? "서버 오류가 발생했습니다.")
        }
    }

    // MARK: - 토큰 재발급

    private func refreshToken() async -> Bool {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            return false
        }

        guard let url = URL(string: baseURL + "/auth/refresh") else { return false }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return false
            }
            let loginResponse = try decoder.decode(LoginResponse.self, from: data)
            await AuthManager.shared.saveLoginInfo(response: loginResponse)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Auth

    func signup(email: String, password: String, fullName: String) async throws -> SignupResponse {
        let body = SignupRequest(email: email, password: password, fullName: fullName)
        return try await request(endpoint: "/auth/signup", method: "POST", body: body, requiresAuth: false)
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let body = LoginRequest(email: email, password: password)
        return try await request(endpoint: "/auth/login", method: "POST", body: body, requiresAuth: false)
    }

    // MARK: - User

    func getUser(userId: Int) async throws -> User {
        return try await request(endpoint: "/users/\(userId)")
    }

    func updateUser(userId: Int, fullName: String?, profileImageUrl: String?) async throws -> User {
        var body: [String: String] = [:]
        if let fullName = fullName { body["fullName"] = fullName }
        if let profileImageUrl = profileImageUrl { body["profileImageUrl"] = profileImageUrl }
        return try await request(endpoint: "/users/\(userId)", method: "PUT", body: body)
    }

    // MARK: - Courses

    func getCourses(category: CourseCategory? = nil, page: Int = 0, size: Int = 10) async throws -> PageResponse<CourseListItem> {
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)"),
            URLQueryItem(name: "sort", value: "createdAt,desc")
        ]
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        return try await request(endpoint: "/courses", queryItems: queryItems, requiresAuth: false)
    }

    func getCourseDetail(courseId: Int) async throws -> CourseDetail {
        return try await request(endpoint: "/courses/\(courseId)", requiresAuth: false)
    }

    func searchCourses(keyword: String, page: Int = 0, size: Int = 10) async throws -> PageResponse<CourseListItem> {
        let queryItems = [
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        return try await request(endpoint: "/courses/search", queryItems: queryItems, requiresAuth: false)
    }

    // MARK: - Sections & Lectures

    func getSections(courseId: Int) async throws -> [Section] {
        return try await request(endpoint: "/courses/\(courseId)/sections")
    }

    func getLectures(sectionId: Int) async throws -> [Lecture] {
        return try await request(endpoint: "/sections/\(sectionId)/lectures")
    }

    func getLectureDetail(lectureId: Int) async throws -> LectureDetail {
        return try await request(endpoint: "/lectures/\(lectureId)")
    }

    // MARK: - Watch History

    func recordWatchHistory(lectureId: Int, lastPosition: Int) async throws -> WatchHistoryResponse {
        let body = WatchHistoryRequest(lastPosition: lastPosition)
        return try await request(endpoint: "/lectures/\(lectureId)/watch-history", method: "POST", body: body)
    }

    func getWatchHistory(userId: Int) async throws -> [WatchHistoryResponse] {
        return try await request(endpoint: "/users/\(userId)/watch-history")
    }

    // MARK: - Enrollment

    func enroll(courseId: Int) async throws -> EnrollmentResponse {
        let body = EnrollmentRequest(courseId: courseId)
        return try await request(endpoint: "/enrollments", method: "POST", body: body)
    }

    func getEnrollments(userId: Int) async throws -> [EnrollmentResponse] {
        return try await request(endpoint: "/users/\(userId)/enrollments")
    }

    func getProgress(userId: Int) async throws -> ProgressResponse {
        return try await request(endpoint: "/users/\(userId)/progress")
    }

    // MARK: - Portfolio

    func createPortfolio(name: String, description: String?) async throws -> Portfolio {
        let body = PortfolioCreateRequest(portfolioName: name, description: description)
        return try await request(endpoint: "/portfolios", method: "POST", body: body)
    }

    func getPortfolios(page: Int = 0, size: Int = 10) async throws -> PageResponse<Portfolio> {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        return try await request(endpoint: "/portfolios", queryItems: queryItems)
    }

    func getPortfolioDetail(portfolioId: Int) async throws -> Portfolio {
        return try await request(endpoint: "/portfolios/\(portfolioId)")
    }

    func getPortfolioImages(portfolioId: Int) async throws -> [PortfolioImage] {
        return try await request(endpoint: "/portfolios/\(portfolioId)/images")
    }

    func deletePortfolioImage(portfolioId: Int, imageId: Int) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/portfolios/\(portfolioId)/images/\(imageId)",
            method: "DELETE"
        )
    }

    func uploadPortfolioImage(portfolioId: Int, imageData: Data, filename: String) async throws -> PortfolioImage {
        guard let url = URL(string: baseURL + "/portfolios/\(portfolioId)/images") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = await AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }

        return try decoder.decode(PortfolioImage.self, from: data)
    }
}

struct EmptyResponse: Codable {}
