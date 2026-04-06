import SwiftUI
import Foundation
import SwiftData
import FortachonCore

// MARK: - Rest Times (matching web version)

struct RestTimes {
    var normal: Int = 90
    var warmup: Int = 60
    var drop: Int = 30
    var timed: Int = 10
    var effort: Int = 90
    var failure: Int = 300
}

// MARK: - View Helpers

extension TimeInterval {
    var formattedAsTimer: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedAsWorkout: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Workout Progression Utilities

/// Standalone utilities for workout progression: rep PR detection, auto weight increase,
/// estimated 1RM calculations, and historical performance analysis.
enum WorkoutProgressionUtils {
    
    /// Check if current performance is a rep PR.
    /// Returns whether this is a PR and the previous max reps.
    @MainActor static func checkRepPR(
        exerciseId: String,
        currentReps: Int,
        weight: Double,
        modelContext: ModelContext
    ) -> (isPR: Bool, previousMaxReps: Int) {
        let historicalMax = getHistoricalMaxReps(
            exerciseId: exerciseId,
            targetWeight: weight,
            weightTolerance: 5.0,
            modelContext: modelContext
        )
        
        return (
            isPR: currentReps > historicalMax && currentReps > 0,
            previousMaxReps: historicalMax
        )
    }
    
    /// Calculate suggested weight increase based on progression rules.
    /// Upper body: +2.5kg, Lower body: +5.0kg
    static func autoIncreaseWeight(currentWeight: Double, isUpperBody: Bool) -> Double {
        let increment: Double = isUpperBody ? 2.5 : 5.0
        let newWeight = currentWeight + increment
        // Round to nearest 0.5
        return round(newWeight * 2) / 2
    }
    
    /// Calculate estimated 1RM using Brzycki formula: weight × (36 / (37 - reps))
    static func estimate1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        guard reps < 37 else { return weight * 1.5 } // Cap for high reps
        let result = weight * (36.0 / (37.0 - Double(reps)))
        return round(result * 10) / 10 // Round to 1 decimal
    }
    
    /// Get historical max reps for an exercise at a given weight range.
    @MainActor static func getHistoricalMaxReps(
        exerciseId: String,
        targetWeight: Double,
        weightTolerance: Double = 5.0,
        modelContext: ModelContext
    ) -> Int {
        let descriptor = FetchDescriptor<WorkoutSessionM>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else { return 0 }
        var maxReps = 0
        
        for session in sessions.prefix(50) {
            for ex in session.exercises where ex.exerciseId == exerciseId {
                for set in ex.sets where set.isComplete && set.setTypeStr == "normal" {
                    let weightDiff = abs(set.weight - targetWeight)
                    if weightDiff <= weightTolerance && set.reps > maxReps {
                        maxReps = set.reps
                    }
                }
            }
        }
        
        return maxReps
    }
    
    /// Determine if an exercise is upper body based on exercise ID
    static func isUpperBodyExercise(exerciseId: String) -> Bool {
        let upperBodyPrefixes: Set<String> = [
            "ex-1", "ex-4", "ex-5", "ex-6", "ex-7", "ex-8",
            "ex-10", "ex-11", "ex-12", "ex-13", "ex-14",
            "ex-21", "ex-22", "ex-23", "ex-24", "ex-25",
            "ex-26", "ex-27", "ex-28", "ex-29", "ex-30",
            "ex-31", "ex-32", "ex-33", "ex-34", "ex-35",
            "ex-36", "ex-37", "ex-38", "ex-39", "ex-40",
            "ex-41", "ex-42", "ex-44", "ex-47", "ex-48",
            "ex-49", "ex-50", "ex-51", "ex-52", "ex-53",
            "ex-54", "ex-55", "ex-56", "ex-57", "ex-58",
            "ex-63", "ex-64", "ex-65", "ex-66", "ex-67",
            "ex-68", "ex-69", "ex-70", "ex-71", "ex-72",
            "ex-73", "ex-74", "ex-75", "ex-76", "ex-77",
            "ex-78", "ex-79", "ex-80", "ex-81", "ex-82",
            "ex-83", "ex-84", "ex-85"
        ]
        return upperBodyPrefixes.contains(exerciseId)
    }
    
    /// Get historical 1RM data for an exercise
    static func getExercise1RMHistory(
        exerciseId: String,
        modelContext: ModelContext
    ) -> [(date: Date, weight: Double)] {
        let descriptor = FetchDescriptor<WorkoutSessionM>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else { return [] }
        var history: [(date: Date, weight: Double)] = []
        
        for session in sessions.prefix(30) {
            for ex in session.exercises where ex.exerciseId == exerciseId {
                var maxE1RM: Double = 0
                for set in ex.sets where set.isComplete && set.setTypeStr == "normal" && set.reps > 0 {
                    let e1rm = estimate1RM(weight: set.weight, reps: set.reps)
                    if e1rm > maxE1RM {
                        maxE1RM = e1rm
                    }
                }
                if maxE1RM > 0 {
                    history.append((date: session.startTime, weight: maxE1RM))
                }
            }
        }
        
        return history
    }
    
    /// Get best 1RM for an exercise across all sessions
    static func getBest1RM(
        exerciseId: String,
        modelContext: ModelContext
    ) -> Double {
        let history = getExercise1RMHistory(exerciseId: exerciseId, modelContext: modelContext)
        return history.map { $0.weight }.max() ?? 0
    }
    
    /// Check for stale workout (3+ hours since start with no recent completed sets)
    static func checkStaleWorkout(
        startTime: Date,
        completedSets: Int,
        totalSets: Int
    ) -> (isStale: Bool, hoursInactive: Int)? {
        let hoursSinceStart = Date().timeIntervalSince(startTime) / 3600.0
        guard hoursSinceStart >= 3.0 else { return nil }
        return (isStale: true, hoursInactive: Int(hoursSinceStart))
    }
}