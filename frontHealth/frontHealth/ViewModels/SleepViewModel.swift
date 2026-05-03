import Foundation

@MainActor
class SleepViewModel: ObservableObject {
    @Published var sleepData: [SleepSession] = []
    @Published var sleepGoalHours: Double = 8.0
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchSleepHistory() async {
        isLoading = true
        errorMessage = nil
        
        async let fetchHistory = APIService.shared.request(endpoint: "/sleep/my", responseType: [SleepSession].self)
        async let fetchUser = APIService.shared.request(endpoint: "/users/me", responseType: User.self)
        
        do {
            let (data, user) = try await (fetchHistory, fetchUser)
            self.sleepData = data
            self.sleepGoalHours = user.sleepGoalHours
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func addSleepSession(session: SleepSessionRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            let body = try JSONEncoder().encode(session)
            _ = try await APIService.shared.request(endpoint: "/sleep", method: "POST", body: body, responseType: SleepSession.self)
            await fetchSleepHistory() // Refresh data
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    var lastNightDuration: Double {
        if let last = sleepData.last {
            return Double(last.durationMin) / 60.0
        }
        return 0.0
    }
    
    var insightText: String {
        let duration = lastNightDuration
        if duration >= sleepGoalHours {
            return "Great job! You met your sleep goal."
        } else if duration >= sleepGoalHours - 1 {
            return "You were close to your goal. Try to get to bed a little earlier tonight."
        } else {
            return "You need more rest. Prioritize sleep tonight to feel refreshed tomorrow."
        }
    }
}
