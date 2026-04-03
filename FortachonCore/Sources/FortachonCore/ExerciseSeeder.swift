import Foundation
import SwiftData

// MARK: - Exercise Seeder
// Convenience functions for populating SwiftData from seed constants.

/// Seeds exercises and routines into a ModelContext if the database appears empty.
/// Returns true if items were inserted, false if they already exist.
@MainActor
public func seedIfEmpty(_ context: ModelContext) async -> Bool {
    let fetchDescriptorEx = FetchDescriptor<ExerciseM>()
    if let existingCount = try? context.fetchCount(fetchDescriptorEx), existingCount > 0 {
        return false // Already seeded
    }

    // Seed exercises
    let exercises = makeExerciseModels()
    for ex in exercises {
        context.insert(ex)
    }

    // Seed routines
    let routines = makeRoutineModels()
    for r in routines {
        context.insert(r)
    }

    try? context.save()
    print("[FortachonCore] Seeded \(exercises.count) exercises and \(routines.count) routines.")
    return true
}

/// Force-seeds the database (clears existing exercises/routines if needed, then inserts).
@MainActor
public func seedForce(_ context: ModelContext) async {
    // Clear existing routines
    let routineFetch = FetchDescriptor<RoutineM>()
    if let routines = try? context.fetch(routineFetch) {
        for r in routines { context.delete(r) }
    }

    // Clear existing exercises (and their relationships)
    let exFetch = FetchDescriptor<ExerciseM>()
    if let exercises = try? context.fetch(exFetch) {
        for ex in exercises { context.delete(ex) }
    }

    try? context.save()

    // Re-seed
    let newExercises = makeExerciseModels()
    for ex in newExercises { context.insert(ex) }

    let newRoutines = makeRoutineModels()
    for r in newRoutines { context.insert(r) }

    try? context.save()
    print("[FortachonCore] Force seeded \(newExercises.count) exercises and \(newRoutines.count) routines.")
}

/// Synchronously inserts exercise models into a ModelContext (non-@MainActor compatible for use from non-UI code).
/// Note: ExerciseM is a @Model class so insertion must typically happen on main thread.
public func insertExerciseModels(into context: ModelContext) {
    let exercises = makeExerciseModels()
    for ex in exercises { context.insert(ex) }
    try? context.save()
}

/// Synchronously inserts routine models into a ModelContext.
/// Note: RoutineM is a @Model class so insertion must typically happen on main thread.
public func insertRoutineModels(into context: ModelContext) {
    let routines = makeRoutineModels()
    for r in routines { context.insert(r) }
    try? context.save()
}
