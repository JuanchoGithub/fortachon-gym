import Foundation
import FortachonCore

/// Dedicated streak calculator for training consistency tracking.
@MainActor
final class StreakCalculator {
    
    // MARK: - Results
    
    struct StreakResult {
        let currentStreak: Int
        let longestStreak: Int
        let weeklyConsistency: Double  // 0-100%
        let monthlyConsistency: Double // 0-100%
        let nextMilestone: Int
        let daysToMilestone: Int
    }
    
    // MARK: - Streak Milestones
    
    static let milestones = [7, 14, 30, 60, 90, 180, 365, 500, 1000]
    
    // MARK: - Calculate
    
    /// Calculate streak data from workout sessions.
    /// - Parameter sessions: Array of workout session start dates
    /// - Returns: StreakResult with all streak metrics
    func calculate(from sessions: [Date]) -> StreakResult {
        guard !sessions.isEmpty else {
            return StreakResult(
                currentStreak: 0,
                longestStreak: 0,
                weeklyConsistency: 0,
                monthlyConsistency: 0,
                nextMilestone: 7,
                daysToMilestone: 7
            )
        }
        
        let sortedDates = sessions.sorted()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Calculate current streak (with 2-day grace period)
        let currentStreak = calculateCurrentStreak(sortedDates, calendar: calendar, today: today)
        
        // Calculate longest streak
        let longestStreak = calculateLongestStreak(sortedDates, calendar: calendar)
        
        // Calculate weekly consistency (last 4 weeks)
        let weeklyConsistency = calculateWeeklyConsistency(sortedDates, calendar: calendar, today: today)
        
        // Calculate monthly consistency (last 12 weeks)
        let monthlyConsistency = calculateMonthlyConsistency(sortedDates, calendar: calendar, today: today)
        
        // Find next milestone
        let nextMilestone = StreakCalculator.milestones.first { $0 > currentStreak } ?? StreakCalculator.milestones.last!
        let daysToMilestone = max(0, nextMilestone - currentStreak)
        
        return StreakResult(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weeklyConsistency: weeklyConsistency,
            monthlyConsistency: monthlyConsistency,
            nextMilestone: nextMilestone,
            daysToMilestone: daysToMilestone
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateCurrentStreak(_ dates: [Date], calendar: Calendar, today: Date) -> Int {
        var streak = 0
        var currentDate = today
        
        // Go backwards from today, allowing 2-day gaps
        var graceDays = 2
        
        while true {
            let startOfDay = calendar.startOfDay(for: currentDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let hasWorkout = dates.contains { $0 >= startOfDay && $0 < endOfDay }
            
            if hasWorkout {
                streak += 1
                graceDays = 2 // Reset grace
            } else if graceDays > 0 {
                graceDays -= 1
            } else {
                break
            }
            
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            
            // Safety limit
            if streak > 10000 { break }
        }
        
        return streak
    }
    
    private func calculateLongestStreak(_ dates: [Date], calendar: Calendar) -> Int {
        guard dates.count > 1 else { return dates.isEmpty ? 0 : 1 }
        
        var longestStreak = 1
        var currentStreak = 1
        var graceDays = 2
        
        for i in 1..<dates.count {
            let prevDate = calendar.startOfDay(for: dates[i - 1])
            let currDate = calendar.startOfDay(for: dates[i])
            
            let daysDiff = calendar.dateComponents([.day], from: prevDate, to: currDate).day ?? 0
            
            if daysDiff == 1 {
                currentStreak += 1
                graceDays = 2
            } else if daysDiff <= 1 + graceDays {
                currentStreak += 1
                graceDays = max(0, graceDays - (daysDiff - 1))
            } else {
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 1
                graceDays = 2
            }
        }
        
        return max(longestStreak, currentStreak)
    }
    
    private func calculateWeeklyConsistency(_ dates: [Date], calendar: Calendar, today: Date) -> Double {
        let weeksToCheck = 4
        var weeksMet = 0
        
        for weekOffset in 0..<weeksToCheck {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today)!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            let workoutsInWeek = dates.filter { $0 >= weekStart && $0 < weekEnd }
            
            // Consider week "met" if 3+ workouts
            if workoutsInWeek.count >= 3 {
                weeksMet += 1
            }
        }
        
        return Double(weeksMet) / Double(weeksToCheck) * 100
    }
    
    private func calculateMonthlyConsistency(_ dates: [Date], calendar: Calendar, today: Date) -> Double {
        let weeksToCheck = 12
        var weeksMet = 0
        
        for weekOffset in 0..<weeksToCheck {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today)!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            let workoutsInWeek = dates.filter { $0 >= weekStart && $0 < weekEnd }
            
            if workoutsInWeek.count >= 3 {
                weeksMet += 1
            }
        }
        
        return Double(weeksMet) / Double(weeksToCheck) * 100
    }
}