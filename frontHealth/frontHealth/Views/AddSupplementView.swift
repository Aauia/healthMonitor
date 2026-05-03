import SwiftUI

struct AddSupplementView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SupplementsViewModel
    
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var instructions: String = ""
    @State private var type: String = "Vitamin"
    @State private var reminderTimes: [Date] = [Date()]
    @State private var startDate: Date = Date()
    @State private var hasEndDate = false
    @State private var endDate: Date = Date()
    @State private var selectedDays: Set<String> = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    let types = ["vitamin", "mineral", "supplement", "medication", "herb"]
    
    // Map backend enums exactly. If UI wants more, map them to "supplement"
    let allowedTypes = ["vitamin", "medication", "supplement"]
    
    let daysEnum = [("Mon", 1), ("Tue", 2), ("Wed", 3), ("Thu", 4), ("Fri", 5), ("Sat", 6), ("Sun", 7)]
    
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Supplement Details")) {
                    TextField("Name (e.g. Vitamin C)", text: $name)
                    TextField("Dosage (e.g. 500mg)", text: $dosage)
                    Picker("Type", selection: $type) {
                        ForEach(["vitamin", "medication", "supplement"], id: \.self) { t in
                            Text(t.capitalized).tag(t)
                        }
                    }
                    TextField("Instructions (e.g. Take with food)", text: $instructions)
                }
                
                Section(header: Text("Schedule Reminders")) {
                    ForEach(0..<reminderTimes.count, id: \.self) { index in
                        HStack {
                            DatePicker("Time \(index + 1)", selection: $reminderTimes[index], displayedComponents: .hourAndMinute)
                            
                            if reminderTimes.count > 1 {
                                Button(action: {
                                    reminderTimes.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    Button(action: {
                        reminderTimes.append(Date())
                    }) {
                        Label("Add Another Time", systemImage: "plus.circle.fill")
                            .foregroundColor(.hmPrimary)
                    }
                }
                
                Section(header: Text("Duration")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Toggle("Set End Date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Days of Week")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(daysEnum, id: \.0) { dayTuple in
                            let dayName = dayTuple.0
                            Button(action: {
                                if selectedDays.contains(dayName) {
                                    selectedDays.remove(dayName)
                                } else {
                                    selectedDays.insert(dayName)
                                }
                            }) {
                                Text(dayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selectedDays.contains(dayName) ? Color.hmPrimary : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedDays.contains(dayName) ? .white : .gray)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Supplement")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button(action: {
                    let timeStrs = reminderTimes.map { timeFormatter.string(from: $0) }
                    let firstTime = timeStrs.first ?? timeFormatter.string(from: Date())
                    let dayInts = daysEnum.filter { selectedDays.contains($0.0) }.map { $0.1 }
                    let fallbackEndDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
                    let finalEndDate = hasEndDate ? endDate : fallbackEndDate
                    
                    let request = SupplementRequest(
                        name: name,
                        type: allowedTypes.contains(type.lowercased()) ? type.lowercased() : "supplement",
                        dosage: dosage.isEmpty ? nil : dosage,
                        reminderTime: firstTime,
                        instructions: instructions.isEmpty ? nil : instructions,
                        reminderTimes: timeStrs,
                        daysOfWeek: dayInts,
                        startDate: dateFormatter.string(from: startDate),
                        endDate: dateFormatter.string(from: finalEndDate)
                    )
                    
                    Task {
                        let success = await viewModel.addSupplement(request: request)
                        if success { dismiss() }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save")
                            .font(.headline)
                    }
                }
                .disabled(name.isEmpty || selectedDays.isEmpty || viewModel.isLoading)
            )
        }
    }
}
