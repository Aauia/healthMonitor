import SwiftUI

struct SupplementsView: View {
    @StateObject private var viewModel = SupplementsViewModel()
    @State private var showingAddSheet = false
    @State private var loggedId: Int? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6).opacity(0.3).edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView("Loading supplements…")
                        .tint(.hmPrimary)
                } else if viewModel.supplements.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No supplements added yet.")
                            .foregroundColor(.gray)
                        Button(action: { showingAddSheet = true }) {
                            Text("Add Supplement")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(red: 16/255, green: 185/255, blue: 129/255))
                                .cornerRadius(10)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Text("Supplements")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: { showingAddSheet = true }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 16/255, green: 185/255, blue: 129/255))
                                            .frame(width: 40, height: 40)
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                            
                            // List of supplements
                            VStack(spacing: 12) {
                                ForEach(viewModel.groupedSupplements, id: \.0) { timeGroup in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(timeGroup.0)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 20)
                                            .padding(.top, 8)
                                        
                                        ForEach(timeGroup.1) { item in
                                            SupplementCardRow(item: item, onLog: { isTaken in
                                                if let id = item.supplement.id {
                                                    loggedId = id
                                                    Task {
                                                        await viewModel.logSupplement(id: id, time: item.plannedTime, taken: isTaken)
                                                        loggedId = nil
                                                    }
                                                }
                                            }, onDelete: {
                                                if let id = item.supplement.id {
                                                    Task {
                                                        await viewModel.deleteSupplement(id: id)
                                                    }
                                                }
                                            })
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Consistency Streak
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Consistency Streak")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(red: 12/255, green: 74/255, blue: 110/255))
                                Text("12 days")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 12/255, green: 74/255, blue: 110/255))
                                Text("Keep up the great work!")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 3/255, green: 105/255, blue: 161/255))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(red: 240/255, green: 249/255, blue: 255/255))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSheet) {
                AddSupplementView(viewModel: viewModel)
            }
            .onAppear {
                Task {
                    await viewModel.fetchSupplements()
                }
            }
            .refreshable {
                await viewModel.fetchSupplements()
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

struct SupplementCardRow: View {
    var item: DailySupplementItem
    var onLog: (Bool) -> Void
    var onDelete: () -> Void
    
    private func colorFor(name: String) -> Color {
        let colors: [Color] = [
            Color(red: 245/255, green: 158/255, blue: 11/255), // amber-500
            Color(red: 14/255, green: 165/255, blue: 233/255), // sky-500
            Color(red: 16/255, green: 185/255, blue: 129/255), // emerald-500
            Color(red: 236/255, green: 72/255, blue: 153/255), // pink-500
            Color(red: 168/255, green: 85/255, blue: 247/255)  // purple-500
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            
            HStack(alignment: .center, spacing: 16) {
                NavigationLink(destination: SupplementDetailView(supplement: item.supplement)) {
                    HStack(alignment: .top, spacing: 16) {
                        // Icon box
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(colorFor(name: item.supplement.name).opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "pill.fill")
                                .foregroundColor(colorFor(name: item.supplement.name))
                                .font(.system(size: 24))
                                .rotationEffect(.degrees(45))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.supplement.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .strikethrough(item.isTaken, color: .gray)
                            
                            HStack(spacing: 8) {
                                Text(item.supplement.dosage ?? "")
                                Text("•")
                                Text(item.plannedTime)
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.bottom, 6)
                            
                            let progress = item.supplement.progressPercent ?? 0.0
                            HStack(spacing: 12) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(UIColor.systemGray6))
                                            .frame(height: 8)
                                        
                                        Capsule()
                                            .fill(colorFor(name: item.supplement.name))
                                            .frame(width: max(0, geometry.size.width * CGFloat(progress / 100.0)), height: 8)
                                    }
                                }
                                .frame(height: 8)
                                
                                Text("\(Int(progress))%")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    // Log Button
                    Button(action: {
                        onLog(!item.isTaken)
                    }) {
                        ZStack {
                            Circle()
                                .stroke(item.isTaken ? Color(red: 16/255, green: 185/255, blue: 129/255) : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(item.isTaken ? Color(red: 16/255, green: 185/255, blue: 129/255) : Color.clear))
                            
                            if item.isTaken {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Delete Button
                    Button(action: {
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
            }
            .padding(20)
        }
        .opacity(item.isTaken ? 0.6 : 1.0)
        .blur(radius: item.isTaken ? 0.5 : 0)
    }
}
