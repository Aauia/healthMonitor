import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning," }
        else if hour < 17 { return "Good afternoon," }
        else { return "Good evening," }
    }

    private var takenCount: Int {
        viewModel.dailySupplements.filter { $0.isTaken }.count
    }

    private var stepsProgress: Double {
        let steps = Double(viewModel.activityToday?.steps ?? 0)
        return min(steps / 10000.0, 1.0)
    }

    // ── Dynamic health condition colours ─────────────────────────

    /// Sleep: green ≥ 7h, orange 5–7h, red < 5h
    private var sleepColor: Color {
        let mins = viewModel.sleepToday?.durationMin ?? 0
        if mins >= 420 { return emerald500 }
        if mins >= 300 { return Color.orange }
        return Color.red
    }

    /// Activity: green ≥ 8k steps, orange 4–8k, red < 4k
    private var activityColor: Color {
        let steps = viewModel.activityToday?.steps ?? 0
        if steps >= 8000 { return emerald500 }
        if steps >= 4000 { return Color.orange }
        return Color.red
    }

    /// Score ring colour
    private var scoreColor: Color {
        let s = viewModel.healthScore
        if s >= 75 { return sky600 }
        if s >= 50 { return Color.orange }
        return Color.red
    }

    /// Score label
    private var scoreLabel: String {
        let s = viewModel.healthScore
        if s >= 75 { return "Looking great" }
        if s >= 50 { return "Room to improve" }
        return "Needs attention"
    }
    
    // Tailwind Colors
    let sky100 = Color(red: 224/255, green: 242/255, blue: 254/255)
    let teal50 = Color(red: 240/255, green: 253/255, blue: 250/255)
    let sky900 = Color(red: 12/255, green: 74/255, blue: 110/255)
    let sky600 = Color(red: 2/255, green: 132/255, blue: 199/255)
    let emerald500 = Color(red: 16/255, green: 185/255, blue: 129/255)
    let emerald50 = Color(red: 236/255, green: 253/255, blue: 245/255)
    let indigo50 = Color(red: 238/255, green: 242/255, blue: 255/255)
    let indigo600 = Color(red: 79/255, green: 70/255, blue: 229/255)
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    VStack {
                        Spacer().frame(height: 100)
                        ProgressView("Loading your health data…")
                            .tint(sky600)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        healthScoreCard
                        sleepCard
                        activityCard
                        supplementsCard
                        recommendationsSection
                    }
                }
            }
            .background(Color(UIColor.systemGray6).opacity(0.3).edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.fetchDashboardData()
                }
            }
            .refreshable {
                await viewModel.fetchDashboardData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Text(user.firstName ?? "user")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
    
    private var healthScoreCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [sky100, teal50], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health Score")
                            .font(.system(size: 14))
                            .foregroundColor(sky900.opacity(0.6))
                        Text(scoreLabel)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(sky900)
                    }
                    Spacer()
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(scoreColor)
                }

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 12)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.healthScore) / 100.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: viewModel.healthScore)

                    VStack(spacing: 0) {
                        Text("\(viewModel.healthScore)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(sky900)
                        Text("out of 100")
                            .font(.system(size: 12))
                            .foregroundColor(sky900.opacity(0.6))
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(24)
        }
        .padding(.horizontal, 20)
    }
    
    private var sleepCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(sleepColor.opacity(0.4), lineWidth: 2)
                )

            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(sleepColor.opacity(0.12)).frame(width: 40, height: 40)
                        Image(systemName: "moon.fill")
                            .foregroundColor(sleepColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last night")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(String(format: "%.1fh sleep", Double(viewModel.sleepToday?.durationMin ?? 0) / 60.0))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
                // Condition badge
                Text(viewModel.sleepToday == nil ? "No data" :
                        (viewModel.sleepToday!.durationMin >= 420 ? "Good" :
                        (viewModel.sleepToday!.durationMin >= 300 ? "Fair" : "Poor")))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(sleepColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(sleepColor.opacity(0.12))
                    .cornerRadius(10)
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
    }
    
    private var activityCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(activityColor.opacity(0.4), lineWidth: 2)
                )

            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(activityColor.opacity(0.12)).frame(width: 40, height: 40)
                            Image(systemName: "shoeprints.fill")
                                .foregroundColor(activityColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Steps today")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text("\(viewModel.activityToday?.steps ?? 0)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    Spacer()
                    // Condition badge
                    Text(viewModel.activityToday == nil ? "No data" :
                            ((viewModel.activityToday!.steps >= 8000) ? "Active" :
                            ((viewModel.activityToday!.steps >= 4000) ? "Moderate" : "Low")))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(activityColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(activityColor.opacity(0.12))
                        .cornerRadius(10)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.systemGray6))
                        Capsule()
                            .fill(activityColor)
                            .frame(width: max(0, geometry.size.width * CGFloat(stepsProgress)))
                    }
                }
                .frame(height: 8)
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
    }
    
    private var supplementsCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )

            VStack(spacing: 16) {
                HStack {
                    Text("Today's Supplements")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(takenCount)/\(viewModel.dailySupplements.count)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                VStack(spacing: 12) {
                    if viewModel.dailySupplements.isEmpty {
                        Text("No supplements added yet.")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(viewModel.dailySupplements) { item in
                            HomeSupplementRow(item: item) {
                                if let id = item.supplement.id {
                                    Task { await viewModel.logSupplement(id: id, time: item.plannedTime, taken: !item.isTaken) }
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
    }
    
    private var recommendationsEmptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .foregroundColor(.gray)
            Text("No insights yet. Check the Recommendations tab.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    private var recommendationsList: some View {
        ForEach(Array(viewModel.recommendations.enumerated()), id: \.offset) { index, rec in
            recommendationRow(index: index, message: rec.content)
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                if viewModel.recommendations.isEmpty {
                    recommendationsEmptyState
                } else {
                    recommendationsList
                }
            }
        }
        .padding(.bottom, 40)
    }
    
    private func recommendationRow(index: Int, message: String) -> some View {
        let bgColors: [Color] = [indigo50, sky100, emerald50, Color(red: 254/255, green: 242/255, blue: 242/255)]
        let iconColors: [Color] = [indigo600, sky600, emerald500, .red]
        let iconNames = ["moon.fill", "shoeprints.fill", "heart.fill", "bolt.fill"]
        
        return HStack(spacing: 12) {
            Image(systemName: iconNames[index % iconNames.count])
                .foregroundColor(iconColors[index % iconColors.count])
                .font(.system(size: 20))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 31/255, green: 41/255, blue: 55/255))
                .lineLimit(2)
            Spacer()
        }
        .padding()
        .background(bgColors[index % bgColors.count])
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

// MARK: - Supplement row extracted to avoid @ViewBuilder complexity

struct HomeSupplementRow: View {
    let item: DailySupplementItem
    let onTap: () -> Void

    private let checkedColor = Color(red: 16/255, green: 185/255, blue: 129/255) // emerald500

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                checkbox
                labels
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var checkbox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(item.isTaken ? checkedColor : Color.clear)
                .frame(width: 20, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(
                            item.isTaken ? checkedColor : Color(UIColor.systemGray4),
                            lineWidth: 2
                        )
                )
            if item.isTaken {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.supplement.name)
                .font(.system(size: 16, weight: item.isTaken ? .regular : .medium))
                .foregroundColor(item.isTaken ? .gray : .primary)
                .strikethrough(item.isTaken, color: .gray)
            Text(item.plannedTime)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}
