import Foundation

struct WatchHistoryRequest: Codable {
    let lastPosition: Int
}

struct WatchHistoryResponse: Codable {
    let progressId: Int
    let lectureId: Int
    let memberId: Int
    let lastPosition: Int
    let updatedAt: String
}
