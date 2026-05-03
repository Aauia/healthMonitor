import SwiftUI

struct RecommendationCard: View {
    var recommendation: Recommendation
    
    private var iconForType: String {
        switch recommendation.category?.lowercased() {
        case "sleep": return "moon.zzz.fill"
        case "activity": return "figure.walk"
        case "supplement", "nutrition": return "pills.fill"
        case "hydration": return "drop.fill"
        default: return "lightbulb.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.hmPrimary.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconForType)
                    .foregroundColor(.hmPrimary)
                    .font(.system(size: 22))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let category = recommendation.category {
                    Text(category.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.hmPrimary)
                }
                Text(recommendation.message)
                    .font(.subheadline)
                    .foregroundColor(.hmText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}
