import Foundation

struct EnrollmentRequest: Codable {
    let courseId: Int
}

struct EnrollmentResponse: Codable, Identifiable {
    let enrollmentId: Int
    let memberId: Int
    let courseId: Int
    let enrolledAt: String
    let isCompleted: Bool

    var id: Int { enrollmentId }
}

struct EnrolledCourse: Codable, Identifiable {
    let courseId: Int
    let title: String
    let category: String?
    let level: String?
    let thumbnailUrl: String?
    let totalLectures: Int
    let completedLectures: Int
    let progressPercent: Double
    let enrolledAt: String?

    var id: Int { courseId }

    // 기존 코드 호환용
    var courseTitle: String { title }
}

struct ProgressResponse: Codable {
    let userId: Int
    let progress: [EnrolledCourse]
    let totalCompletedLectures: Int
    let totalEnrolledCourses: Int
    let totalProgressPercent: Double
}
