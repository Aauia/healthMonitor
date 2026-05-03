import SwiftUI
import Charts

// MARK: - Main View

struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()
    @StateObject private var recViewModel = RecommendationsViewModel()
    @State private var showingSyncSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.hmBackground.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 24) {
                        periodPicker
                        WeeklySummaryCard(viewModel: viewModel)
                        StepsChartCard(viewModel: viewModel)
                        ActivityMinutesChartCard(viewModel: viewModel)
                        ActivityHistoryCard(viewModel: viewModel)
                        InsightsCard(recViewModel: recViewModel)
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationBarItems(trailing:
                Button(action: { showingSyncSheet = true }) {
                    Image(systemName: "plus").foregroundColor(.hmPrimary)
                }
            )
            .sheet(isPresented: $showingSyncSheet) {
                SyncActivityView(viewModel: viewModel)
            }
            .task {
                await viewModel.fetchActivity()
                await recViewModel.fetchRecommendations()
            }
            .refreshable {
                await viewModel.fetchActivity()
                await recViewModel.fetchRecommendations()
            }
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            Text("Day").tag(0)
            Text("Week").tag(1)
            Text("Month").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Weekly Summary

struct WeeklySummaryCard: View {
    @ObservedObject var viewModel: ActivityViewModel

    private var avgSteps: Int {
        guard !viewModel.activityData.isEmpty else { return 0 }
        let total = viewModel.activityData.reduce(0) { $0 + $1.steps }
        return total / viewModel.activityData.count
    }

    private var goalPercent: Int { Int(viewModel.progress * 100) }

    // Green ≥ 8k, orange 4–8k, red < 4k
    private var activityColor: Color {
        if avgSteps >= 8000 { return Color(red: 0.08, green: 0.72, blue: 0.50) }
        if avgSteps >= 4000 { return .orange }
        return .red
    }

    private var conditionLabel: String {
        if avgSteps >= 8000 { return "Active" }
        if avgSteps >= 4000 { return "Moderate" }
        return "Low" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Summary")
                    .font(.headline)
                    .foregroundColor(.hmText)
                Spacer()
                if avgSteps > 0 {
                    Text(conditionLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(activityColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(activityColor.opacity(0.12))
                        .cornerRadius(10)
                }
            }
            Text("\(avgSteps) avg steps/day")
                .font(.subheadline)
                .foregroundColor(.gray)
            ProgressBar(progress: viewModel.progress, color: activityColor)
                .frame(height: 12)
            Text("\(goalPercent)% of weekly goal")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .cardStyle()
    }
}

// MARK: - Steps Chart

struct StepsChartCard: View {
    @ObservedObject var viewModel: ActivityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps")
                .font(.headline)
                .foregroundColor(.hmText)
            stepsChartContent
        }
        .cardStyle()
    }

    @ViewBuilder
    private var stepsChartContent: some View {
        if viewModel.activityData.isEmpty {
            EmptyChartPlaceholder(icon: "chart.xyaxis.line", text: "No data for this week")
        } else {
            StepsLineChart(data: viewModel.activityData)
        }
    }
}

struct StepsLineChart: View {
    let data: [ActivitySession]

    var body: some View {
        Chart(data) { item in
            LineMark(
                x: .value("Day", dayLabel(from: item.logDate)),
                y: .value("Steps", item.steps)
            )
            .foregroundStyle(Color.hmMint)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .symbol(Circle())
            .symbolSize(40)
        }
        .frame(height: 220)
        .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Color.gray) } }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel().foregroundStyle(Color.gray)
            }
        }
    }

    private func dayLabel(from dateString: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let d = fmt.date(from: dateString) else { return dateString }
        fmt.dateFormat = "EEE"
        return fmt.string(from: d)
    }
}

// MARK: - Activity Minutes Chart

struct ActivityMinutesChartCard: View {
    @ObservedObject var viewModel: ActivityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calories Burned")
                .font(.headline)
                .foregroundColor(.hmText)
            minutesChartContent
        }
        .cardStyle()
    }

    @ViewBuilder
    private var minutesChartContent: some View {
        if viewModel.activityData.isEmpty {
            EmptyChartPlaceholder(icon: "chart.bar.fill", text: "No data for this week")
        } else {
            ActivityMinutesBarChart(data: viewModel.activityData)
        }
    }
}

struct ActivityMinutesBarChart: View {
    let data: [ActivitySession]

    private let barColor = Color(red: 0.08, green: 0.72, blue: 0.65)

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Day", dayLabel(from: item.logDate)),
                y: .value("Calories", item.caloriesBurned ?? 0)
            )
            .foregroundStyle(barColor)
            .cornerRadius(4)
        }
        .frame(height: 220)
        .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Color.gray) } }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel().foregroundStyle(Color.gray)
            }
        }
    }

    private func dayLabel(from dateString: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let d = fmt.date(from: dateString) else { return dateString }
        fmt.dateFormat = "EEE"
        return fmt.string(from: d)
    }
}

// MARK: - Activity History

struct ActivityHistoryCard: View {
    @ObservedObject var viewModel: ActivityViewModel

    private var sortedData: [ActivitySession] {
        viewModel.activityData.sorted { $0.logDate > $1.logDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(.headline)
                    .foregroundColor(.hmText)
                Spacer()
                Text("\(sortedData.count) entries")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if sortedData.isEmpty {
                EmptyChartPlaceholder(icon: "clock.arrow.circlepath", text: "No activity logged yet")
                    .frame(height: 120)
            } else {
                ForEach(sortedData) { session in
                    ActivityHistoryRow(session: session)
                    if session.id != sortedData.last?.id {
                        Divider().padding(.vertical, 2)
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct ActivityHistoryRow: View {
    let session: ActivitySession

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let d = fmt.date(from: session.logDate) else { return session.logDate }
        fmt.dateFormat = "MMM d, yyyy"
        return fmt.string(from: d)
    }

    // Green ≥ 8k, orange 4–8k, red < 4k
    private var rowColor: Color {
        if session.steps >= 8000 { return Color(red: 0.08, green: 0.72, blue: 0.50) }
        if session.steps >= 4000 { return .orange }
        return .red
    }

    private var conditionLabel: String {
        if session.steps >= 8000 { return "Active" }
        if session.steps >= 4000 { return "Moderate" }
        return "Low"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(rowColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "figure.walk")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(rowColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formattedDate)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.hmText)
                    Spacer()
                    Text(conditionLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(rowColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(rowColor.opacity(0.12))
                        .cornerRadius(6)
                }

                HStack(spacing: 12) {
                    statChip(icon: "shoeprints.fill", value: "\(session.steps)", color: rowColor)

                    if let cal = session.caloriesBurned, cal > 0 {
                        statChip(icon: "flame.fill", value: "\(cal) kcal", color: .orange)
                    }

                    if let mins = session.activeMinutes, mins > 0 {
                        statChip(icon: "timer", value: "\(mins) min", color: .hmPrimary)
                    }

                    if let dist = session.distanceMeters, dist > 0 {
                        statChip(icon: "map.fill",
                                 value: String(format: "%.2f km", dist / 1000.0),
                                 color: .purple)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statChip(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.hmText)
        }
    }
}

// MARK: - Insights Card

struct InsightsCard: View {
    @ObservedObject var recViewModel: RecommendationsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            insightsHeader
            insightsContent
        }
        .cardStyle()
    }

    private var insightsHeader: some View {
        HStack {
            Text("Insights")
                .font(.headline)
                .foregroundColor(.hmText)
            Spacer()
            Button(action: { Task { await recViewModel.generateInsights() } }) {
                generateButtonLabel
            }
            .disabled(recViewModel.isLoading)
        }
    }

    @ViewBuilder
    private var generateButtonLabel: some View {
        if recViewModel.isLoading {
            ProgressView()
        } else {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text("Generate")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.hmPrimary)
        }
    }

    @ViewBuilder
    private var insightsContent: some View {
        if recViewModel.recommendations.isEmpty {
            Text("No insights yet. Tap Generate to get personalized health tips.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 8)
        } else {
            ForEach(recViewModel.recommendations) { rec in
                RecommendationCard(recommendation: rec)
                if rec.id != recViewModel.recommendations.last?.id {
                    Divider().padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Shared Helpers

struct EmptyChartPlaceholder: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            Text(text)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }
}

// MARK: - View Modifier

extension View {
    func cardStyle() -> some View {
        self
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
    }
}
