import Foundation

struct DailySupplementItem: Identifiable {
    var id: String { "\(supplement.id ?? 0)_\(plannedTime)" }
    var supplement: Supplement
    var plannedTime: String
    var isTaken: Bool {
        supplement.takenTimesToday?.contains(plannedTime) ?? false
    }
}

@MainActor
class SupplementsViewModel: ObservableObject {
    @Published var supplements: [Supplement] = []
    @Published var groupedSupplements: [(String, [DailySupplementItem])] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchSupplements() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await APIService.shared.request(endpoint: "/supplements/my", responseType: [Supplement].self)
            self.supplements = data
            self.groupSupplementsByTime()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func addSupplement(request: SupplementRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            let body = try JSONEncoder().encode(request)
            _ = try await APIService.shared.request(endpoint: "/supplements", method: "POST", body: body, responseType: Supplement.self)
            await fetchSupplements()
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    


    func logSupplement(id: Int, time: String, taken: Bool) async {
        // Optimistic Update
        if let idx = supplements.firstIndex(where: { $0.id == id }) {
            if taken {
                if supplements[idx].takenTimesToday != nil {
                    if !supplements[idx].takenTimesToday!.contains(time) {
                        supplements[idx].takenTimesToday!.append(time)
                    }
                } else {
                    supplements[idx].takenTimesToday = [time]
                }
            } else {
                supplements[idx].takenTimesToday?.removeAll { $0 == time }
            }
            groupSupplementsByTime()
        }
        
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayStr = formatter.string(from: Date())
            
            let request = SupplementLogRequest(logDate: todayStr, plannedTime: time, taken: taken)
            let body = try JSONEncoder().encode(request)
            
            _ = try await APIService.shared.request(endpoint: "/supplements/\(id)/log", method: "POST", body: body, responseType: StatusResponse.self)
            await fetchSupplements()
        } catch {
            self.errorMessage = error.localizedDescription
            // If it fails, refetch to revert optimistic update
            await fetchSupplements()
        }
    }
    
    func deleteSupplement(id: Int) async {
        if let index = supplements.firstIndex(where: { $0.id == id }) {
            supplements.remove(at: index)
            groupSupplementsByTime()
        }
        
        do {
            _ = try await APIService.shared.request(endpoint: "/supplements/\(id)", method: "DELETE", responseType: StatusResponse.self)
            await fetchSupplements()
        } catch {
            self.errorMessage = error.localizedDescription
            await fetchSupplements()
        }
    }
    
    private func groupSupplementsByTime() {
        var itemsByTime: [String: [DailySupplementItem]] = [:]
        
        for supplement in supplements {
            let timesString = supplement.reminderTimes ?? supplement.reminderTime ?? ""
            var times: [String] = []
            
            if timesString.hasPrefix("[") {
                if let data = timesString.data(using: .utf8),
                   let array = try? JSONDecoder().decode([String].self, from: data) {
                    times = array
                }
            } else {
                times = timesString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            }
            
            if times.isEmpty {
                let item = DailySupplementItem(supplement: supplement, plannedTime: "Anytime")
                itemsByTime["Anytime", default: []].append(item)
            } else {
                for time in times {
                    let item = DailySupplementItem(supplement: supplement, plannedTime: time)
                    itemsByTime[time, default: []].append(item)
                }
            }
        }
        
        let sortedKeys = itemsByTime.keys.sorted()
        self.groupedSupplements = sortedKeys.map { ($0, itemsByTime[$0]!) }
    }
}
