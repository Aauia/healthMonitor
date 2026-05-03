import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isOnboardingCompleted: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingCompleted, forKey: "hasSeenOnboarding")
        }
    }
    
    @Published var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        }
    }
    
    init() {
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn") && UserDefaults.standard.string(forKey: "authToken") != nil
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("Unauthorized"), object: nil, queue: .main) { [weak self] _ in
            self?.logOut()
        }
    }
    
    func logOut() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        self.isLoggedIn = false
    }
}
