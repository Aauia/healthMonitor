import SwiftUI

struct SyncActivityView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ActivityViewModel
    
    @State private var activityDate = Date()
    @State private var steps: String = ""
    @State private var activeMinutes: String = ""
    @State private var caloriesBurned: String = ""
    @State private var distanceMeters: String = ""
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Details")) {
                    DatePicker("Date", selection: $activityDate, displayedComponents: .date)
                    TextField("Steps", text: $steps)
                        .keyboardType(.numberPad)
                    TextField("Active minutes (optional)", text: $activeMinutes)
                        .keyboardType(.numberPad)
                    TextField("Calories burned (optional)", text: $caloriesBurned)
                        .keyboardType(.numberPad)
                    TextField("Distance in meters (optional)", text: $distanceMeters)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Log Activity")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button(action: {
                    guard let stepCount = Int(steps) else { return }
                    Task {
                        let entry = ActivityLogEntry(
                            logDate:        dateFormatter.string(from: activityDate),
                            steps:          stepCount,
                            activeMinutes:  Int(activeMinutes),
                            caloriesBurned: Int(caloriesBurned),
                            distanceMeters: Double(distanceMeters)
                        )
                        let request = ActivitySyncRequest(logs: [entry])
                        let success = await viewModel.syncActivity(session: request)
                        if success { dismiss() }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(steps.isEmpty || viewModel.isLoading)
            )
        }
    }
}
