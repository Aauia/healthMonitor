import SwiftUI

struct RecommendationsView: View {
    @StateObject private var viewModel = RecommendationsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.hmBackground.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView("Generating insights…")
                        .tint(.hmPrimary)
                } else if viewModel.recommendations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.hmPrimary.opacity(0.5))
                        Text("No recommendations yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Tap \"Generate Insights\" to get personalized health tips based on your data.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            Task { await viewModel.generateInsights() }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Generate Insights")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.hmPrimary)
                            .cornerRadius(12)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.recommendations) { rec in
                                CardView {
                                    RecommendationCard(recommendation: rec)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarItems(trailing:
                Button(action: {
                    Task { await viewModel.generateInsights() }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Generate")
                    }
                    .foregroundColor(.hmPrimary)
                }
                .disabled(viewModel.isLoading)
            )
            .task {
                await viewModel.fetchRecommendations()
            }
            .refreshable {
                await viewModel.fetchRecommendations()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
