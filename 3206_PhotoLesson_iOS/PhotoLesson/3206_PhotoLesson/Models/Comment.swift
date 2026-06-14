//
//  Comment.swift
//  3206_PhotoLesson
//

import Foundation

struct Comment: Codable, Identifiable {
    let id: Int
    let lectureId: Int
    let memberId: Int
    let memberName: String
    let content: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "commentId"
        case lectureId, memberId, memberName, content, createdAt
    }
}

struct CommentCreateRequest: Codable {
    let content: String
}
