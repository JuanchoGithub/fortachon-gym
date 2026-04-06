import SwiftUI
import FortachonCore

// MARK: - Promotion Review Modal

/// A modal for reviewing exercise promotions (when user is ready to level up
/// from a basic to advanced variation).
struct PromotionReviewModal: View {
    @Environment(\.dismiss) private var dismiss
    
    let currentExerciseName: String
    let advancedExerciseName: String
    let criteriaMet: [String]
    let difficultyDelta: String
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Challenge icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)
                    .symbolEffect(.breathe, value: isAnimating)
                
                // Title
                Text("Ready for a Challenge?")
                    .font(.title2.bold())
                
                // Exercise comparison
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Current exercise
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(currentExerciseName)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Text("Mastered")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        // Advanced exercise
                        VStack(spacing: 4) {
                            Image(systemName: "star.circle.fill")
                                .foregroundStyle(.orange)
                            Text(advancedExerciseName)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Text(difficultyDelta)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                
                // Criteria met
                if !criteriaMet.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Criteria Met")
                            .font(.subheadline.bold())
                        
                        ForEach(criteriaMet, id: \.self) { criterion in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(criterion)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onAccept()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Try It!")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    
                    Button(action: {
                        onDecline()
                        dismiss()
                    }) {
                        Text("Not Yet")
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
            .presentationDetents([.fraction(0.6)])
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
    PromotionReviewModal(
        currentExerciseName: "Push-ups",
        advancedExerciseName: "Archer Push-ups",
        criteriaMet: [
            "3 × 12 reps for 3 consecutive workouts",
            "RPE consistently below 7",
            "Perfect form maintained"
        ],
        difficultyDelta: "+20% harder",
        onAccept: {},
        onDecline: {}
    )
}