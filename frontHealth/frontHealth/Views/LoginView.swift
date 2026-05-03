import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.hmPrimary)
                
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    SecureField("Password", text: $viewModel.password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    Task {
                        let success = await viewModel.login()
                        if success {
                            appState.isLoggedIn = true
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.hmPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                Spacer()
                
                Button(action: {
                    showRegister = true
                }) {
                    Text("Don't have an account? **Register**")
                        .foregroundColor(.hmPrimary)
                }
                
                Button(action: {
                    appState.isOnboardingCompleted = false
                }) {
                    Text("View Tutorial")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                .padding(.bottom, 20)
            }
            .background(Color.hmBackground.edgesIgnoringSafeArea(.all))
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}
