import Foundation

struct Lecture: Codable, Identifiable {
    let lectureId: Int
    let title: String
    let videoUrl: String?
    let playTime: Int
    let sortOrder: Int?

    var id: Int { lectureId }

    var formattedPlayTime: String {
        let minutes = playTime / 60
        let seconds = playTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct LectureDetail: Codable {
    let lectureId: Int
    let title: String
    let videoUrl: String?
    let playTime: Int
    let sectionId: Int?
}
