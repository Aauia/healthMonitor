import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentTab = 0
    
    let screens = [
        ("heart.text.square", "Track your health easily", "Monitor all your daily metrics in one place."),
        ("moon.zzz", "Understand your sleep", "Get insights into your sleep quality and duration."),
        ("figure.walk", "Stay active every day", "Reach your goals with daily step tracking."),
        ("pills", "Never miss your vitamins", "Get reminded to take your supplements on time.")
    ]
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Skip") {
                    appState.isOnboardingCompleted = true
                }
                .padding()
                .foregroundColor(.hmPrimary)
            }
            
            TabView(selection: $currentTab) {
                ForEach(0..<screens.count, id: \.self) { index in
                    VStack(spacing: 20) {
                        Image(systemName: screens[index].0)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .foregroundColor(.hmPrimary)
                            .padding(.bottom, 40)
                        
                        Text(screens[index].1)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.hmText)
                            .multilineTextAlignment(.center)
                        
                        Text(screens[index].2)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            Button(action: {
                if currentTab < screens.count - 1 {
                    withAnimation {
                        currentTab += 1
                    }
                } else {
                    appState.isOnboardingCompleted = true
                }
            }) {
                Text(currentTab == screens.count - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.hmPrimary)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            
            Button(action: {
                appState.isOnboardingCompleted = true
            }) {
                Text("Already have an account? **Log In**")
                    .font(.subheadline)
                    .foregroundColor(.hmPrimary)
                    .padding(.top, 12)
            }
            .padding(.bottom, 20)
        }
        .background(Color.hmBackground.edgesIgnoringSafeArea(.all))
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppState())
    }
}
