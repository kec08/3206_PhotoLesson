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

// ============================================================
// MARK: - 🔶 데모 모드 (Mock Data)
// 서버 연결 없이 시연용 목데이터를 반환합니다.
// 실제 서버 연동 시 아래 주석 처리된 원본 코드를 복원하세요.
// ============================================================

class APIService {
    static let shared = APIService()

    // 실제 서버 Base URL (현재 미사용)
    // private let baseURL = "http://localhost:8080/api/v1"

    // MARK: - Mock 상태 관리
    private var enrolledCourseIds: Set<Int> = [101] // courseId 101은 이미 수강 중
    private var mockPortfolios: [Portfolio] = MockData.portfolios
    private var mockPortfolioImages: [Int: [PortfolioImage]] = MockData.portfolioImagesMap
    private var nextPortfolioId = 603
    private var nextImageId = 710

    // MARK: - Auth (Mock)

    func signup(email: String, password: String, fullName: String) async throws -> SignupResponse {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이 (시연용)
        return SignupResponse(
            userId: 1001,
            email: email,
            fullName: fullName,
            createdAt: "2026-03-26T10:00:00Z"
        )
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        return LoginResponse(
            accessToken: "mock_access_token_demo",
            refreshToken: "mock_refresh_token_demo",
            userId: 1001,
            email: email,
            expiresIn: 3600
        )
    }

    // MARK: - User (Mock)

    func getUser(userId: Int) async throws -> User {
        try await Task.sleep(nanoseconds: 300_000_000)
        return User(
            id: userId,
            email: "demo@photolesson.com",
            fullName: "김사진",
            profileImageUrl: nil,
            role: "STUDENT",
            createdAt: "2026-01-15T09:00:00Z"
        )
    }

    // MARK: - Courses (Mock)

    func getCourses(category: CourseCategory? = nil, page: Int = 0, size: Int = 10) async throws -> PageResponse<CourseListItem> {
        try await Task.sleep(nanoseconds: 400_000_000)
        var filtered = MockData.allCourses
        if let category = category {
            filtered = filtered.filter { $0.category == category.rawValue }
        }
        return PageResponse(
            content: filtered,
            page: page,
            size: size,
            totalElements: filtered.count,
            totalPages: 1
        )
    }

    func getCourseDetail(courseId: Int) async throws -> CourseDetail {
        try await Task.sleep(nanoseconds: 400_000_000)
        if let detail = MockData.courseDetails[courseId] {
            // 수강 중이면 진도율 포함
            if enrolledCourseIds.contains(courseId) {
                return CourseDetail(
                    courseId: detail.courseId,
                    title: detail.title,
                    description: detail.description,
                    category: detail.category,
                    level: detail.level,
                    instructorName: detail.instructorName,
                    thumbnailUrl: detail.thumbnailUrl,
                    price: detail.price,
                    sections: detail.sections,
                    userProgress: UserProgress(
                        enrollmentId: 401,
                        completedLectures: 3,
                        totalLectures: detail.sections.reduce(0) { $0 + ($1.lectures?.count ?? 0) },
                        progressPercent: 25.0
                    )
                )
            }
            return detail
        }
        // 기본 반환
        return MockData.courseDetails[101]!
    }

    func searchCourses(keyword: String, page: Int = 0, size: Int = 10) async throws -> PageResponse<CourseListItem> {
        try await Task.sleep(nanoseconds: 400_000_000)
        let keyword = keyword.lowercased()
        let filtered = MockData.allCourses.filter {
            $0.title.lowercased().contains(keyword) ||
            $0.instructorName.lowercased().contains(keyword)
        }
        return PageResponse(
            content: filtered,
            page: page,
            size: size,
            totalElements: filtered.count,
            totalPages: 1
        )
    }

    // MARK: - Sections & Lectures (Mock)

    func getSections(courseId: Int) async throws -> [Section] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockData.courseDetails[courseId]?.sections ?? []
    }

    func getLectures(sectionId: Int) async throws -> [Lecture] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockData.sectionLectures[sectionId] ?? []
    }

    func getLectureDetail(lectureId: Int) async throws -> LectureDetail {
        try await Task.sleep(nanoseconds: 300_000_000)
        return LectureDetail(
            lectureId: lectureId,
            title: "레슨 \(lectureId)",
            videoUrl: nil,
            playTime: 1200,
            sectionId: 201
        )
    }

    // MARK: - Watch History (Mock)

    func recordWatchHistory(lectureId: Int, lastPosition: Int) async throws -> WatchHistoryResponse {
        try await Task.sleep(nanoseconds: 200_000_000)
        return WatchHistoryResponse(
            progressId: 501,
            lectureId: lectureId,
            memberId: 1001,
            lastPosition: lastPosition,
            updatedAt: "2026-03-26T12:00:00Z"
        )
    }

    // MARK: - Enrollment (Mock)

    func enroll(courseId: Int) async throws -> EnrollmentResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        enrolledCourseIds.insert(courseId)
        return EnrollmentResponse(
            enrollmentId: 401 + enrolledCourseIds.count,
            memberId: 1001,
            courseId: courseId,
            enrolledAt: "2026-03-26T12:00:00Z",
            isCompleted: false
        )
    }

    func getEnrollments(userId: Int) async throws -> [EnrollmentResponse] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return enrolledCourseIds.enumerated().map { index, courseId in
            EnrollmentResponse(
                enrollmentId: 401 + index,
                memberId: userId,
                courseId: courseId,
                enrolledAt: "2026-03-01T10:00:00Z",
                isCompleted: false
            )
        }
    }

    func getProgress(userId: Int) async throws -> ProgressResponse {
        try await Task.sleep(nanoseconds: 300_000_000)
        let enrolledCourses = enrolledCourseIds.compactMap { courseId -> EnrolledCourse? in
            guard let course = MockData.allCourses.first(where: { $0.courseId == courseId }) else { return nil }
            return EnrolledCourse(
                courseId: courseId,
                courseTitle: course.title,
                completedLectures: 3,
                totalLectures: course.lectureCount,
                progressPercent: Double(3) / Double(course.lectureCount) * 100
            )
        }
        let totalLectures = enrolledCourses.reduce(0) { $0 + $1.completedLectures }
        let avgPercent = enrolledCourses.isEmpty ? 0.0 : enrolledCourses.reduce(0.0) { $0 + $1.progressPercent } / Double(enrolledCourses.count)
        return ProgressResponse(
            userId: userId,
            progress: enrolledCourses,
            totalCompletedLectures: totalLectures,
            totalEnrolledCourses: enrolledCourses.count,
            totalProgressPercent: avgPercent
        )
    }

    // MARK: - Portfolio (Mock)

    func createPortfolio(name: String, description: String?) async throws -> Portfolio {
        try await Task.sleep(nanoseconds: 500_000_000)
        let portfolio = Portfolio(
            portfolioId: nextPortfolioId,
            memberId: 1001,
            portfolioName: name,
            description: description,
            imageCount: 0,
            createdAt: "2026-03-26T12:00:00Z"
        )
        nextPortfolioId += 1
        mockPortfolios.insert(portfolio, at: 0)
        return portfolio
    }

    func getPortfolios(page: Int = 0, size: Int = 10) async throws -> PageResponse<Portfolio> {
        try await Task.sleep(nanoseconds: 300_000_000)
        return PageResponse(
            content: mockPortfolios,
            page: page,
            size: size,
            totalElements: mockPortfolios.count,
            totalPages: 1
        )
    }

    func getPortfolioDetail(portfolioId: Int) async throws -> Portfolio {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockPortfolios.first { $0.portfolioId == portfolioId } ?? mockPortfolios[0]
    }

    func getPortfolioImages(portfolioId: Int) async throws -> [PortfolioImage] {
        try await Task.sleep(nanoseconds: 400_000_000)
        return mockPortfolioImages[portfolioId] ?? MockData.defaultPortfolioImages
    }

    func deletePortfolioImage(portfolioId: Int, imageId: Int) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        mockPortfolioImages[portfolioId]?.removeAll { $0.imageId == imageId }
    }

    func uploadPortfolioImage(portfolioId: Int, imageData: Data, filename: String) async throws -> PortfolioImage {
        try await Task.sleep(nanoseconds: 800_000_000)
        let newImage = PortfolioImage(
            imageId: nextImageId,
            portfolioId: portfolioId,
            imageUrl: "https://picsum.photos/400/\(300 + nextImageId)",
            thumbnailUrl: "https://picsum.photos/200/\(150 + nextImageId)",
            uploadedAt: "2026-03-26T12:00:00Z"
        )
        nextImageId += 1
        if mockPortfolioImages[portfolioId] != nil {
            mockPortfolioImages[portfolioId]?.insert(newImage, at: 0)
        } else {
            mockPortfolioImages[portfolioId] = [newImage]
        }
        return newImage
    }
}

struct EmptyResponse: Codable {}

// ============================================================
// MARK: - Mock 데이터 정의
// ============================================================

private enum MockData {

    // MARK: 강의 목록
    static let allCourses: [CourseListItem] = [
        CourseListItem(courseId: 101, title: "DSLR 기초 - 노출의 이해", category: "PORTRAIT", level: "BEGINNER",
                       instructorName: "김사진", thumbnailUrl: nil, price: 0, sectionCount: 3, lectureCount: 8, createdAt: "2026-03-01T10:00:00Z"),
        CourseListItem(courseId: 102, title: "인물 촬영 고급 기법", category: "PORTRAIT", level: "ADVANCED",
                       instructorName: "박포토", thumbnailUrl: nil, price: 55000, sectionCount: 2, lectureCount: 6, createdAt: "2026-02-20T10:00:00Z"),
        CourseListItem(courseId: 103, title: "풍경 사진의 모든 것", category: "LANDSCAPE", level: "INTERMEDIATE",
                       instructorName: "이풍경", thumbnailUrl: nil, price: 39000, sectionCount: 3, lectureCount: 9, createdAt: "2026-02-15T10:00:00Z"),
        CourseListItem(courseId: 104, title: "음식 사진 촬영법", category: "FOOD", level: "BEGINNER",
                       instructorName: "최맛집", thumbnailUrl: nil, price: 25000, sectionCount: 2, lectureCount: 5, createdAt: "2026-02-10T10:00:00Z"),
        CourseListItem(courseId: 105, title: "거리 스냅 촬영 마스터", category: "STREET", level: "INTERMEDIATE",
                       instructorName: "정스냅", thumbnailUrl: nil, price: 42000, sectionCount: 2, lectureCount: 7, createdAt: "2026-02-05T10:00:00Z"),
        CourseListItem(courseId: 106, title: "매크로 접사 촬영의 세계", category: "MACRO", level: "ADVANCED",
                       instructorName: "한접사", thumbnailUrl: nil, price: 60000, sectionCount: 2, lectureCount: 6, createdAt: "2026-01-28T10:00:00Z"),
    ]

    // MARK: 강의 상세
    static let courseDetails: [Int: CourseDetail] = [
        101: CourseDetail(
            courseId: 101,
            title: "DSLR 기초 - 노출의 이해",
            description: "DSLR 카메라의 기본적인 노출 설정을 배우는 강의입니다. 초보자도 쉽게 따라할 수 있도록 구성되어 있으며, ISO, 셔터스피드, 조리개의 관계를 실습을 통해 익힙니다.",
            category: "PORTRAIT", level: "BEGINNER", instructorName: "김사진", thumbnailUrl: nil, price: 0,
            sections: [
                Section(sectionId: 201, title: "1. 카메라 기초", sortOrder: 1, lectures: [
                    Lecture(lectureId: 301, title: "노출이란?", videoUrl: nil, playTime: 1200, sortOrder: 1),
                    Lecture(lectureId: 302, title: "ISO 설정하기", videoUrl: nil, playTime: 1500, sortOrder: 2),
                    Lecture(lectureId: 303, title: "셔터 스피드의 이해", videoUrl: nil, playTime: 900, sortOrder: 3),
                ]),
                Section(sectionId: 202, title: "2. 조명과 빛", sortOrder: 2, lectures: [
                    Lecture(lectureId: 304, title: "자연광 활용법", videoUrl: nil, playTime: 1100, sortOrder: 1),
                    Lecture(lectureId: 305, title: "인공조명 기초", videoUrl: nil, playTime: 1300, sortOrder: 2),
                ]),
                Section(sectionId: 203, title: "3. 실전 촬영", sortOrder: 3, lectures: [
                    Lecture(lectureId: 306, title: "야외 촬영 실습", videoUrl: nil, playTime: 1800, sortOrder: 1),
                    Lecture(lectureId: 307, title: "실내 촬영 실습", videoUrl: nil, playTime: 1600, sortOrder: 2),
                    Lecture(lectureId: 308, title: "촬영 후 보정 기초", videoUrl: nil, playTime: 2000, sortOrder: 3),
                ]),
            ],
            userProgress: nil
        ),
        102: CourseDetail(
            courseId: 102,
            title: "인물 촬영 고급 기법",
            description: "전문 포토그래퍼의 인물 촬영 노하우를 배워보세요. 포즈 연출, 조명 세팅, 배경 활용법 등 실무 중심의 고급 테크닉을 다룹니다.",
            category: "PORTRAIT", level: "ADVANCED", instructorName: "박포토", thumbnailUrl: nil, price: 55000,
            sections: [
                Section(sectionId: 204, title: "1. 포즈와 연출", sortOrder: 1, lectures: [
                    Lecture(lectureId: 309, title: "기본 포즈 가이드", videoUrl: nil, playTime: 1400, sortOrder: 1),
                    Lecture(lectureId: 310, title: "표정 연출 테크닉", videoUrl: nil, playTime: 1200, sortOrder: 2),
                    Lecture(lectureId: 311, title: "자연스러운 동작 유도", videoUrl: nil, playTime: 1100, sortOrder: 3),
                ]),
                Section(sectionId: 205, title: "2. 조명 마스터", sortOrder: 2, lectures: [
                    Lecture(lectureId: 312, title: "스튜디오 조명 셋업", videoUrl: nil, playTime: 1600, sortOrder: 1),
                    Lecture(lectureId: 313, title: "렘브란트 조명 기법", videoUrl: nil, playTime: 1300, sortOrder: 2),
                    Lecture(lectureId: 314, title: "역광 인물 촬영", videoUrl: nil, playTime: 1500, sortOrder: 3),
                ]),
            ],
            userProgress: nil
        ),
        103: CourseDetail(
            courseId: 103,
            title: "풍경 사진의 모든 것",
            description: "아름다운 풍경 사진을 촬영하기 위한 모든 것을 배웁니다. 구도, 빛의 활용, 필터 사용법, 장노출 테크닉까지 체계적으로 학습합니다.",
            category: "LANDSCAPE", level: "INTERMEDIATE", instructorName: "이풍경", thumbnailUrl: nil, price: 39000,
            sections: [
                Section(sectionId: 206, title: "1. 구도의 기본", sortOrder: 1, lectures: [
                    Lecture(lectureId: 315, title: "삼분법과 황금비율", videoUrl: nil, playTime: 1000, sortOrder: 1),
                    Lecture(lectureId: 316, title: "리딩라인 활용", videoUrl: nil, playTime: 1100, sortOrder: 2),
                    Lecture(lectureId: 317, title: "전경/중경/배경 구성", videoUrl: nil, playTime: 1200, sortOrder: 3),
                ]),
                Section(sectionId: 207, title: "2. 빛과 시간대", sortOrder: 2, lectures: [
                    Lecture(lectureId: 318, title: "골든아워 촬영", videoUrl: nil, playTime: 1300, sortOrder: 1),
                    Lecture(lectureId: 319, title: "블루아워 촬영", videoUrl: nil, playTime: 1100, sortOrder: 2),
                    Lecture(lectureId: 320, title: "야경 촬영 테크닉", videoUrl: nil, playTime: 1500, sortOrder: 3),
                ]),
                Section(sectionId: 208, title: "3. 필터와 장노출", sortOrder: 3, lectures: [
                    Lecture(lectureId: 321, title: "ND 필터 활용법", videoUrl: nil, playTime: 900, sortOrder: 1),
                    Lecture(lectureId: 322, title: "CPL 필터로 반사 제거", videoUrl: nil, playTime: 800, sortOrder: 2),
                    Lecture(lectureId: 323, title: "장노출로 물 표현하기", videoUrl: nil, playTime: 1400, sortOrder: 3),
                ]),
            ],
            userProgress: nil
        ),
        104: CourseDetail(
            courseId: 104,
            title: "음식 사진 촬영법",
            description: "SNS에서 돋보이는 음식 사진 촬영법을 배웁니다. 스타일링, 앵글, 조명 등 음식을 맛있어 보이게 찍는 비결을 알려드립니다.",
            category: "FOOD", level: "BEGINNER", instructorName: "최맛집", thumbnailUrl: nil, price: 25000,
            sections: [
                Section(sectionId: 209, title: "1. 음식 스타일링", sortOrder: 1, lectures: [
                    Lecture(lectureId: 324, title: "접시와 소품 배치", videoUrl: nil, playTime: 1000, sortOrder: 1),
                    Lecture(lectureId: 325, title: "색감과 질감 살리기", videoUrl: nil, playTime: 1100, sortOrder: 2),
                ]),
                Section(sectionId: 210, title: "2. 촬영 앵글과 조명", sortOrder: 2, lectures: [
                    Lecture(lectureId: 326, title: "탑뷰/45도/사이드 앵글", videoUrl: nil, playTime: 1200, sortOrder: 1),
                    Lecture(lectureId: 327, title: "자연광으로 음식 촬영", videoUrl: nil, playTime: 900, sortOrder: 2),
                    Lecture(lectureId: 328, title: "스마트폰 음식 촬영 팁", videoUrl: nil, playTime: 800, sortOrder: 3),
                ]),
            ],
            userProgress: nil
        ),
        105: CourseDetail(
            courseId: 105,
            title: "거리 스냅 촬영 마스터",
            description: "거리에서 만나는 순간을 포착하는 스냅 촬영 기법을 배웁니다. 빠른 판단력과 구도 감각을 키우는 실전 중심 강의입니다.",
            category: "STREET", level: "INTERMEDIATE", instructorName: "정스냅", thumbnailUrl: nil, price: 42000,
            sections: [
                Section(sectionId: 211, title: "1. 스냅 촬영 기초", sortOrder: 1, lectures: [
                    Lecture(lectureId: 329, title: "스냅 촬영이란?", videoUrl: nil, playTime: 900, sortOrder: 1),
                    Lecture(lectureId: 330, title: "순간 포착 테크닉", videoUrl: nil, playTime: 1100, sortOrder: 2),
                    Lecture(lectureId: 331, title: "거리에서의 에티켓", videoUrl: nil, playTime: 700, sortOrder: 3),
                ]),
                Section(sectionId: 212, title: "2. 실전 스냅", sortOrder: 2, lectures: [
                    Lecture(lectureId: 332, title: "도심 스냅 실습", videoUrl: nil, playTime: 1400, sortOrder: 1),
                    Lecture(lectureId: 333, title: "야시장/축제 촬영", videoUrl: nil, playTime: 1300, sortOrder: 2),
                    Lecture(lectureId: 334, title: "비 오는 날 촬영", videoUrl: nil, playTime: 1000, sortOrder: 3),
                    Lecture(lectureId: 335, title: "흑백 스냅의 매력", videoUrl: nil, playTime: 1200, sortOrder: 4),
                ]),
            ],
            userProgress: nil
        ),
        106: CourseDetail(
            courseId: 106,
            title: "매크로 접사 촬영의 세계",
            description: "작은 세계를 크게 담는 매크로 접사 촬영을 배웁니다. 곤충, 꽃, 물방울 등 미시 세계의 아름다움을 사진으로 표현하는 방법을 알려드립니다.",
            category: "MACRO", level: "ADVANCED", instructorName: "한접사", thumbnailUrl: nil, price: 60000,
            sections: [
                Section(sectionId: 213, title: "1. 매크로 장비와 세팅", sortOrder: 1, lectures: [
                    Lecture(lectureId: 336, title: "매크로 렌즈 선택법", videoUrl: nil, playTime: 1100, sortOrder: 1),
                    Lecture(lectureId: 337, title: "접사링과 확대 장비", videoUrl: nil, playTime: 1000, sortOrder: 2),
                    Lecture(lectureId: 338, title: "삼각대와 포커스 레일", videoUrl: nil, playTime: 900, sortOrder: 3),
                ]),
                Section(sectionId: 214, title: "2. 접사 촬영 실전", sortOrder: 2, lectures: [
                    Lecture(lectureId: 339, title: "꽃과 식물 접사", videoUrl: nil, playTime: 1300, sortOrder: 1),
                    Lecture(lectureId: 340, title: "곤충 접사 촬영", videoUrl: nil, playTime: 1500, sortOrder: 2),
                    Lecture(lectureId: 341, title: "물방울 접사 아트", videoUrl: nil, playTime: 1400, sortOrder: 3),
                ]),
            ],
            userProgress: nil
        ),
    ]

    // MARK: 섹션별 레슨 맵
    static let sectionLectures: [Int: [Lecture]] = {
        var map: [Int: [Lecture]] = [:]
        for detail in courseDetails.values {
            for section in detail.sections {
                if let lectures = section.lectures {
                    map[section.sectionId] = lectures
                }
            }
        }
        return map
    }()

    // MARK: 포트폴리오
    static let portfolios: [Portfolio] = [
        Portfolio(portfolioId: 601, memberId: 1001, portfolioName: "인물 촬영 - 3월",
                  description: "봄빛을 활용한 인물 촬영 연습", imageCount: 6, createdAt: "2026-03-09T10:00:00Z"),
        Portfolio(portfolioId: 602, memberId: 1001, portfolioName: "풍경 촬영 - 여행",
                  description: "제주도 여행 풍경 모음", imageCount: 8, createdAt: "2026-02-15T14:30:00Z"),
    ]

    // MARK: 포트폴리오 이미지
    static let defaultPortfolioImages: [PortfolioImage] = (1...6).map { i in
        PortfolioImage(
            imageId: 700 + i,
            portfolioId: 601,
            imageUrl: "https://picsum.photos/400/\(300 + i * 10)",
            thumbnailUrl: "https://picsum.photos/200/\(150 + i * 10)",
            uploadedAt: "2026-03-09T10:0\(i):00Z"
        )
    }

    static let portfolioImagesMap: [Int: [PortfolioImage]] = [
        601: defaultPortfolioImages,
        602: (1...8).map { i in
            PortfolioImage(
                imageId: 800 + i,
                portfolioId: 602,
                imageUrl: "https://picsum.photos/400/\(350 + i * 10)",
                thumbnailUrl: "https://picsum.photos/200/\(175 + i * 10)",
                uploadedAt: "2026-02-15T14:3\(i):00Z"
            )
        },
    ]
}

// ============================================================
// MARK: - 🔒 원본 서버 연동 코드 (주석 처리)
// 서버 복원 시 위 Mock 코드를 삭제하고 아래 주석을 해제하세요.
// ============================================================

/*
class APIService {
    static let shared = APIService()

    private let baseURL = "http://localhost:8080/api/v1"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Generic Request

    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
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
            throw APIError.unauthorized
        case 409:
            let errorResp = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.conflict(errorResp?.message ?? "충돌이 발생했습니다.")
        default:
            let errorResp = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResp?.message ?? "서버 오류가 발생했습니다.")
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
        return try await request(endpoint: "/courses", queryItems: queryItems)
    }

    func getCourseDetail(courseId: Int) async throws -> CourseDetail {
        return try await request(endpoint: "/courses/\(courseId)")
    }

    func searchCourses(keyword: String, page: Int = 0, size: Int = 10) async throws -> PageResponse<CourseListItem> {
        let queryItems = [
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        return try await request(endpoint: "/courses/search", queryItems: queryItems)
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
*/
