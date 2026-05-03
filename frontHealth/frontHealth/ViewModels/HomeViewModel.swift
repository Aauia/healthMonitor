import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var user: User?
    @Published var sleepToday: SleepSession?
    @Published var activityToday: ActivitySession?
    @Published var supplementsToday: [Supplement] = []
    @Published var dailySupplements: [DailySupplementItem] = []
    @Published var recommendations: [Recommendation] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        async let fetchProfile = fetchUserProfile()
        async let fetchSleep = fetchSleepData()
        async let fetchActivity = fetchActivityData()
        async let fetchSupplements = fetchSupplementsData()
        async let fetchRecs = fetchRecommendationsData()
        
        _ = await (fetchProfile, fetchSleep, fetchActivity, fetchSupplements, fetchRecs)
        
        isLoading = false
    }
    
    private func fetchUserProfile() async {
        do {
            let fetchedUser = try await APIService.shared.request(endpoint: "/users/me", responseType: User.self)
            self.user = fetchedUser
        } catch {
            print("Profile error: \(error)")
        }
    }
    
    private func fetchSleepData() async {
        do {
            let data = try await APIService.shared.request(endpoint: "/sleep/my", responseType: [SleepSession].self)
            self.sleepToday = data.last
        } catch {
            print("Sleep error: \(error)")
        }
    }
    
    private func fetchActivityData() async {
        do {
            let data = try await APIService.shared.request(endpoint: "/activity/my", responseType: [ActivitySession].self)
            self.activityToday = data.last
        } catch {
            print("Activity error: \(error)")
        }
    }
    
    private func fetchSupplementsData() async {
        do {
            let data = try await APIService.shared.request(endpoint: "/supplements/my", responseType: [Supplement].self)
            self.supplementsToday = data
            self.parseDailySupplements()
        } catch {
            print("Supplements error: \(error)")
        }
    }
    
    private func parseDailySupplements() {
        var items: [DailySupplementItem] = []
        for supplement in supplementsToday {
            let timesString = supplement.reminderTimes ?? supplement.reminderTime ?? ""
            var times: [String] = []
            
            if timesString.hasPrefix("[") {
                if let data = timesString.data(using: .utf8),
                   let array = try? JSONDecoder().decode([String].self, from: data) {
                    times = array
                }
            } else {
                times = timesString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            }
            
            if times.isEmpty {
                items.append(DailySupplementItem(supplement: supplement, plannedTime: "Anytime"))
            } else {
                for time in times {
                    items.append(DailySupplementItem(supplement: supplement, plannedTime: time))
                }
            }
        }
        self.dailySupplements = items.sorted { $0.plannedTime < $1.plannedTime }
    }
    
    func logSupplement(id: Int, time: String, taken: Bool) async {
        // Optimistic update
        if let idx = supplementsToday.firstIndex(where: { $0.id == id }) {
            if taken {
                if supplementsToday[idx].takenTimesToday != nil {
                    if !supplementsToday[idx].takenTimesToday!.contains(time) {
                        supplementsToday[idx].takenTimesToday!.append(time)
                    }
                } else {
                    supplementsToday[idx].takenTimesToday = [time]
                }
            } else {
                supplementsToday[idx].takenTimesToday?.removeAll { $0 == time }
            }
            parseDailySupplements()
        }
        
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayStr = formatter.string(from: Date())
            
            let request = SupplementLogRequest(logDate: todayStr, plannedTime: time, taken: taken)
            let body = try JSONEncoder().encode(request)
            
            _ = try await APIService.shared.request(endpoint: "/supplements/\(id)/log", method: "POST", body: body, responseType: StatusResponse.self)
            await fetchSupplementsData()
        } catch {
            self.errorMessage = error.localizedDescription
            await fetchSupplementsData()
        }
    }
    
    private func fetchRecommendationsData() async {
        do {
            let data = try await APIService.shared.request(endpoint: "/recommendations/my", responseType: [Recommendation].self)
            self.recommendations = data
        } catch {
            print("Recommendations error: \(error)")
        }
    }
    
    var healthScore: Int {
        var score = 40
        
        let stepsGoal = Double(user?.stepsGoal ?? 10000)
        let sleepGoalMin = (user?.sleepGoalHours ?? 8.0) * 60.0
        
        if let sleep = sleepToday {
            let sleepRatio = min(Double(sleep.durationMin) / sleepGoalMin, 1.0)
            score += Int(sleepRatio * 25)
        }
        
        if let act = activityToday {
            let activityRatio = min(Double(act.steps) / stepsGoal, 1.0)
            score += Int(activityRatio * 25)
        }
        
        if !supplementsToday.isEmpty {
            let takenCount = supplementsToday.filter { ($0.takenTimesToday?.count ?? 0) > 0 }.count
            let totalCount = supplementsToday.count
            let supplementRatio = Double(takenCount) / Double(totalCount)
            score += Int(supplementRatio * 10)
        }
        
        return min(score, 100)
    }
}
