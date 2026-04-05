import SwiftUI
import FortachonCore

struct RecommendationBannerView: View {
    let recommendation: Recommendation
    let onRoutineSelect: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private var gradient: LinearGradient {
        switch recommendation.type {
        case .workout:
            return LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rest, .activeRecovery:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .deload:
            return LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .promotion:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .imbalance:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var icon: String {
        switch recommendation.type {
        case .workout: return "figure.strengthtraining.traditional"
        case .rest: return "moon.stars.fill"
        case .activeRecovery: return "sparkles"
        case .deload: return "exclamationmark.triangle.fill"
        case .promotion: return "trophy.fill"
        case .imbalance: return "scalemass.fill"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Text(recommendation.reason)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)
                if !recommendation.relevantRoutineIds.isEmpty {
                    ForEach(Array(recommendation.relevantRoutineIds.prefix(2)), id: \.self) { _ in
                        Button(action: onRoutineSelect) {
                            HStack {
                                Text("Start")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .padding(8)
                            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(16)
        .background(gradient, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
}