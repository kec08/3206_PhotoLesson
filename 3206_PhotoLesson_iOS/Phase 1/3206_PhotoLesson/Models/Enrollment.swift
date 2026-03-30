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
    let courseTitle: String
    let completedLectures: Int
    let totalLectures: Int
    let progressPercent: Double

    var id: Int { courseId }
}

struct ProgressResponse: Codable {
    let userId: Int
    let progress: [EnrolledCourse]
    let totalCompletedLectures: Int
    let totalEnrolledCourses: Int
    let totalProgressPercent: Double
}
