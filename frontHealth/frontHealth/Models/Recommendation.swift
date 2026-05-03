import Foundation

struct Recommendation: Codable, Identifiable {
    var id: Int?
    var category: String?
    var message: String
    var createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case message
        case createdAt = "created_at"
    }
}

struct RecommendationRequest: Codable {
    var date: String
}
