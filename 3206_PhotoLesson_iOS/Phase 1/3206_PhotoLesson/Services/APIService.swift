import Foundation

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case conflict(String)
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
    case noConnection

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 URL입니다."
        case .invalidResponse: return "서버 응답 오류입니다."
        case .unauthorized: return "인증이 필요합니다."
        case .conflict(let msg): return msg
        case .serverError(let msg): return msg
        case .decodingError: return "데이터 처리 오류입니다."
        case .networkError(let err): return err.localizedDescription
        case .noConnection: return "네트워크 연결을 확인해주세요."
        }
    }
}

class APIService {
    static let shared = APIService()

    // ngrok 배포 URL (2026-05-07)
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
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        if requiresAuth, let token = await AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
            throw APIError.noConnection
        } catch {
            throw APIError.networkError(error)
        }

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
            if !requiresAuth {
                let msg = APIService.parseErrorMessage(from: data) ?? "이메일 또는 비밀번호가 일치하지 않습니다."
                throw APIError.serverError(msg)
            }
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
            await AuthManager.shared.logout()
            throw APIError.unauthorized
        case 409:
            let msg = APIService.parseErrorMessage(from: data) ?? "충돌이 발생했습니다."
            throw APIError.conflict(msg)
        default:
            let msg = APIService.parseErrorMessage(from: data) ?? "서버 오류가 발생했습니다."
            throw APIError.serverError(msg)
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
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
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

    func uploadProfileImage(userId: Int, imageData: Data) async throws -> User {
        guard let url = URL(string: baseURL + "/users/\(userId)/profile-image") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        if let token = await AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try decoder.decode(User.self, from: data)
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
        let loggedIn = await AuthManager.shared.isLoggedIn
        return try await request(endpoint: "/courses/\(courseId)", requiresAuth: loggedIn)
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
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

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

// MARK: - Admin API

extension APIService {
    func getAdminUsers() async throws -> [User] {
        return try await request(endpoint: "/admin/users")
    }

    func changeUserRole(userId: Int, role: String) async throws -> User {
        let body = ["role": role]
        return try await request(endpoint: "/admin/users/\(userId)/role", method: "PATCH", body: body)
    }

    func deleteUser(userId: Int) async throws {
        guard let url = URL(string: baseURL + "/admin/users/\(userId)") else { throw APIError.invalidURL }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        if let token = await AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...204).contains(httpResponse.statusCode) else {
            let msg = APIService.parseErrorMessage(from: data) ?? "계정 삭제에 실패했습니다."
            throw APIError.serverError(msg)
        }
    }
}

// MARK: - 에러 응답 파싱 (message / error 두 필드 fallback)

extension APIService {
    static func parseErrorMessage(from data: Data) -> String? {
        if let resp = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return resp.message
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = json["error"] as? String ?? json["message"] as? String {
            return msg
        }
        return nil
    }
}

// MARK: - Teacher API

extension APIService {
    // 강의 생성
    func createTeacherCourse(_ request: TeacherCourseRequest) async throws -> [String: Any] {
        guard let url = URL(string: baseURL + "/teacher/courses") else { throw APIError.invalidURL }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        if let token = await AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...201).contains(httpResponse.statusCode) else {
            let msg = APIService.parseErrorMessage(from: data) ?? "강의 생성에 실패했습니다."
            throw APIError.serverError(msg)
        }
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    // 내 강의 목록
    func getTeacherCourses() async throws -> [CourseListItem] {
        return try await request(endpoint: "/teacher/courses")
    }

    // 강의 수정
    func updateTeacherCourse(courseId: Int, _ request: TeacherCourseRequest) async throws {
        guard let url = URL(string: baseURL + "/teacher/courses/\(courseId)") else { throw APIError.invalidURL }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        if let token = await AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = try JSONEncoder().encode(request)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...204).contains(httpResponse.statusCode) else {
            let msg = APIService.parseErrorMessage(from: data) ?? "강의 수정에 실패했습니다."
            throw APIError.serverError(msg)
        }
    }

    // 강의 삭제
    func deleteTeacherCourse(courseId: Int) async throws {
        guard let url = URL(string: baseURL + "/teacher/courses/\(courseId)") else { throw APIError.invalidURL }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        if let token = await AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...204).contains(httpResponse.statusCode) else {
            let msg = APIService.parseErrorMessage(from: data) ?? "강의 삭제에 실패했습니다."
            throw APIError.serverError(msg)
        }
    }

    // 섹션 추가
    func addSection(courseId: Int, title: String) async throws {
        let body = ["title": title]
        let _: [String: String] = try await self.request(endpoint: "/teacher/courses/\(courseId)/sections", method: "POST", body: body)
    }

    // 섹션 수정
    func updateSection(sectionId: Int, title: String) async throws {
        let body = ["title": title]
        let _: [String: String] = try await self.request(endpoint: "/teacher/sections/\(sectionId)", method: "PUT", body: body)
    }

    // 섹션 삭제
    func deleteSection(sectionId: Int) async throws {
        let _: EmptyResponse = try await request(endpoint: "/teacher/sections/\(sectionId)", method: "DELETE")
    }

    // 레슨 추가
    func addLecture(sectionId: Int, title: String, videoUrl: String, playTime: Int) async throws {
        let body = LectureCreateBody(title: title, videoUrl: videoUrl, playTime: playTime)
        let _: [String: String] = try await self.request(endpoint: "/teacher/sections/\(sectionId)/lectures", method: "POST", body: body)
    }

    // 레슨 수정
    func updateLecture(lectureId: Int, title: String, videoUrl: String, playTime: Int) async throws {
        let body = LectureCreateBody(title: title, videoUrl: videoUrl, playTime: playTime)
        let _: [String: String] = try await self.request(endpoint: "/teacher/lectures/\(lectureId)", method: "PUT", body: body)
    }

    // 레슨 삭제
    func deleteLecture(lectureId: Int) async throws {
        let _: EmptyResponse = try await request(endpoint: "/teacher/lectures/\(lectureId)", method: "DELETE")
    }

    // 수강생 대시보드 (전체)
    func getTeacherDashboard() async throws -> TeacherDashboard {
        return try await request(endpoint: "/teacher/dashboard")
    }

    // 강의별 수강생 상세
    func getCourseDashboard(courseId: Int) async throws -> CourseDashboard {
        return try await request(endpoint: "/teacher/courses/\(courseId)/dashboard")
    }

    // 강의 썸네일 업로드
    func uploadCourseThumbnail(courseId: Int, imageData: Data) async throws -> String {
        guard let url = URL(string: baseURL + "/teacher/courses/\(courseId)/thumbnail") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        if let token = await AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"thumbnail.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let msg = APIService.parseErrorMessage(from: data) ?? "썸네일 업로드에 실패했습니다."
            throw APIError.serverError(msg)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let thumbnailUrl = json["thumbnailUrl"] as? String {
            return thumbnailUrl
        }
        return ""
    }
}

// MARK: - Teacher Models

struct TeacherCourseRequest: Codable {
    let title: String
    let description: String
    let category: String
    let level: String
    let price: Int?
    let thumbnailUrl: String?
    let sections: [SectionCreateRequest]?
}

struct SectionCreateRequest: Codable {
    let title: String
    let lectures: [LectureCreateRequest]?
}

struct LectureCreateRequest: Codable {
    let title: String
    let videoUrl: String
    let playTime: Int
}

struct LectureCreateBody: Codable {
    let title: String
    let videoUrl: String
    let playTime: Int
}

struct TeacherDashboard: Codable {
    let totalCourses: Int
    let totalStudents: Int
    let totalLectures: Int
    let courses: [CourseSummary]
}

struct CourseSummary: Codable, Identifiable {
    let courseId: Int
    let title: String
    let category: String?
    let studentCount: Int
    let lectureCount: Int
    let createdAt: String?

    var id: Int { courseId }
}

struct CourseDashboard: Codable {
    let courseId: Int
    let courseTitle: String
    let totalStudents: Int
    let totalLectures: Int
    let students: [StudentProgress]
}

struct StudentProgress: Codable, Identifiable {
    let userId: Int
    let fullName: String
    let email: String
    let completedLectures: Int
    let totalLectures: Int
    let progressPercent: Double
    let enrolledAt: String?

    var id: Int { userId }
}

// MARK: - 댓글 API

extension APIService {
    /// 댓글 목록 조회
    func getComments(lectureId: Int) async throws -> [Comment] {
        return try await request(
            endpoint: "/lectures/\(lectureId)/comments",
            method: "GET",
            requiresAuth: true
        )
    }

    /// 댓글 작성
    func createComment(lectureId: Int, content: String) async throws -> Comment {
        return try await request(
            endpoint: "/lectures/\(lectureId)/comments",
            method: "POST",
            body: CommentCreateRequest(content: content),
            requiresAuth: true
        )
    }

    /// 댓글 삭제
    func deleteComment(commentId: Int) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/comments/\(commentId)",
            method: "DELETE",
            requiresAuth: true
        )
    }
}
