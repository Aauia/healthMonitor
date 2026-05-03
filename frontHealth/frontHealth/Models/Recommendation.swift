import Foundation

struct Recommendation: Codable, Identifiable {
    var id: Int?
    var type: String?
    var content: String
    var createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case content
        case createdAt = "created_at"
    }
}

struct RecommendationRequest: Codable {
    var date: String
}
