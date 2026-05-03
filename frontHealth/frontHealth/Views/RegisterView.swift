import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("Fill in the details below to get started.")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Full Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                    TextField("e.g. Alex Smith", text: $viewModel.fullName)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                    TextField("you@example.com", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                    SecureField("At least 6 characters", text: $viewModel.password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    let success = await viewModel.register()
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
                        Text("Register")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    viewModel.fullName.isEmpty || viewModel.email.isEmpty || viewModel.password.isEmpty
                    ? Color.gray.opacity(0.4)
                    : Color.hmPrimary
                )
                .foregroundColor(.white)
                .cornerRadius(10)
                .font(.headline)
            }
            .padding(.horizontal)
            .disabled(viewModel.isLoading || viewModel.fullName.isEmpty || viewModel.email.isEmpty || viewModel.password.isEmpty)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Already have an account? **Login**")
                    .foregroundColor(.hmPrimary)
            }
            .padding(.bottom, 20)
        }
        .background(Color.hmBackground.edgesIgnoringSafeArea(.all))
    }
}
