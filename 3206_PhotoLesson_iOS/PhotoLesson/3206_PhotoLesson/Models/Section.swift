import Foundation

struct Section: Codable, Identifiable {
    let sectionId: Int
    let title: String
    let sortOrder: Int
    let lectures: [Lecture]?

    var id: Int { sectionId }
}
