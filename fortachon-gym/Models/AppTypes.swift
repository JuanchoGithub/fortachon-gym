import SwiftUI
import FortachonCore

// MARK: - Upgrade Suggestion Types

/// A suggestion from the smart coach to upgrade an exercise to a more challenging variant.
struct UpgradeSuggestion: Identifiable {
    let id = UUID()
    let currentExerciseId: String
    let targetExerciseId: String
    let currentExerciseName: String
    let targetExerciseName: String
    let reason: String
}

/// Generates upgrade suggestions based on workout history and exercise frequency.
enum UpgradeSuggestions {
    static func generate(
        currentExerciseIds: [String],
        allExercises: [ExerciseM],
        frequency: [String: Int]
    ) -> [UpgradeSuggestion] {
        var suggestions: [UpgradeSuggestion] = []
        
        // Define known exercise upgrade paths (easier → harder variants)
        let upgradePaths: [String: String] = [
            // Bodyweight → Weighted progressions
            "Push-ups": "Diamond Push-ups",  // Primary push-up progression
            "Incline Push-ups": "Push-ups",
            "Knee Push-ups": "Push-ups",
            "Wall Push-ups": "Incline Push-ups",
            "Bodyweight Squats": "Goblet Squats",
            "Lunges": "Bulgarian Split Squats",
            "Plank": "Weighted Plank",
            "Dips (Bench)": "Dips (Parallel Bars)",
            "Lat Pulldown": "Pull-ups",
            "Assisted Pull-ups": "Pull-ups",
            
            // Machine → Free weight progressions
            "Leg Press": "Barbell Squats",
            "Chest Press Machine": "Bench Press (Barbell)",
            "Shoulder Press Machine": "Overhead Press (Barbell)",
            "Cable Flyes": "Dumbbell Flyes",
            "Leg Curl Machine": "Romanian Deadlift",
            "Leg Extension Machine": "Front Squats",
            
            // Dumbbell → Barbell progressions
            "Dumbbell Bench Press": "Bench Press (Barbell)",
            "Dumbbell Rows": "Barbell Rows",
            "Dumbbell Shoulder Press": "Overhead Press (Barbell)",
            "Dumbbell Romanian Deadlift": "Romanian Deadlift",
            "Dumbbell Lunges": "Bulgarian Split Squats",
            
            // Difficulty progressions within same movement
            "Bench Press (Barbell)": "Incline Bench Press",
            "Overhead Press (Barbell)": "Handstand Push-ups",
            "Pull-ups": "Weighted Pull-ups",
            "Diamond Push-ups": "Weighted Push-ups",
            "Goblet Squats": "Front Squats",
            "Romanian Deadlift": "Deadlift",
            "Bulgarian Split Squats": "Pistol Squats",
        ]
        
        for exerciseId in currentExerciseIds {
            // Find the exercise name
            let exerciseName = allExercises.first { $0.id == exerciseId }?.name ?? exerciseId
            
            // Check if there's an upgrade path for this exercise
            guard let targetName = upgradePaths[exerciseName] else { continue }
            
            // Find target exercise ID
            guard let targetExercise = allExercises.first(where: { $0.name == targetName }) else { continue }
            
            // Don't suggest upgrades for exercises done very few times
            let frequency = frequency[exerciseId] ?? 0
            guard frequency >= 2 else { continue }
            
            // Generate reason based on frequency
            let reason: String
            if frequency >= 5 {
                reason = "You've done \(exerciseName) \(frequency) times. Time to level up!"
            } else {
                reason = "Ready to progress from \(exerciseName)? Try \(targetName)."
            }
            
            suggestions.append(UpgradeSuggestion(
                currentExerciseId: exerciseId,
                targetExerciseId: targetExercise.id,
                currentExerciseName: exerciseName,
                targetExerciseName: targetName,
                reason: reason
            ))
        }
        
        return suggestions
    }
}