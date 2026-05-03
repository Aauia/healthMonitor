import SwiftUI
import Charts

// MARK: - Main Sleep View

struct SleepView: View {
    @StateObject private var viewModel = SleepViewModel()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.hmBackground.edgesIgnoringSafeArea(.all)

                if viewModel.isLoading {
                    ProgressView("Loading sleep data…").tint(.hmPrimary)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            SleepSummaryCard(viewModel: viewModel)
                            SleepChartCard(viewModel: viewModel)
                            SleepHistoryCard(viewModel: viewModel)
                            Spacer(minLength: 40)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Sleep")
            .navigationBarItems(trailing:
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus").foregroundColor(.hmPrimary)
                }
            )
            .sheet(isPresented: $showingAddSheet) {
                AddSleepView(viewModel: viewModel)
            }
            .task { await viewModel.fetchSleepHistory() }
            .refreshable { await viewModel.fetchSleepHistory() }
            .alert("Error",
                   isPresented: Binding(
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

// MARK: - Summary Card

struct SleepSummaryCard: View {
    @ObservedObject var viewModel: SleepViewModel

    private var duration: Double { viewModel.lastNightDuration }

    /// green ≥ 7h, orange 5–7h, red < 5h
    private var sleepColor: Color {
        if duration >= 7.0 { return Color(red: 0.08, green: 0.72, blue: 0.50) }
        if duration >= 5.0 { return .orange }
        return .red
    }

    private var conditionLabel: String {
        if duration >= 7.0 { return "Good" }
        if duration >= 5.0 { return "Fair" }
        return "Poor"
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Last Night's Sleep")
                        .font(.headline)
                        .foregroundColor(.hmText)
                    Spacer()
                    // Condition badge
                    if !viewModel.sleepData.isEmpty {
                        Text(conditionLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(sleepColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(sleepColor.opacity(0.12))
                            .cornerRadius(10)
                    }
                }

                if viewModel.sleepData.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "moon.zzz")
                                .font(.system(size: 36))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No sleep data yet")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    HStack(alignment: .bottom, spacing: 16) {
                        // Big duration number
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", duration))
                                    .font(.system(size: 52, weight: .bold))
                                    .foregroundColor(.hmText)
                                Text("hrs")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            Text("Goal: \(String(format: "%.1f", viewModel.sleepGoalHours)) hrs")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        // Progress ring coloured by condition
                        ProgressRing(
                            progress: min(duration / viewModel.sleepGoalHours, 1.0),
                            color: sleepColor,
                            lineWidth: 14
                        )
                        .frame(width: 90, height: 90)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        // Coloured left-side border strip
        .overlay(
            Rectangle()
                .fill(viewModel.sleepData.isEmpty ? Color.clear : sleepColor)
                .frame(width: 4)
                .cornerRadius(2)
                .padding(.horizontal, 16)
                .padding(.vertical, 4),
            alignment: .leading
        )
    }
}

// MARK: - Sleep Duration Bar Chart

struct SleepChartCard: View {
    @ObservedObject var viewModel: SleepViewModel

    private var chartData: [SleepSession] {
        Array(viewModel.sleepData.prefix(7).reversed())
    }

    private func barColor(for session: SleepSession) -> Color {
        let h = Double(session.durationMin) / 60.0
        if h >= 7.0 { return Color(red: 0.08, green: 0.72, blue: 0.50) }
        if h >= 5.0 { return .orange }
        return .red
    }

    private func dayLabel(from dateString: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let d = fmt.date(from: dateString) else { return dateString }
        fmt.dateFormat = "EEE"
        return fmt.string(from: d)
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sleep Duration — 7 Days")
                        .font(.headline)
                        .foregroundColor(.hmText)
                    Spacer()
                    // Legend
                    HStack(spacing: 8) {
                        legendDot(.red,    "< 5h")
                        legendDot(.orange, "5–7h")
                        legendDot(Color(red: 0.08, green: 0.72, blue: 0.50), "7h+")
                    }
                }

                if chartData.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 36))
                                .foregroundColor(.gray.opacity(0.4))
                            Text("No history yet")
                                .foregroundColor(.gray)
                        }
                        .frame(height: 180)
                        Spacer()
                    }
                } else {
                    Chart(chartData) { session in
                        BarMark(
                            x: .value("Day", dayLabel(from: session.sleepDate)),
                            y: .value("Hours", Double(session.durationMin) / 60.0)
                        )
                        .foregroundStyle(barColor(for: session))
                        .cornerRadius(6)

                        // Goal reference line at 7h
                        RuleMark(y: .value("Goal", 7.0))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                            .foregroundStyle(Color.gray.opacity(0.5))
                            .annotation(position: .trailing) {
                                Text("Goal")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(values: [0, 2, 4, 6, 8]) { v in
                            AxisGridLine().foregroundStyle(Color.gray.opacity(0.15))
                            AxisValueLabel {
                                if let h = v.as(Double.self) {
                                    Text("\(Int(h))h")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in AxisValueLabel().foregroundStyle(Color.gray) }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundColor(.gray)
        }
    }
}

// MARK: - Sleep History List

struct SleepHistoryCard: View {
    @ObservedObject var viewModel: SleepViewModel

    private func sleepColor(durationMin: Int) -> Color {
        let h = Double(durationMin) / 60.0
        if h >= 7.0 { return Color(red: 0.08, green: 0.72, blue: 0.50) }
        if h >= 5.0 { return .orange }
        return .red
    }

    private func conditionLabel(durationMin: Int) -> String {
        let h = Double(durationMin) / 60.0
        if h >= 7.0 { return "Good" }
        if h >= 5.0 { return "Fair" }
        return "Poor"
    }

    private func formattedDate(_ raw: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let d = fmt.date(from: raw) else { return raw }
        fmt.dateFormat = "MMM d, yyyy"
        return fmt.string(from: d)
    }

    var body: some View {
        if viewModel.sleepData.isEmpty { EmptyView() } else {
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("History")
                            .font(.headline)
                            .foregroundColor(.hmText)
                        Spacer()
                        Text("\(viewModel.sleepData.count) entries")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    ForEach(viewModel.sleepData.prefix(14).reversed()) { session in
                        SleepHistoryRow(
                            session: session,
                            color: sleepColor(durationMin: session.durationMin),
                            condition: conditionLabel(durationMin: session.durationMin),
                            formattedDate: formattedDate(session.sleepDate)
                        )
                        if session.id != viewModel.sleepData.reversed().first?.id {
                            Divider().padding(.vertical, 2)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SleepHistoryRow: View {
    let session: SleepSession
    let color: Color
    let condition: String
    let formattedDate: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "moon.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(formattedDate)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.hmText)
                Text("\(session.bedtime) – \(session.wakeTime)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.1f hrs", Double(session.durationMin) / 60.0))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.hmText)
                Text(condition)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.12))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}
