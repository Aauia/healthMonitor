import Foundation

@MainActor
class ActivityViewModel: ObservableObject {
    @Published var activityData: [ActivitySession] = []
    @Published var selectedPeriod: Int = 0 // 0: Day, 1: Week, 2: Month
    @Published var stepsGoal: Int = 10000
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchActivity() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let today = Date()
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let startStr = formatter.string(from: weekAgo)
            let endStr = formatter.string(from: today)
            
            async let fetchHistory = APIService.shared.request(
                endpoint: "/activity/my?start=\(startStr)&end=\(endStr)",
                responseType: [ActivitySession].self
            )
            async let fetchUser = APIService.shared.request(
                endpoint: "/users/me",
                responseType: User.self
            )
            
            let (data, user) = try await (fetchHistory, fetchUser)
            self.activityData = data
            self.stepsGoal = user.stepsGoal
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func syncActivity(session: ActivitySyncRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            let body = try JSONEncoder().encode(session)
            _ = try await APIService.shared.request(endpoint: "/activity/sync", method: "POST", body: body, responseType: StatusResponse.self)
            await fetchActivity()
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    var currentSteps: Int {
        activityData.last?.steps ?? 0
    }
    
    var progress: Double {
        min(Double(currentSteps) / Double(stepsGoal), 1.0)
    }
}
