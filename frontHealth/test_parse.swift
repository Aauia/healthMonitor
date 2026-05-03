import Foundation

let jsonStr = """
{
  "id": 5,
  "user_id": 3,
  "name": "Test",
  "type": "vitamin",
  "dosage": "234",
  "reminder_time": null,
  "reminder_times": "02:26,20:26",
  "start_date": "2026-05-05",
  "end_date": "2026-07-01",
  "is_active": true,
  "is_taken_today": false,
  "taken_times_today": [],
  "progress_percent": 0.0
}
"""

struct Supplement: Codable {
    var id: Int?
    var name: String
    var type: String?
    var dosage: String?
    var reminderTime: String?
    var reminderTimes: String?
    var daysOfWeek: String?
    var startDate: String?
    var endDate: String?
    var isActive: Bool?
    var isTakenToday: Bool?
    var takenTimesToday: [String]?
    var progressPercent: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, dosage
        case reminderTime = "reminder_time"
        case reminderTimes = "reminder_times"
        case daysOfWeek = "days_of_week"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case isTakenToday = "is_taken_today"
        case takenTimesToday = "taken_times_today"
        case progressPercent = "progress_percent"
    }
}

if let data = jsonStr.data(using: .utf8) {
    do {
        let supp = try JSONDecoder().decode(Supplement.self, from: data)
        print("Decoded OK")
        print("reminderTime:", supp.reminderTime ?? "nil")
        print("reminderTimes:", supp.reminderTimes ?? "nil")
        
        let timesString = supp.reminderTimes ?? supp.reminderTime ?? ""
        var times: [String] = []
        if timesString.hasPrefix("[") {
            print("Array")
        } else {
            times = timesString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            print("Times count:", times.count)
            print("Times:", times)
        }
    } catch {
        print("Decode Error:", error)
    }
}
