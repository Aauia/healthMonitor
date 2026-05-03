import SwiftUI

struct SupplementRow: View {
    var item: DailySupplementItem
    var onLog: (Bool) -> Void
    
    private func colorFor(name: String) -> Color {
        let colors: [Color] = [.orange, .blue, .green, .pink, .purple, .teal, .indigo, .red]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        Button(action: {
            onLog(!item.isTaken)
        }) {
            HStack(alignment: .center, spacing: 16) {
                // Left colored icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorFor(name: item.supplement.name))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "paperclip")
                        .foregroundColor(.black)
                        .font(.system(size: 24, weight: .medium))
                        .rotationEffect(.degrees(45))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(item.supplement.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Subtitle: Dosage and Time
                    Text("\(item.supplement.dosage)  •  \(item.plannedTime)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                    
                    // Progress Bar and Percentage
                    if let progress = item.supplement.progressPercent {
                        HStack(spacing: 12) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color(UIColor.systemGray6))
                                        .frame(height: 6)
                                    
                                    Capsule()
                                        .fill(colorFor(name: item.supplement.name))
                                        .frame(width: max(0, geometry.size.width * CGFloat(progress / 100.0)), height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            Text("\(Int(progress))%")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .contentShape(Rectangle()) // Makes the entire row tappable even on empty spaces
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
        .opacity(item.isTaken ? 0.6 : 1.0)
        .blur(radius: item.isTaken ? 0.5 : 0)
        .animation(.easeInOut, value: item.isTaken)
    }
}
