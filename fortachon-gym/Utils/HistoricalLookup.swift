import Foundation
import SwiftData
import FortachonCore

/// Utility for looking up historical workout data to compare against current performance.
@MainActor
struct HistoricalLookup {
    let modelContext: ModelContext
    
    /// Finds the last completed session containing the given exercise and returns average weight/reps.
    func getLastSessionValues(for exerciseId: String) -> (avgWeight: Double, avgReps: Int)? {
        let descriptor = FetchDescriptor<WorkoutSessionM>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else { return nil }
        
        // Find the most recent session that contains this exercise
        for session in sessions {
            let matchingExercise = session.exercises.first { $0.exerciseId == exerciseId }
            guard let exercise = matchingExercise else { continue }
            
            // Get completed sets (excluding warmup for comparison)
            let completedSets = exercise.sets.filter {
                $0.isComplete && $0.setTypeStr != "warmup" && $0.weight > 0
            }
            
            guard !completedSets.isEmpty else { continue }
            
            let totalWeight = completedSets.reduce(0) { $0 + $1.weight }
            let totalReps = completedSets.reduce(0) { $0 + $1.reps }
            let count = Double(completedSets.count)
            
            return (avgWeight: totalWeight / count, avgReps: totalReps / completedSets.count)
        }
        
        return nil
    }
    
    /// Gets the last body weight recorded in any session.
    func getLastBodyWeight() -> Double? {
        let descriptor = FetchDescriptor<WorkoutSessionM>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else { return nil }
        
        for session in sessions {
            for exercise in session.exercises {
                if let bw = exercise.sets.compactMap({ $0.storedBodyWeight }).first {
                    return bw
                }
            }
        }
        
        return nil
    }
    
    /// Gets exercise frequency in the last N sessions.
    func getExerciseFrequency(in lastNSessions: Int = 10) -> [String: Int] {
        let descriptor = FetchDescriptor<WorkoutSessionM>(
            predicate: #Predicate { _ in true },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else { return [:] }
        let limitedSessions = Array(sessions.prefix(lastNSessions))
        
        var counts: [String: Int] = [:]
        for session in limitedSessions {
            var seenIds = Set<String>()
            for exercise in session.exercises {
                if !seenIds.contains(exercise.exerciseId) {
                    counts[exercise.exerciseId, default: 0] += 1
                    seenIds.insert(exercise.exerciseId)
                }
            }
        }
        
        return counts
    }
    
    /// Gets all exercises from the last session for a given exercise ID.
    func getLastSessionSets(for exerciseId: String) -> [PerformedSetM]? {
        let descriptor = FetchDescriptor<WorkoutSessionM>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else { return nil }
        
        for session in sessions {
            let matchingExercise = session.exercises.first { $0.exerciseId == exerciseId }
            if let exercise = matchingExercise {
                return exercise.sets
            }
        }
        
        return nil
    }
    
    /// Gets recent workout sessions for muscle freshness calculation.
    func getRecentSessions(limit: Int = 10) -> [WorkoutSessionM] {
        let descriptor = FetchDescriptor<WorkoutSessionM>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        guard let sessions = try? modelContext.fetch(descriptor) else { return [] }
        return Array(sessions.prefix(limit))
    }
}
