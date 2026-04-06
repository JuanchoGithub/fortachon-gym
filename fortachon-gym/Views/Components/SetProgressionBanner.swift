import SwiftUI
import FortachonCore

// MARK: - Set Progression Banner

/// A banner shown when progression triggers (auto weight increase based on rep PRs).
struct SetProgressionBanner: View {
    let results: [ProgressionResult]
    let onDismiss: () -> Void
    let onApplyWeightIncrease: ((ProgressionResult) -> Void)?
    
    @State private var isAnimating = false
    
    init(
        results: [ProgressionResult],
        onDismiss: @escaping () -> Void,
        onApplyWeightIncrease: ((ProgressionResult) -> Void)? = nil
    ) {
        self.results = results
        self.onDismiss = onDismiss
        self.onApplyWeightIncrease = onApplyWeightIncrease
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(results) { result in
                HStack(spacing: 12) {
                    // Celebration icon
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("New PR!")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("\(result.exerciseName): \(result.newMaxReps) reps (+\(result.newMaxReps - result.oldMaxReps))")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                        
                        if result.shouldIncreaseWeight {
                            Text("Consider increasing to \(String(format: "%.1f", result.suggestedNewWeight)) kg")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 4) {
                        if let onApply = onApplyWeightIncrease, result.shouldIncreaseWeight {
                            Button("Apply") {
                                onApply(result)
                                onDismiss()
                            }
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        }
                        
                        Button("Dismiss") {
                            onDismiss()
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [.green, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Single Result Variant

struct SingleProgressionBanner: View {
    let result: ProgressionResult
    let onDismiss: () -> Void
    let onApplyWeightIncrease: (() -> Void)?
    
    var body: some View {
        SetProgressionBanner(
            results: [result],
            onDismiss: onDismiss,
            onApplyWeightIncrease: onApplyWeightIncrease != nil ? { _ in onApplyWeightIncrease?() } : nil
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        SetProgressionBanner(
            results: [
                ProgressionResult(
                    exerciseId: "ex-1",
                    exerciseName: "Bench Press",
                    isRepPR: true,
                    oldMaxReps: 8,
                    newMaxReps: 10,
                    weight: 80,
                    shouldIncreaseWeight: true,
                    suggestedNewWeight: 82.5
                ),
                ProgressionResult(
                    exerciseId: "ex-2",
                    exerciseName: "Squat",
                    isRepPR: true,
                    oldMaxReps: 6,
                    newMaxReps: 8,
                    weight: 100,
                    shouldIncreaseWeight: true,
                    suggestedNewWeight: 105
                )
            ],
            onDismiss: {},
            onApplyWeightIncrease: { _ in }
        )
        Spacer()
    }
}