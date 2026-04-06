import Foundation

// MARK: - WeightSuggestion

public struct WeightSuggestion: Sendable {
    public let weight: Double
    public let reps: Int?
    public let sets: Int?
    public let reason: String
    public let actionKey: String?
    public let params: [String: String]?
    public let trend: WeightTrend

    public init(weight: Double, reps: Int? = nil, sets: Int? = nil,
                reason: String, actionKey: String? = nil,
                params: [String: String]? = nil, trend: WeightTrend) {
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.reason = reason
        self.actionKey = actionKey
        self.params = params
        self.trend = trend
    }
}

// MARK: - WeightTrend

public enum WeightTrend: String, Sendable {
    case increase, decrease, maintain
}

// MARK: - getSmartWeightSuggestion

/// Calculates a smart starting weight suggestion for an exercise.
/// Port of `getSmartWeightSuggestion` from analyticsService.ts with 90% for strength goal.
public func getSmartWeightSuggestion(
    exerciseId: String,
    history: [WorkoutSession],
    profile: StrengthProfile?,
    allExercises: [Exercise],
    goal: UserGoal = .muscle
) -> WeightSuggestion {
    // First, check if there's direct history for this exercise
    let exHistory = getExerciseHistory(history, exerciseId: exerciseId)

    if let lastEntry = exHistory.first {
        let lastSets = lastEntry.sets.filter { $0.type == .normal && $0.isComplete && $0.weight > 0 }
        if let lastWeight = lastSets.max(by: { $0.weight < $1.weight })?.weight {
            // Has previous data for this exercise - use recent performance
            let increment = detectPreferredIncrement(from: exHistory)

            let daysSince = (Date().timeIntervalSince1970 * 1000 - lastEntry.session.startTime) / (1000 * 60 * 60 * 24)

            // Deload if returning after 14+ day break
            if daysSince > 14 {
                let deloadWeight = round((lastWeight * 0.9) / increment) * increment
                return WeightSuggestion(
                    weight: deloadWeight,
                    reps: lastSets.first?.reps,
                    sets: lastSets.count,
                    reason: "insight_reason_rust",
                    trend: .decrease
                )
            }

            // Standard: suggest same weight or slight progression
            return WeightSuggestion(
                weight: lastWeight,
                reps: lastSets.first?.reps,
                sets: lastSets.count,
                reason: "insight_reason_maintain",
                trend: .maintain
            )
        }
    }

    // No direct history - use inferred 1RM from strength profile
    if let profile = profile,
       let exercise = allExercises.first(where: { $0.id == exerciseId }),
       let result = getInferredMax(exercise, profile: profile) {
        // KEY CHANGE: 90% for strength (was 80% in web version)
        let percentage: Double
        switch goal {
        case .strength:
            percentage = 0.9  // Changed from 0.8 to 0.9
        case .muscle:
            percentage = 0.7
        case .endurance:
            percentage = 0.6
        }

        let targetWeight = round((result * percentage) / 2.5) * 2.5
        return WeightSuggestion(
            weight: targetWeight,
            reason: "insight_reason_new",
            trend: .increase
        )
    }

    // No data at all
    return WeightSuggestion(
        weight: 0,
        reason: "",
        trend: .maintain
    )
}

// MARK: - getSmartStartingWeight

/// Convenience method that returns just the weight value.
public func getSmartStartingWeight(
    exerciseId: String,
    history: [WorkoutSession],
    profile: StrengthProfile?,
    allExercises: [Exercise],
    goal: UserGoal = .muscle
) -> Double {
    let suggestion = getSmartWeightSuggestion(
        exerciseId: exerciseId,
        history: history,
        profile: profile,
        allExercises: allExercises,
        goal: goal
    )
    return suggestion.weight
}

// MARK: - detectPreferredIncrement

/// Detects the preferred weight increment from exercise history.
public func detectPreferredIncrement(from history: [(session: WorkoutSession, sets: [PerformedSet])]) -> Double {
    var weightDeltas: [Double] = []
    var lastWeight: Double? = nil

    for entry in history.prefix(10) {
        for set in entry.sets where set.weight > 0 {
            if let last = lastWeight, set.weight != last {
                weightDeltas.append(abs(set.weight - last))
            }
            lastWeight = set.weight
        }
    }

    guard !weightDeltas.isEmpty else { return 2.5 }

    // Find the most common increment (mode)
    let roundedDeltas = weightDeltas.map { round($0 * 10) / 10 }
    var counts: [Double: Int] = [:]
    for delta in roundedDeltas {
        counts[delta, default: 0] += 1
    }

    let mostCommon = counts.max(by: { $0.value < $1.value })?.key ?? 2.5

    // Sanitize to common increments
    if mostCommon >= 4.5 { return 5.0 }
    if mostCommon >= 2.2 { return 2.5 }
    if mostCommon >= 1.0 { return 1.25 }
    return 2.5
}

// MARK: - getExerciseHistory (for new history format)

/// Gets exercise history sorted by session start time (most recent first).
private func getExerciseHistory(
    _ sessions: [WorkoutSession],
    exerciseId: String
) -> [(session: WorkoutSession, sets: [PerformedSet])] {
    var entries: [(WorkoutSession, [PerformedSet])] = []

    let sortedSessions = sessions.sorted { $0.startTime > $1.startTime }

    for session in sortedSessions {
        for ex in session.exercises where ex.exerciseId == exerciseId {
            entries.append((session, ex.sets))
            break  // One entry per session
        }
    }

    return entries
}