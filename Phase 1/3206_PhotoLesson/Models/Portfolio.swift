import Foundation

struct Portfolio: Codable, Identifiable {
    let portfolioId: Int
    let memberId: Int?
    let portfolioName: String
    let description: String?
    let imageCount: Int?
    let createdAt: String?

    var id: Int { portfolioId }
}

struct PortfolioCreateRequest: Codable {
    let portfolioName: String
    let description: String?
}

struct PortfolioImage: Codable, Identifiable {
    let imageId: Int
    let portfolioId: Int
    let imageUrl: String
    let thumbnailUrl: String?
    let uploadedAt: String?

    var id: Int { imageId }
}
