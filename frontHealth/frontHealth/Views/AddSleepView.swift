import SwiftUI

struct AddSleepView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SleepViewModel
    
    @State private var sleepDate = Date()
    @State private var bedtime = Date()
    @State private var wakeTime = Date()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    var durationMin: Int {
        let diff = Calendar.current.dateComponents([.minute], from: bedtime, to: wakeTime)
        let mins = diff.minute ?? 0
        return mins < 0 ? mins + 24 * 60 : mins
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sleep Details")) {
                    DatePicker("Sleep Date", selection: $sleepDate, displayedComponents: .date)
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                    DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                }
                
                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(String(format: "%.1f hrs", Double(durationMin) / 60.0))
                            .foregroundColor(.hmPrimary)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button(action: {
                    Task {
                        let request = SleepSessionRequest(
                            sleepDate: dateFormatter.string(from: sleepDate),
                            bedtime: timeFormatter.string(from: bedtime),
                            wakeTime: timeFormatter.string(from: wakeTime),
                            durationMin: durationMin
                        )
                        let success = await viewModel.addSleepSession(session: request)
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
                .disabled(viewModel.isLoading)
            )
        }
    }
}
