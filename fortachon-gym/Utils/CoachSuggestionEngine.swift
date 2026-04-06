import Foundation
import FortachonCore

// MARK: - Coach Suggestion Engine

/// Generates workout suggestions based on fatigue analysis and muscle freshness.
/// Mirrors the web version's handleCoachSuggest() and handleAggressiveSuggest() logic.
enum CoachSuggestionEngine {
    
    // MARK: - Muscle Group Definitions
    
    static let pushMuscleIds = ["chest", "front_delts", "triceps", "pectorals", "anterior_deltoid"]
    static let pullMuscleIds = ["lats", "traps", "biceps", "latissimus_dorsi", "rhomboids"]
    static let legMuscleIds = ["quads", "hamstrings", "glutes", "quadriceps"]
    
    // MARK: - Suggestion Result
    
    struct Suggestion {
        let exercises: [(exerciseId: String, sets: [(reps: Int, weight: Double, type: String)])]
        let focusLabel: String
        let description: String
        let isFallback: Bool
    }
    
    // MARK: - Generate Suggestion (Normal Mode)
    
    static func generateSuggestion(
        sessions: [WorkoutSessionM],
        allExercises: [ExerciseM],
        routines: [RoutineM],
        prefs: UserPreferencesM?
    ) -> Suggestion? {
        let muscleFreshness = computeMuscleFreshness(
            sessions: sessions,
            allExercises: allExercises,
            prefs: prefs
        )
        
        // Calculate average freshness per group
        let pushScore = averageFreshness(for: pushMuscleIds, freshness: muscleFreshness)
        let pullScore = averageFreshness(for: pullMuscleIds, freshness: muscleFreshness)
        let legsScore = averageFreshness(for: legMuscleIds, freshness: muscleFreshness)
        
        // If all groups are very fatigued, suggest recovery
        if pushScore < 30 && pullScore < 30 && legsScore < 30 {
            return generateRecoverySuggestion(allExercises: allExercises)
        }
        
        // Find freshest muscle group
        let groups: [(name: String, score: Double)] = [
            ("Push", pushScore),
            ("Pull", pullScore),
            ("Legs", legsScore)
        ]
        let sorted = groups.sorted { $0.score > $1.score }
        let freshest = sorted.first!
        
        let routine = generateRoutineForMuscleGroup(
            muscleGroup: freshest.name,
            allExercises: allExercises,
            routines: routines
        )
        
        guard !routine.isEmpty else { return nil }
        
        return Suggestion(
            exercises: routine,
            focusLabel: freshest.name,
            description: "\(freshest.name) muscles are \(Int(freshest.score))% recovered. Ready for a focused session.",
            isFallback: false
        )
    }
    
    // MARK: - Generate Aggressive Suggestion
    
    static func generateAggressiveSuggestion(
        sessions: [WorkoutSessionM],
        allExercises: [ExerciseM],
        routines: [RoutineM],
        prefs: UserPreferencesM?
    ) -> Suggestion {
        let muscleFreshness = computeMuscleFreshness(
            sessions: sessions,
            allExercises: allExercises,
            prefs: prefs
        )
        
        let pushScore = averageFreshness(for: pushMuscleIds, freshness: muscleFreshness)
        let pullScore = averageFreshness(for: pullMuscleIds, freshness: muscleFreshness)
        let legsScore = averageFreshness(for: legMuscleIds, freshness: muscleFreshness)
        
        let groups: [(name: String, score: Double)] = [
            ("Push", pushScore),
            ("Pull", pullScore),
            ("Legs", legsScore)
        ]
        let sorted = groups.sorted { $0.score > $1.score }
        let freshest = sorted.first!
        
        let routine = generateRoutineForMuscleGroup(
            muscleGroup: freshest.name,
            allExercises: allExercises,
            routines: routines
        )
        
        let finalRoutine = routine.isEmpty ? generateBasicPushWorkout(allExercises: allExercises) : routine
        
        return Suggestion(
            exercises: finalRoutine,
            focusLabel: freshest.name,
            description: "Ignoring fatigue. \(freshest.name) muscles are \(Int(freshest.score))% recovered.",
            isFallback: false
        )
    }
    
    // MARK: - Recovery Suggestion
    
    static func generateRecoverySuggestion(allExercises: [ExerciseM]) -> Suggestion? {
        let mobilityExercises = allExercises.filter {
            $0.categoryStr == "Flexibility" || $0.categoryStr == "Mobility"
        }
        
        var result: [(exerciseId: String, sets: [(reps: Int, weight: Double, type: String)])] = []
        
        for ex in mobilityExercises.prefix(5) {
            result.append((exerciseId: ex.id, sets: [(reps: 10, weight: 0, type: "normal")]))
        }
        
        if result.isEmpty { return nil }
        
        return Suggestion(
            exercises: result,
            focusLabel: "Recovery",
            description: "You're showing signs of fatigue. Consider a light mobility session.",
            isFallback: true
        )
    }
    
    // MARK: - Muscle Freshness Computation
    
    private static func computeMuscleFreshness(
        sessions: [WorkoutSessionM],
        allExercises: [ExerciseM],
        prefs: UserPreferencesM?
    ) -> [MuscleFreshness] {
        let goal = prefs?.mainGoal ?? .muscle
        let baseline = goal == .strength ? 10.0 : (goal == .endurance ? 20.0 : 15.0)
        let bioAdaptive = prefs?.bioAdaptiveEngine ?? false
        
        let coreSessions = sessions.map { session -> (exercises: [WorkoutExercise], startTime: Date, endTime: Date) in
            let exercises = session.exercises.map { WorkoutExercise(from: $0) }
            return (exercises: exercises, startTime: session.startTime, endTime: session.endTime)
        }
        
        let coreExercises = allExercises.map { Exercise(from: $0) }
        
        return calculateMuscleFreshnessAdvanced(
            sessions: coreSessions,
            exercises: coreExercises,
            capacityBaseline: baseline,
            bioAdaptiveEnabled: bioAdaptive
        )
    }
    
    private static func averageFreshness(for muscleIds: [String], freshness: [MuscleFreshness]) -> Double {
        let matching = freshness.filter { mf in
            muscleIds.contains { $0.lowercased().contains(mf.muscleName.lowercased()) || mf.muscleName.lowercased().contains($0) }
        }
        guard !matching.isEmpty else { return 50.0 }
        return matching.reduce(0) { $0 + $1.freshnessPercent } / Double(matching.count)
    }
    
    // MARK: - Routine Generation
    
    private static func generateRoutineForMuscleGroup(
        muscleGroup: String,
        allExercises: [ExerciseM],
        routines: [RoutineM]
    ) -> [(exerciseId: String, sets: [(reps: Int, weight: Double, type: String)])] {
        let matchingRoutines = routines.filter { routine in
            routine.name.localizedCaseInsensitiveContains(muscleGroup) ||
            routine.desc.localizedCaseInsensitiveContains(muscleGroup)
        }
        
        if let bestRoutine = matchingRoutines.first {
            return bestRoutine.exercises.map { ex in
                (
                    exerciseId: ex.exerciseId,
                    sets: ex.sets.map { (reps: $0.reps, weight: $0.weight, type: $0.setTypeStr) }
                )
            }
        }
        
        switch muscleGroup {
        case "Push": return generateBasicPushWorkout(allExercises: allExercises)
        case "Pull": return generateBasicPullWorkout(allExercises: allExercises)
        case "Legs": return generateBasicLegWorkout(allExercises: allExercises)
        default: return []
        }
    }
    
    static func generateBasicPushWorkout(allExercises: [ExerciseM]) -> [(exerciseId: String, sets: [(reps: Int, weight: Double, type: String)])] {
        let pushIds = ["ex-1", "ex-4", "ex-26", "ex-85"]
        return pushIds.compactMap { id in
            allExercises.first { $0.id == id }.map {
                (exerciseId: $0.id, sets: [(reps: 8, weight: 0, type: "normal"), (reps: 8, weight: 0, type: "normal"), (reps: 8, weight: 0, type: "normal")])
            }
        }
    }
    
    static func generateBasicPullWorkout(allExercises: [ExerciseM]) -> [(exerciseId: String, sets: [(reps: Int, weight: Double, type: String)])] {
        let pullIds = ["ex-5", "ex-10", "ex-7"]
        return pullIds.compactMap { id in
            allExercises.first { $0.id == id }.map {
                (exerciseId: $0.id, sets: [(reps: 8, weight: 0, type: "normal"), (reps: 8, weight: 0, type: "normal"), (reps: 8, weight: 0, type: "normal")])
            }
        }
    }
    
    static func generateBasicLegWorkout(allExercises: [ExerciseM]) -> [(exerciseId: String, sets: [(reps: Int, weight: Double, type: String)])] {
        let legIds = ["ex-2", "ex-16", "ex-17", "ex-20"]
        return legIds.compactMap { id in
            allExercises.first { $0.id == id }.map {
                (exerciseId: $0.id, sets: [(reps: 8, weight: 0, type: "normal"), (reps: 8, weight: 0, type: "normal"), (reps: 8, weight: 0, type: "normal")])
            }
        }
    }
}
