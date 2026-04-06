import Foundation
import SwiftData
import FortachonCore

/// Calculates smart starting weights for exercises based on historical data, profile, and habit analysis.
@MainActor
struct SmartWeightCalculator {
    let modelContext: ModelContext
    let preferences: UserPreferencesM?
    
    init(modelContext: ModelContext, preferences: UserPreferencesM?) {
        self.modelContext = modelContext
        self.preferences = preferences
    }
    
    /// Gets a smart starting weight for an exercise based on history and related exercises.
    /// Matches web's getSmartStartingWeight behavior.
    func getSmartStartingWeight(for exerciseId: String) -> Double {
        // 1. Check direct history for this exercise
        if let historicalWeight = getHistoricalAverageWeight(for: exerciseId) {
            return historicalWeight
        }
        
        // 2. Try related exercises via upgrade paths
        if let relatedWeight = getRelatedExerciseWeight(for: exerciseId) {
            return relatedWeight
        }
        
        // 3. Fall back to main goal-based defaults
        return getDefaultWeight(for: exerciseId)
    }
    
    /// Gets the average weight from historical sessions for this exercise.
    private func getHistoricalAverageWeight(for exerciseId: String) -> Double? {
        let descriptor = FetchDescriptor<WorkoutSessionM>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else { return nil }
        
        var totalWeight: Double = 0
        var setCount: Int = 0
        
        // Look at last 10 sessions for stable average
        for session in sessions.prefix(10) {
            if let exercise = session.exercises.first(where: { $0.exerciseId == exerciseId }) {
                for set in exercise.sets where set.isComplete && set.setTypeStr == "normal" && set.weight > 0 {
                    totalWeight += set.weight
                    setCount += 1
                }
            }
        }
        
        guard setCount > 0 else { return nil }
        return totalWeight / Double(setCount)
    }
    
    /// Tries to find weight from related exercises via known upgrade paths.
    private func getRelatedExerciseWeight(for exerciseId: String) -> Double? {
        // Define reverse upgrade paths (if upgrading from X to Y, we can estimate Y from X)
        let reversePaths: [String: String] = [
            // Bodyweight progressions
            "Diamond Push-ups": "Push-ups",
            "Push-ups": "Incline Push-ups",
            "Incline Push-ups": "Knee Push-ups",
            "Goblet Squats": "Bodyweight Squats",
            "Bulgarian Split Squats": "Lunges",
            "Pull-ups": "Lat Pulldown",
            
            // Machine to free weight
            "Barbell Squats": "Leg Press",
            "Bench Press (Barbell)": "Chest Press Machine",
            "Overhead Press (Barbell)": "Shoulder Press Machine",
            
            // Dumbbell to barbell
            "Bench Press (Barbell)": "Dumbbell Bench Press",
            "Barbell Rows": "Dumbbell Rows",
            "Overhead Press (Barbell)": "Dumbbell Shoulder Press",
            
            // Progressions
            "Incline Bench Press": "Bench Press (Barbell)",
            "Weighted Pull-ups": "Pull-ups",
            "Front Squats": "Goblet Squats",
            "Deadlift": "Romanian Deadlift",
        ]
        
        guard let relatedExerciseName = reversePaths[exerciseId] else { return nil }
        
        // Find the related exercise ID by name
        let exerciseDescriptor = FetchDescriptor<ExerciseM>()
        guard let exercises = try? modelContext.fetch(exerciseDescriptor) else { return nil }
        
        if let relatedExercise = exercises.first(where: { $0.name == relatedExerciseName }) {
            // Get 80% of the related exercise's typical weight (harder variant should start lighter)
            if let avgWeight = getHistoricalAverageWeight(for: relatedExercise.id) {
                return avgWeight * 0.8
            }
        }
        
        return nil
    }
    
    /// Returns default weight based on exercise category and user profile.
    private func getDefaultWeight(for exerciseId: String) -> Double {
        let descriptor = FetchDescriptor<ExerciseM>()
        guard let exercises = try? modelContext.fetch(descriptor),
              let exercise = exercises.first(where: { $0.id == exerciseId }) else {
            return 20.0 // Default bar weight
        }
        
        let isUpperBody = ["Chest", "Shoulders", "Arms", "Back"].contains(exercise.bodyPartStr)
        let goal = preferences?.mainGoal ?? .muscle
        
        switch (goal, isUpperBody) {
        case (.strength, true): return 30.0
        case (.strength, false): return 50.0
        case (.endurance, true): return 20.0
        case (.endurance, false): return 30.0
        case (.muscle, true): return 25.0
        case (.muscle, false): return 40.0
        case (_, true): return 20.0
        case (_, false): return 30.0
        }
    }
    
    /// Analyzes user habits from workout history (matches web's analyzeUserHabits).
    func analyzeUserHabits() -> UserHabits {
        let descriptor = FetchDescriptor<WorkoutSessionM>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else {
            return UserHabits(totalWorkouts: 0, exerciseFrequency: [:], averageSetsPerWorkout: 0, averageWorkoutDuration: 0)
        }
        
        var exerciseCounts: [String: Int] = [:]
        var totalSets = 0
        
        for session in sessions {
            var exercisesInSession: Set<String> = []
            for exercise in session.exercises {
                exercisesInSession.insert(exercise.exerciseId)
                totalSets += exercise.sets.filter { $0.isComplete }.count
            }
            for exId in exercisesInSession {
                exerciseCounts[exId, default: 0] += 1
            }
        }
        
        let avgSets = sessions.isEmpty ? 0 : totalSets / sessions.count
        let avgDuration = 0 // Would need elapsed time tracking
        
        return UserHabits(
            totalWorkouts: sessions.count,
            exerciseFrequency: exerciseCounts,
            averageSetsPerWorkout: avgSets,
            averageWorkoutDuration: avgDuration
        )
    }
    
    /// Gets the last body weight recorded in sessions.
    func getLastBodyWeight() -> Double? {
        let lookup = HistoricalLookup(modelContext: modelContext)
        return lookup.getLastBodyWeight()
    }
    
    /// Infers user profile from workout history (matches web's inferUserProfile).
    func inferUserProfile() -> UserGoal {
        let habits = analyzeUserHabits()
        
        // If user consistently does high volume, likely muscle goal
        if habits.averageSetsPerWorkout > 15 {
            return .muscle
        }
        
        // Check exercise variety - if many different exercises, likely endurance
        if habits.exerciseFrequency.count > 15 {
            return .endurance
        }
        
        return .muscle // Default assumption
    }
}

/// User habit analysis result.
struct UserHabits {
    let totalWorkouts: Int
    let exerciseFrequency: [String: Int]
    let averageSetsPerWorkout: Int
    let averageWorkoutDuration: Int
}