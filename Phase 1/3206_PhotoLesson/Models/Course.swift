import Foundation

enum CourseCategory: String, CaseIterable, Codable {
    case PORTRAIT
    case LANDSCAPE
    case FOOD
    case STREET
    case MACRO

    var displayName: String {
        switch self {
        case .PORTRAIT: return "인물"
        case .LANDSCAPE: return "풍경"
        case .FOOD: return "음식"
        case .STREET: return "거리"
        case .MACRO: return "매크로"
        }
    }
}

enum CourseLevel: String, Codable {
    case BEGINNER
    case INTERMEDIATE
    case ADVANCED

    var displayName: String {
        switch self {
        case .BEGINNER: return "초급"
        case .INTERMEDIATE: return "중급"
        case .ADVANCED: return "고급"
        }
    }
}

struct CourseListItem: Codable, Identifiable {
    let courseId: Int
    let title: String
    let category: String
    let level: String
    let instructorName: String
    let thumbnailUrl: String?
    let price: Int?
    let sectionCount: Int
    let lectureCount: Int
    let createdAt: String

    var id: Int { courseId }

    var categoryEnum: CourseCategory? {
        CourseCategory(rawValue: category)
    }

    var levelEnum: CourseLevel? {
        CourseLevel(rawValue: level)
    }
}

struct CourseDetail: Codable, Identifiable {
    let courseId: Int
    let title: String
    let description: String?
    let category: String?
    let level: String?
    let instructorName: String
    let thumbnailUrl: String?
    let price: Int?
    let sections: [Section]
    let userProgress: UserProgress?

    var id: Int { courseId }
}

struct UserProgress: Codable {
    let enrollmentId: Int?
    let completedLectures: Int
    let totalLectures: Int
    let progressPercent: Double
}
