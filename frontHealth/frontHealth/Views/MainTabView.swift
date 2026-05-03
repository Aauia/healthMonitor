import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            SleepView()
                .tabItem {
                    Label("Sleep", systemImage: "moon.zzz")
                }
            
            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "figure.walk")
                }
            
            SupplementsView()
                .tabItem {
                    Label("Supplements", systemImage: "pills")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .accentColor(.hmPrimary)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppState())
    }
}
