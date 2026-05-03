import Foundation

struct Supplement: Codable, Identifiable {
    var id: Int?
    var name: String
    var type: String?
    var dosage: String?
    var reminderTime: String?
    var reminderTimes: String?
    var instructions: String?
    var daysOfWeek: String?
    var startDate: String?
    var endDate: String?
    var isActive: Bool?
    var isTakenToday: Bool?
    var takenTimesToday: [String]?
    var progressPercent: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case dosage
        case reminderTime = "reminder_time"
        case reminderTimes = "reminder_times"
        case instructions
        case daysOfWeek = "days_of_week"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case isTakenToday = "is_taken_today"
        case takenTimesToday = "taken_times_today"
        case progressPercent = "progress_percent"
    }
}

struct SupplementRequest: Codable {
    var name: String
    var type: String
    var dosage: String?
    var reminderTime: String?
    var instructions: String?
    var reminderTimes: [String]
    var daysOfWeek: [Int]
    var startDate: String
    var endDate: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case dosage
        case reminderTime = "reminder_time"
        case instructions
        case reminderTimes = "reminder_times"
        case daysOfWeek = "days_of_week"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct SupplementProgress: Codable {
    var supplementId: Int
    var progressPercent: Double
    var totalLogs: Int
    
    enum CodingKeys: String, CodingKey {
        case supplementId = "supplement_id"
        case progressPercent = "progress_percent"
        case totalLogs = "total_logs"
    }
}

struct SupplementLogRequest: Codable {
    var logDate: String
    var plannedTime: String
    var taken: Bool
    
    enum CodingKeys: String, CodingKey {
        case logDate = "log_date"
        case plannedTime = "planned_time"
        case taken
    }
}

struct StatusResponse: Codable {
    var status: String
}
