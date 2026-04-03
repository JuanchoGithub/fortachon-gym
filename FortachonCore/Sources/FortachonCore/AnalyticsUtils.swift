import Foundation

// MARK: - HabitData

public struct HabitData {
    public let exerciseFrequency: [String: Int]
    public let routineFrequency: [String: Int]
}

// MARK: - analyzeUserHabits

public func analyzeUserHabits(_ history: [WorkoutSession]) -> HabitData {
    let now = Date()
    let cutoff = now.timeIntervalSince1970 * 1000 - 90 * 24 * 60 * 60 * 1000
    let recent = history.filter { $0.startTime > cutoff }
    var exFreq: [String: Int] = [:]
    var rtFreq: [String: Int] = [:]
    for session in recent {
        rtFreq[session.routineId, default: 0] += 1
        for ex in session.exercises {
            exFreq[ex.exerciseId, default: 0] += 1
        }
    }
    return HabitData(exerciseFrequency: exFreq, routineFrequency: rtFreq)
}

// MARK: - calculateSessionDensity

public func calculateSessionDensity(_ session: WorkoutSession) -> Double {
    guard session.endTime > session.startTime else { return 0 }
    let minutes = (session.endTime - session.startTime) / 60_000
    guard minutes >= 5 else { return 0 }
    var totalVolume: Double = 0
    for ex in session.exercises {
        for set in ex.sets where set.isComplete {
            totalVolume += set.weight * Double(set.reps)
        }
    }
    return totalVolume / minutes
}

// MARK: - calculateAverageDensity

public func calculateAverageDensity(_ history: [WorkoutSession], limit: Int = 10) -> Double {
    let densities = history.prefix(limit)
        .map(calculateSessionDensity)
        .filter { $0 > 0 }
    guard !densities.isEmpty else { return 0 }
    return densities.reduce(0, +) / Double(densities.count)
}

// MARK: - detectPreferredIncrement

public func detectPreferredIncrement(legWeight: Double) -> Double {
    return legWeight <= 20 ? 2.5 : 5.0
}

// MARK: - calculateMedianWorkoutDuration

public enum DurationBucket: String {
    case short, medium, long
}

public func calculateMedianWorkoutDuration(_ history: [WorkoutSession]) -> DurationBucket {
    guard history.count >= 5 else { return .medium }
    var durations: [Double] = []
    for s in history.prefix(20) {
        guard s.endTime > s.startTime else { continue }
        let mins = (s.endTime - s.startTime) / 60_000
        if mins > 10 && mins < 180 {
            durations.append(mins)
        }
    }
    guard !durations.isEmpty else { return .medium }
    durations.sort()
    let mid = durations.count / 2
    let median = durations.count % 2 != 0
        ? durations[mid]
        : (durations[mid - 1] + durations[mid]) / 2
    if median < 35 { return .short }
    if median > 65 { return .long }
    return .medium
}
