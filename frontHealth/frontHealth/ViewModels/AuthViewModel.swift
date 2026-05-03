import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func login() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = LoginRequest(email: email, password: password)
            let response = try await AuthService.shared.login(request: request)
            saveUserSession(response: response)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func register() async -> Bool {
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your full name."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let request = RegisterRequest(email: email, password: password, fullName: fullName)
            let response = try await AuthService.shared.register(request: request)
            // Backend returns a TokenResponse on register — save it directly, no need to login again
            saveUserSession(response: response)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    private func saveUserSession(response: TokenResponse) {
        UserDefaults.standard.set(response.accessToken, forKey: "authToken")
        UserDefaults.standard.set(response.user.email, forKey: "userEmail")
        UserDefaults.standard.set(response.user.fullName, forKey: "userName")
    }
}
