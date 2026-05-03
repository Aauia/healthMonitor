import Foundation

// Matches backend ActivityLogOut schema
struct ActivitySession: Codable, Identifiable {
    var id: Int?
    var logDate: String
    var steps: Int
    var activeMinutes: Int?
    var caloriesBurned: Int?
    var distanceMeters: Double?
    var syncedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case logDate        = "log_date"
        case steps
        case activeMinutes  = "active_minutes"
        case caloriesBurned = "calories_burned"
        case distanceMeters = "distance_meters"
        case syncedAt       = "synced_at"
    }
}

// Matches backend ActivityLogCreate schema (one entry inside the logs array)
struct ActivityLogEntry: Codable {
    var logDate: String
    var steps: Int
    var activeMinutes: Int?
    var caloriesBurned: Int?
    var distanceMeters: Double?

    enum CodingKeys: String, CodingKey {
        case logDate        = "log_date"
        case steps
        case activeMinutes  = "active_minutes"
        case caloriesBurned = "calories_burned"
        case distanceMeters = "distance_meters"
    }
}

// Matches backend ActivitySyncRequest: { "logs": [...] }
struct ActivitySyncRequest: Codable {
    var logs: [ActivityLogEntry]
}
