import SwiftUI
import FortachonCore

// MARK: - Auto Update 1RM Modal

/// A modal for confirming auto-updates to estimated 1RM.
/// Presented as a slide-up sheet when a new personal record is detected.
struct AutoUpdate1RMModal: View {
    @Environment(\.dismiss) private var dismiss
    
    let exerciseName: String
    let old1RM: Double
    let new1RM: Double
    let weight: Double
    let reps: Int
    let unit: String
    let onAccept: () -> Void
    let onIgnore: () -> Void
    let cascadeRatios: [String: Double]? = nil // Optional: exerciseId -> new ratio
    
    @State private var isAnimating = false
    @State private var showDownstreamEffects = false
    
    private var improvement: Double { new1RM - old1RM }
    
    private var improvementPercentage: Double {
        guard old1RM > 0 else { return 0 }
        return (improvement / old1RM) * 100
    }
    
    // Calculate weight suggestions based on new 1RM
    private var weightSuggestions: [(percentage: Int, label: String, weight: Double)] {
        [
            (90, "90% (Heavy)", new1RM * 0.9),
            (80, "80% (Moderate)", new1RM * 0.8),
            (70, "70% (Volume)", new1RM * 0.7),
            (60, "60% (Light)", new1RM * 0.6)
        ]
    }
        
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Celebration icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.bounce, value: isAnimating)
                
                // Title
                Text("New 1RM Detected!")
                    .font(.title2.bold())
                
                // Exercise name
                Text(exerciseName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                // 1RM comparison
                HStack(spacing: 24) {
                    // Old 1RM
                    VStack(spacing: 4) {
                        Text("Previous")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(old1RM > 0 ? String(format: "%.1f", old1RM) : "N/A")
                            .font(.title.bold())
                        if old1RM > 0 {
                            Text(unit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    // New 1RM
                    VStack(spacing: 4) {
                        Text("New")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(String(format: "%.1f", new1RM))
                            .font(.title.bold())
                            .foregroundStyle(.green)
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                }
                
                // Explanation
                VStack(spacing: 4) {
                    Text("Based on your set of **\(reps) reps** at **\(String(format: "%.1f", weight)) \(unit)**")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if improvementPercentage > 0 {
                        Text("That's a **+\(String(format: "%.1f", improvementPercentage))%** improvement!")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
                
                    
                    // Downstream effects expandable section
                    DisclosureGroup(
                        isExpanded: $showDownstreamEffects,
                        content: {
                            VStack(spacing: 8) {
                                // Weight suggestions
                                Text("Training Weights with New 1RM")
                                    .font(.subheadline.bold())
                                
                                ForEach(weightSuggestions, id: \.percentage) { suggestion in
                                    HStack {
                                        Text(suggestion.label)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(String(format: "%.1f", suggestion.weight))
                                            .font(.subheadline.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        },
                        label: {
                            Text("View Training Weights")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    )
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                        onAccept()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Update 1RM")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    
                    Button(action: {
                        onIgnore()
                        dismiss()
                    }) {
                        Text("Keep Current")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .presentationDetents([.fraction(0.55)])
            .presentationCornerRadius(20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AutoUpdate1RMModal(
        exerciseName: "Bench Press",
        old1RM: 100,
        new1RM: 107.5,
        weight: 90,
        reps: 5,
        unit: "KG",
        onAccept: {},
        onIgnore: {}
    )
}