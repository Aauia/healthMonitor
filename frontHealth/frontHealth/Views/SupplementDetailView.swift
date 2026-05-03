import SwiftUI

struct SupplementDetailView: View {
    let supplement: Supplement
    let emerald500 = Color(red: 16/255, green: 185/255, blue: 129/255)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(colorFor(name: supplement.name).opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "pill.fill")
                        .foregroundColor(colorFor(name: supplement.name))
                        .font(.system(size: 40))
                        .rotationEffect(.degrees(45))
                }
                .padding(.top, 24)
                
                VStack(spacing: 8) {
                    Text(supplement.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text((supplement.type ?? "Supplement").capitalized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 16) {
                    detailRow(title: "Dosage", value: supplement.dosage ?? "Not specified")
                    detailRow(title: "Schedule", value: formatTimes())
                    detailRow(title: "Days", value: formatDays())
                    detailRow(title: "Duration", value: "\(supplement.startDate ?? "") to \(supplement.endDate ?? "")")
                    
                    if let progress = supplement.progressPercent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Progress")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            HStack {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(UIColor.systemGray6))
                                            .frame(height: 10)
                                        
                                        Capsule()
                                            .fill(emerald500)
                                            .frame(width: max(0, geometry.size.width * CGFloat(progress / 100.0)), height: 10)
                                    }
                                }
                                .frame(height: 10)
                                
                                Text("\(Int(progress))%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                if let instructions = supplement.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(instructions)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Supplement Info")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGray6).opacity(0.3).edgesIgnoringSafeArea(.all))
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
    }
    
    private func formatTimes() -> String {
        let timesString = supplement.reminderTimes ?? supplement.reminderTime ?? ""
        if timesString.hasPrefix("[") {
            if let data = timesString.data(using: .utf8),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                return array.joined(separator: ", ")
            }
        } else if !timesString.isEmpty {
            let times = timesString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return times.joined(separator: ", ")
        }
        return "Anytime"
    }
    
    private func formatDays() -> String {
        let daysString = supplement.daysOfWeek ?? ""
        if daysString.hasPrefix("[") {
            if let data = daysString.data(using: .utf8),
               let array = try? JSONDecoder().decode([Int].self, from: data) {
                let dayNames = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                return array.map { dayNames[$0] }.joined(separator: ", ")
            }
        } else if !daysString.isEmpty {
            let dayNames = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let dayInts = daysString.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            return dayInts.map { dayNames[$0] }.joined(separator: ", ")
        }
        return "Every day"
    }
    
    private func colorFor(name: String) -> Color {
        let colors: [Color] = [
            Color(red: 59/255, green: 130/255, blue: 246/255), // Blue
            Color(red: 16/255, green: 185/255, blue: 129/255), // Emerald
            Color(red: 245/255, green: 158/255, blue: 11/255), // Amber
            Color(red: 236/255, green: 72/255, blue: 153/255), // Pink
            Color(red: 139/255, green: 92/255, blue: 246/255)  // Purple
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}
