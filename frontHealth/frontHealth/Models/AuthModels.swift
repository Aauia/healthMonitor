import Foundation

struct User: Codable {
    let id: Int
    let email: String
    var fullName: String
    let role: String
    var stepsGoal: Int
    var sleepGoalHours: Double
    var notificationsEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case stepsGoal = "steps_goal"
        case sleepGoalHours = "sleep_goal_hours"
        case notificationsEnabled = "notifications_enabled"
    }
}

struct UserUpdateRequest: Codable {
    var fullName:             String? = nil
    var stepsGoal:            Int?    = nil
    var sleepGoalHours:      Double? = nil
    var notificationsEnabled: Bool?   = nil
    
    enum CodingKeys: String, CodingKey {
        case fullName             = "full_name"
        case stepsGoal            = "steps_goal"
        case sleepGoalHours      = "sleep_goal_hours"
        case notificationsEnabled = "notifications_enabled"
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

// Request Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let fullName: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case fullName = "full_name"
    }
}
