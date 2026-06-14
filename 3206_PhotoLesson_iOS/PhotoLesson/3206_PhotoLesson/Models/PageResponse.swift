import Foundation

struct PageResponse<T: Codable>: Codable {
    let content: [T]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
}

struct ErrorResponse: Codable {
    let status: Int
    let message: String
    let timestamp: String?
}
