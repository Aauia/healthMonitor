import Foundation

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    func login(request: LoginRequest) async throws -> TokenResponse {
        let bodyData = try JSONEncoder().encode(request)
        return try await APIService.shared.request(
            endpoint: "/auth/login",
            method: "POST",
            body: bodyData,
            responseType: TokenResponse.self
        )
    }
    
    // Register also returns TokenResponse (access_token + user) from the backend
    func register(request: RegisterRequest) async throws -> TokenResponse {
        let bodyData = try JSONEncoder().encode(request)
        return try await APIService.shared.request(
            endpoint: "/auth/register",
            method: "POST",
            body: bodyData,
            responseType: TokenResponse.self
        )
    }
}
