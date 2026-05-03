import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(String)
    case invalidResponse
    case decodingError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .requestFailed(let message): return "Request Failed: \(message)"
        case .invalidResponse: return "Invalid Response from Server"
        case .decodingError: return "Failed to decode response"
        case .unauthorized: return "Unauthorized. Please log in again."
        }
    }
}

class APIService {
    static let shared = APIService()
    private let baseURL = "http://127.0.0.1:8086"
    
    private init() {}
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            // Can be observed by AppState to log user out
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("Unauthorized"), object: nil)
            }
            throw APIError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Attempt to decode a backend error message
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorDict["detail"] as? String {
                throw APIError.requestFailed(detail)
            }
            throw APIError.requestFailed("Status Code: \(httpResponse.statusCode)")
        }
        
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
}
