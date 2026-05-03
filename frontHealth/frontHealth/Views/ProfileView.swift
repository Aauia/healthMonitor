import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showLogoutAlert = false
    @State private var isEditing = false
    
    // Get first letter of name for avatar
    private var avatarLetter: String {
        viewModel.name.first.map(String.init)?.uppercased() ?? "U"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading && viewModel.user == nil {
                    loadingView
                } else {
                    mainContent
                }
            }
            .background(Color.hmBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("Profile")
            .navigationBarItems(trailing: editButton)
            .onAppear {
                Task { await viewModel.fetchProfile() }
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    viewModel.logOut()
                    appState.logOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
            .overlay(statusOverlay)
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer().frame(height: 100)
            ProgressView("Loading profile...")
                .tint(.hmPrimary)
        }
    }

    private var mainContent: some View {
        VStack(spacing: 20) {
            profileCard
            healthGoalsCard
            settingsCard
            
            if isEditing {
                saveButton
            }
            
            logoutButton
            
            Spacer(minLength: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var editButton: some View {
        Button(isEditing ? "Cancel" : "Edit") {
            if isEditing {
                Task { await viewModel.fetchProfile() }
            }
            isEditing.toggle()
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.36, green: 0.72, blue: 0.92),
                                         Color(red: 0.20, green: 0.78, blue: 0.70)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    Text(avatarLetter)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if isEditing {
                        TextField("Full Name", text: $viewModel.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title2)
                    } else {
                        Text(viewModel.name.isEmpty ? "User" : viewModel.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.hmText)
                    }
                    Text(viewModel.email.isEmpty ? "" : viewModel.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var healthGoalsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Health Goals")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.hmText)
                .padding(.bottom, 16)
            
            if isEditing {
                GoalEditRow(
                    title: "Daily Steps",
                    value: Binding(
                        get: { String(viewModel.stepsGoal) },
                        set: { viewModel.stepsGoal = Int($0) ?? 0 }
                    ),
                    unit: "steps"
                )
                Divider()
                GoalEditRow(
                    title: "Sleep Goal",
                    value: Binding(
                        get: { String(format: "%.1f", viewModel.sleepGoalHours) },
                        set: { viewModel.sleepGoalHours = Double($0) ?? 0.0 }
                    ),
                    unit: "hours"
                )
            } else {
                GoalRow(
                    icon: "target",
                    iconColor: Color(red: 0.05, green: 0.72, blue: 0.34),
                    bgColor: Color(red: 0.05, green: 0.72, blue: 0.34).opacity(0.08),
                    title: "Daily Steps",
                    subtitle: "\(viewModel.stepsGoal) steps",
                    hasDivider: true
                )
                
                GoalRow(
                    icon: "moon.zzz.fill",
                    iconColor: Color(red: 0.37, green: 0.38, blue: 0.87),
                    bgColor: Color(red: 0.37, green: 0.38, blue: 0.87).opacity(0.08),
                    title: "Sleep Goal",
                    subtitle: "\(String(format: "%.1f", viewModel.sleepGoalHours)) hours/night",
                    hasDivider: false
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.hmText)
                .padding(.bottom, 16)
            
            NotificationRow(
                icon: "bell.fill",
                title: "Push Notifications",
                subtitle: "Enable reminders",
                isOn: $viewModel.notificationsEnabled,
                hasDivider: false
            )
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var saveButton: some View {
        Button(action: {
            Task {
                await viewModel.saveProfile()
                isEditing = false
            }
        }) {
            if viewModel.isLoading {
                ProgressView().tint(.white)
            } else {
                Text("Save Changes")
                    .fontWeight(.bold)
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.hmMint)
        .cornerRadius(24)
        .padding(.top, 10)
    }

    private var logoutButton: some View {
        Button(action: { showLogoutAlert = true }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private var statusOverlay: some View {
        VStack {
            if let success = viewModel.successMessage {
                Text(success)
                    .padding()
                    .background(Color(red: 16/255, green: 185/255, blue: 129/255))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.successMessage = nil
                        }
                    }
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            viewModel.errorMessage = nil
                        }
                    }
            }
            Spacer()
        }
        .padding(.top, 100)
        .animation(.spring(), value: viewModel.successMessage)
        .animation(.spring(), value: viewModel.errorMessage)
    }
}

// ── Sub-components ─────────────────────────────────────────────────

struct GoalEditRow: View {
    let title: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.hmText)
            Spacer()
            TextField(unit, text: $value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
            Text(unit)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct GoalRow: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let title: String
    let subtitle: String
    let hasDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(bgColor)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.hmText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 4)
                
                Spacer()
            }
            .padding(.vertical, 12)
            
            if hasDivider {
                Divider()
            }
        }
    }
}

struct NotificationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let hasDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.58, green: 0.34, blue: 0.96).opacity(0.08))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.58, green: 0.34, blue: 0.96))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.hmText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 4)
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(Color(red: 0.05, green: 0.72, blue: 0.34))
            }
            .padding(.vertical, 12)
            
            if hasDivider {
                Divider()
            }
        }
    }
}
