import SwiftUI

// MARK: - Streak Card View

struct StreakCardView: View {
    let currentStreak: Int
    let longestStreak: Int
    let weeklyProgress: Int
    let weeklyGoal: Int
    let motivationalMessage: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with motivational message
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(motivationalMessage)
                        .font(.headline)
                        .lineLimit(2)
                }
                Spacer()
                if currentStreak >= 3 {
                    Text("🔥")
                        .font(.title2)
                }
            }
            
            // Streak stats
            HStack(spacing: 16) {
                // Current streak
                VStack(spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.title2.bold())
                        .foregroundStyle(currentStreak >= 7 ? .orange : .primary)
                    Text("Current Streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                // Longest streak
                VStack(spacing: 4) {
                    Text("\(longestStreak)")
                        .font(.title2.bold())
                        .foregroundStyle(.purple)
                    Text("Best Streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                // Weekly progress
                VStack(spacing: 4) {
                    Text("\(weeklyProgress)/\(weeklyGoal)")
                        .font(.title2.bold())
                        .foregroundStyle(weeklyProgress >= weeklyGoal ? .green : .primary)
                    Text("This Week")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Weekly progress bar
            if weeklyGoal > 0 {
                ProgressView(value: Double(weeklyProgress), total: Double(weeklyGoal))
                    .progressViewStyle(.linear)
                    .tint(weeklyProgress >= weeklyGoal ? .green : .blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StreakCardView(
            currentStreak: 7,
            longestStreak: 30,
            weeklyProgress: 3,
            weeklyGoal: 4,
            motivationalMessage: "⭐ 7 day streak! You're building great habits!"
        )
        
        StreakCardView(
            currentStreak: 0,
            longestStreak: 14,
            weeklyProgress: 0,
            weeklyGoal: 4,
            motivationalMessage: "🏋️ Ready to crush your workout today?"
        )
    }
    .padding()
}