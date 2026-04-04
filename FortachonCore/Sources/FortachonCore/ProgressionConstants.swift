import Foundation

// MARK: - Progression Constants
// Mirrors constants/progression.ts

/// Represents criteria that must be met to progress from one exercise to another.
public struct ProgressionCriteria: Sendable {
    public let minWeightRatio: Double?  // Weight relative to bodyweight (e.g., 0.5 = 50% BW)
    public let minReps: Int
    public let requiredSessions: Int    // How many times criteria must be met

    public init(minWeightRatio: Double? = nil, minReps: Int, requiredSessions: Int) {
        self.minWeightRatio = minWeightRatio
        self.minReps = minReps
        self.requiredSessions = requiredSessions
    }
}

/// Represents a progression path from a base exercise to a target exercise.
public struct ProgressionPath: Sendable {
    public let baseExerciseId: String
    public let targetExerciseId: String
    public let criteria: ProgressionCriteria
    public let reasonKey: String

    public init(baseExerciseId: String, targetExerciseId: String, criteria: ProgressionCriteria, reasonKey: String) {
        self.baseExerciseId = baseExerciseId
        self.targetExerciseId = targetExerciseId
        self.criteria = criteria
        self.reasonKey = reasonKey
    }
}

/// All defined progression paths for exercise promotions.
public let progressionPaths: [ProgressionPath] = [
    ProgressionPath(
        baseExerciseId: "ex-109",  // Goblet Squat
        targetExerciseId: "ex-2",  // Barbell Squat
        criteria: ProgressionCriteria(minWeightRatio: 0.35, minReps: 10, requiredSessions: 3),
        reasonKey: "progression_reason_squat"
    ),
    ProgressionPath(
        baseExerciseId: "ex-23",   // Push Up
        targetExerciseId: "ex-1",  // Bench Press
        criteria: ProgressionCriteria(minWeightRatio: nil, minReps: 20, requiredSessions: 3),
        reasonKey: "progression_reason_bench"
    ),
    ProgressionPath(
        baseExerciseId: "ex-5",    // Barbell Row
        targetExerciseId: "ex-6",  // Pull Up
        criteria: ProgressionCriteria(minWeightRatio: 0.7, minReps: 5, requiredSessions: 3),
        reasonKey: "progression_reason_pullup"
    ),
    ProgressionPath(
        baseExerciseId: "ex-98",   // RDL
        targetExerciseId: "ex-3",  // Deadlift
        criteria: ProgressionCriteria(minWeightRatio: 0.6, minReps: 8, requiredSessions: 3),
        reasonKey: "progression_reason_deadlift"
    ),
]
