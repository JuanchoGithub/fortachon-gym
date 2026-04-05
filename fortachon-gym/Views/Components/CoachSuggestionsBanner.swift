import SwiftUI

/// A yellow-orange color commonly used for suggestions/warnings.
private let suggestionColor: Color = Color(red: 1.0, green: 0.75, blue: 0.0)

/// A card showing a single exercise upgrade suggestion from the smart coach.
struct SmartCoachSuggestionCard: View {
    let suggestion: UpgradeSuggestion
    let onUpgrade: (UpgradeSuggestion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and title
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(suggestionColor)
                Text("Upgrade")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Exercise names
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.currentExerciseName)
                    .font(.headline)
                    .lineLimit(1)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(suggestion.targetExerciseName)
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            }
            
            // Reason
            Text(suggestion.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // Upgrade button
            Button(action: { onUpgrade(suggestion) }) {
                Text("Upgrade")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background(suggestionColor)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(suggestionColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// A horizontal scrollable banner showing multiple coach suggestions at the bottom of the workout.
struct CoachSuggestionsBanner: View {
    let suggestions: [UpgradeSuggestion]
    let onUpgrade: (UpgradeSuggestion) -> Void
    
    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundStyle(.orange)
                    Text("Coach Suggestions")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(suggestions) { suggestion in
                            SmartCoachSuggestionCard(
                                suggestion: suggestion,
                                onUpgrade: onUpgrade
                            )
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(suggestionColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(suggestionColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}
