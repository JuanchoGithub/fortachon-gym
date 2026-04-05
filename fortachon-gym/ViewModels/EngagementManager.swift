import Foundation
import SwiftData
import FortachonCore
import Observation

/// Manages user engagement features: check-ins, streaks, motivational messages.
@Observable
@MainActor
final class EngagementManager {
    
    // MARK: - State
    
    var shouldShowCheckIn: Bool = false
    var streakResult: StreakCalculator.StreakResult?
    var motivationalMessage: String = ""
    var weeklyGoal: Int = 4
    var weeklyProgress: Int = 0
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let streakCalculator = StreakCalculator()
    private let inactiveThresholdDays = 10
    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Check-in
    
    /// Check if the user should see a check-in prompt (10+ days inactive).
    func checkLastActivity(sessions: [WorkoutSessionM], preferences: UserPreferencesM?) {
        guard let lastSession = sessions.sorted(by: { $0.startTime > $1.startTime }).first else {
            // No sessions yet, don't show check-in for new users
            shouldShowCheckIn = false
            return
        }
        
        let daysSinceLastWorkout = Calendar.current.dateComponents(
            [.day],
            from: lastSession.startTime,
            to: Date()
        ).day ?? 0
        
        shouldShowCheckIn = daysSinceLastWorkout >= inactiveThresholdDays
    }
    
    /// Submit a check-in response.
    func submitCheckIn(reason: CheckInReason, preferences: UserPreferencesM?) {
        preferences?.lastCheckInDate = Date()
        preferences?.lastCheckInReason = reason.rawValue
        shouldShowCheckIn = false
    }
    
    /// Snooze the check-in for tomorrow.
    func snoozeCheckIn(preferences: UserPreferencesM?) {
        // Just dismiss for now, will show again next time app opens
        shouldShowCheckIn = false
    }
    
    // MARK: - Streaks
    
    /// Calculate and update streak data.
    func updateStreaks(sessions: [WorkoutSessionM]) {
        let dates = sessions.map { $0.startTime }
        streakResult = streakCalculator.calculate(from: dates)
    }
    
    // MARK: - Weekly Progress
    
    /// Calculate weekly training progress.
    func updateWeeklyProgress(sessions: [WorkoutSessionM], goal: Int = 4) {
        weeklyGoal = goal
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        
        let thisWeekSessions = sessions.filter { $0.startTime >= startOfWeek }
        // Count unique training days
        let uniqueDays = Set(thisWeekSessions.map { calendar.startOfDay(for: $0.startTime) })
        weeklyProgress = min(uniqueDays.count, goal)
    }
    
    // MARK: - Motivational Messages
    
    /// Get a context-aware motivational message.
    func getMotivationalMessage(streak: Int, weeklyProgress: Int, weeklyGoal: Int) -> String {
        if streak >= 30 {
            return "🔥 \(streak) day streak! You're unstoppable!"
        } else if streak >= 14 {
            return "💪 \(streak) days strong! Keep the momentum going!"
        } else if streak >= 7 {
            return "⭐ \(streak) day streak! You're building great habits!"
        } else if streak >= 3 {
            return "🎯 \(streak) days in a row! Nice work!"
        } else if weeklyProgress >= weeklyGoal {
            return "✅ Weekly goal complete! You nailed it this week!"
        } else if weeklyProgress > 0 {
            let remaining = weeklyGoal - weeklyProgress
            return "📈 \(weeklyProgress)/\(weeklyGoal) this week. \(remaining) more to hit your goal!"
        } else {
            return "🏋️ Ready to crush your workout today?"
        }
    }
}