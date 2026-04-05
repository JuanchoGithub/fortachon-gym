import Foundation
import FortachonCore

// MARK: - Workout Validation Result

struct WorkoutValidationResult {
    let isValid: Bool
    let warnings: [ValidationWarning]
    let errors: [ValidationError]
    
    var hasIssues: Bool { !warnings.isEmpty || !errors.isEmpty }
    var canFinish: Bool { errors.isEmpty }
}

struct ValidationWarning: Identifiable {
    let id = UUID()
    let message: String
    let severity: WarningSeverity
    
    enum WarningSeverity {
        case info, warning, critical
    }
}

struct ValidationError: Identifiable {
    let id = UUID()
    let message: String
    let isBlocking: Bool
}

// MARK: - Workout Completion Validator

@MainActor
final class WorkoutCompletionValidator {
    
    // MARK: - Validate
    
    /// Validate a workout before completion.
    /// - Parameters:
    ///   - exercises: Array of workout exercises
    ///   - templateExercises: Optional template to compare against
    /// - Returns: ValidationResult with warnings and errors
    func validate(
        exercises: [WorkoutExerciseM],
        templateExercises: [WorkoutExerciseM]? = nil
    ) -> WorkoutValidationResult {
        var warnings: [ValidationWarning] = []
        var errors: [ValidationError] = []
        
        // Check 1: No exercises
        if exercises.isEmpty {
            errors.append(ValidationError(
                message: "No exercises added. Add at least one exercise to finish.",
                isBlocking: true
            ))
            return WorkoutValidationResult(isValid: false, warnings: warnings, errors: errors)
        }
        
        // Check 2: No completed sets at all
        let totalCompletedSets = exercises.reduce(0) { count, ex in
            count + ex.sets.filter { $0.isComplete }.count
        }
        
        if totalCompletedSets == 0 {
            errors.append(ValidationError(
                message: "No completed sets. Complete at least one set to finish the workout.",
                isBlocking: true
            ))
            return WorkoutValidationResult(isValid: false, warnings: warnings, errors: errors)
        }
        
        // Check 3: Exercises with no completed sets
        for ex in exercises {
            let hasCompletedSets = ex.sets.contains { $0.isComplete }
            if !hasCompletedSets {
                warnings.append(ValidationWarning(
                    message: "\"\(ex.exerciseId)\" has no completed sets.",
                    severity: .warning
                ))
            }
        }
        
        // Check 4: Only warmup sets completed
        for ex in exercises {
            let normalSets = ex.sets.filter { $0.setTypeStr == "normal" && $0.isComplete }
            let warmupOnly = ex.sets.contains { $0.isComplete } && normalSets.isEmpty
            if warmupOnly {
                warnings.append(ValidationWarning(
                    message: "\"\(ex.exerciseId)\" only has warmup sets completed.",
                    severity: .info
                ))
            }
        }
        
        // Check 5: Very low volume (less than 3 total completed working sets)
        let workingSets = exercises.reduce(0) { count, ex in
            count + ex.sets.filter { $0.isComplete && $0.setTypeStr != "warmup" }.count
        }
        if workingSets < 3 {
            warnings.append(ValidationWarning(
                message: "Very low volume (\(workingSets) working sets). Consider adding more sets.",
                severity: .warning
            ))
        }
        
        // Check 6: Compare against template (if provided)
        if let template = templateExercises {
            let missingExercises = template.filter { templateEx in
                !exercises.contains { $0.exerciseId == templateEx.exerciseId }
            }
            for missing in missingExercises {
                warnings.append(ValidationWarning(
                    message: "\"\(missing.exerciseId)\" was in your template but not performed.",
                    severity: .info
                ))
            }
        }
        
        // Check 7: Very short workout (less than 5 minutes)
        // This is checked at the view level with elapsed time
        
        let isValid = errors.isEmpty
        return WorkoutValidationResult(
            isValid: isValid,
            warnings: warnings,
            errors: errors
        )
    }
    
    // MARK: - 1RM Detection
    
    /// Check if a completed set represents a new estimated 1RM.
    /// - Parameters:
    ///   - exerciseId: The exercise ID
    ///   - weight: Weight used
    ///   - reps: Reps completed
    ///   - current1RM: Current stored 1RM for this exercise
    /// - Returns: New estimated 1RM if it's a PR, nil otherwise
    func detectNew1RM(
        exerciseId: String,
        weight: Double,
        reps: Int,
        current1RM: Double
    ) -> Double? {
        guard reps > 0 && weight > 0 else { return nil }
        
        // Use Epley formula: 1RM = weight × (1 + reps/30)
        let estimated1RM = weight * (1.0 + Double(reps) / 30.0)
        
        // Check if this is a meaningful improvement (> 2.5%)
        let improvementThreshold = current1RM * 1.025
        
        if estimated1RM > improvementThreshold && estimated1RM > current1RM {
            return estimated1RM
        }
        
        return nil
    }
    
    // MARK: - Workout Summary
    
    struct WorkoutSummary {
        let duration: TimeInterval
        let totalVolume: Double
        let setsCompleted: Int
        let totalSets: Int
        let exercisesCompleted: Int
        let totalExercises: Int
        let new1RMs: [(exerciseId: String, new1RM: Double)]
        let prCount: Int
    }
    
    /// Generate a workout summary.
    func generateSummary(
        exercises: [WorkoutExerciseM],
        startTime: Date,
        endTime: Date,
        new1RMs: [(exerciseId: String, new1RM: Double)] = [],
        prCount: Int = 0
    ) -> WorkoutSummary {
        let duration = endTime.timeIntervalSince(startTime)
        
        var totalVolume: Double = 0
        var setsCompleted = 0
        var totalSets = 0
        var exercisesCompleted = 0
        
        for ex in exercises {
            totalSets += ex.sets.count
            let completedSets = ex.sets.filter { $0.isComplete }
            setsCompleted += completedSets.count
            
            if !completedSets.isEmpty {
                exercisesCompleted += 1
            }
            
            for set in completedSets {
                totalVolume += set.weight * Double(set.reps)
            }
        }
        
        return WorkoutSummary(
            duration: duration,
            totalVolume: totalVolume,
            setsCompleted: setsCompleted,
            totalSets: totalSets,
            exercisesCompleted: exercisesCompleted,
            totalExercises: exercises.count,
            new1RMs: new1RMs,
            prCount: prCount
        )
    }
}