import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var stepsGoal: Int = 10000
    @Published var sleepGoalHours: Double = 8.0
    @Published var notificationsEnabled: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    func fetchProfile() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let fetchedUser = try await APIService.shared.request(endpoint: "/users/me", responseType: User.self)
            self.user = fetchedUser
            self.name = fetchedUser.fullName
            self.email = fetchedUser.email
            self.stepsGoal = fetchedUser.stepsGoal
            self.sleepGoalHours = fetchedUser.sleepGoalHours
            self.notificationsEnabled = fetchedUser.notificationsEnabled
            
            // Sync to local storage for quick access elsewhere if needed
            UserDefaults.standard.set(fetchedUser.email, forKey: "userEmail")
            UserDefaults.standard.set(fetchedUser.fullName, forKey: "userName")
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func saveProfile() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let request = UserUpdateRequest(
                fullName: name,
                stepsGoal: stepsGoal,
                sleepGoalHours: sleepGoalHours,
                notificationsEnabled: notificationsEnabled
            )
            let body = try JSONEncoder().encode(request)
            let updatedUser = try await APIService.shared.request(
                endpoint: "/users/me",
                method: "PATCH",
                body: body,
                responseType: User.self
            )
            self.user = updatedUser
            self.successMessage = "Profile updated successfully"
            
            // Sync to local storage
            UserDefaults.standard.set(updatedUser.fullName, forKey: "userName")
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func logOut() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        // AppState will usually observe this or the view will react to the missing token
    }
}

// RecommendationsViewModel is moved or kept here if needed. 
// It was in the same file previously.
@MainActor
class RecommendationsViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchRecommendations() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await APIService.shared.request(endpoint: "/recommendations/my", responseType: [Recommendation].self)
            self.recommendations = data
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func generateInsights() async {
        isLoading = true
        errorMessage = nil
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let request = RecommendationRequest(date: formatter.string(from: Date()))
            let body = try JSONEncoder().encode(request)
            _ = try await APIService.shared.request(endpoint: "/recommendations/generate", method: "POST", body: body, responseType: Recommendation.self)
            await fetchRecommendations()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
