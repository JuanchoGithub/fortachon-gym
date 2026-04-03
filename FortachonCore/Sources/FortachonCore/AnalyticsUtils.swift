import Foundation

// MARK: - HabitData

public struct HabitData: Sendable {
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

// MARK: - calculateMuscleFreshness

public func calculateMuscleFreshness(
    history: [WorkoutSession],
    exercises: [Exercise],
    userGoal: UserGoal
) -> [String: Double] {
    let recoveryTimes: [String: Double] = [
        MUSCLES.abs: 24, MUSCLES.forearms: 24,
        MUSCLES.calves: 48, MUSCLES.biceps: 48, MUSCLES.triceps: 48,
        MUSCLES.sideDelts: 48, MUSCLES.rearDelts: 48,
        MUSCLES.pectorals: 72,
        MUSCLES.lats: 72, MUSCLES.frontDelts: 60,
        MUSCLES.traps: 60,
        MUSCLES.quads: 96, MUSCLES.hamstrings: 96, MUSCLES.glutes: 96,
        MUSCLES.lowerBack: 96,
    ]
    let defaultRecoveryHours: Double = 72
    var capacityBaseline: Double = 15
    if userGoal == .strength { capacityBaseline = 10 }
    else if userGoal == .endurance { capacityBaseline = 20 }

    let now = Date().timeIntervalSince1970 * 1000
    let maxLookback = 6 * 24 * 60 * 60 * 1000.0
    let relevant = history.filter { (now - $0.startTime) < maxLookback }

    var muscleFatigue: [String: Double] = [:]

    for session in relevant {
        let hoursAgo = (now - session.startTime) / 3_600_000.0

        for ex in session.exercises {
            guard let def = exercises.first(where: { $0.id == ex.exerciseId }) else { continue }

            let stressUnits = ex.sets.reduce(0.0) { acc, set in
                guard set.isComplete else { return acc }
                var intensityMult: Double = 1.0
                if set.reps > 0 && set.reps <= 6 { intensityMult = 1.65 }
                else if set.reps > 12 { intensityMult = 0.8 }
                switch set.type {
                case .failure: intensityMult += 0.3
                case .drop: intensityMult += 0.1
                case .warmup: intensityMult = 0.5
                default: break
                }
                return acc + intensityMult
            }

            guard stressUnits > 0 else { continue }
            let appliedStress = stressUnits

            let primary = def.primaryMuscles ?? []
            let secondary = def.secondaryMuscles ?? []
            let allMs = primary + secondary
            for muscle in allMs {
                let recoveryDuration = recoveryTimes[muscle] ?? defaultRecoveryHours
                guard hoursAgo < recoveryDuration else { continue }
                let timeFactor = 1.0 - (hoursAgo / recoveryDuration)
                let weight = primary.contains(muscle) ? 1.0 : 0.5
                let fatigue = ((appliedStress * weight) / capacityBaseline) * 100.0 * timeFactor
                muscleFatigue[muscle, default: 0] += fatigue
            }
        }
    }

    var freshness: [String: Double] = [:]
    for (muscle, fatigue) in muscleFatigue {
        freshness[muscle] = max(0, min(100, round(100 - fatigue)))
    }
    return freshness
}

// MARK: - calculateSystemicFatigue

public func calculateSystemicFatigue(
    history: [WorkoutSession],
    exercises: [Exercise]
) -> (score: Int, level: String) {
    let now = Date().timeIntervalSince1970 * 1000
    let twoWeeks = 14 * 24 * 3600 * 1000.0
    let recent = history.filter { (now - $0.startTime) < twoWeeks }

    var fatiguePoints: Double = 0
    for session in recent {
        let daysAgo = (now - session.startTime) / (24 * 3600 * 1000.0)
        let decay = max(0, 1.0 - (daysAgo / 10.0))
        var sessionCost: Double = 5
        let sets = session.exercises.reduce(0) { acc, ex in
            acc + ex.sets.filter { $0.isComplete }.count
        }
        var compoundFactor = 0
        for ex in session.exercises {
            if let def = exercises.first(where: { $0.id == ex.exerciseId }) {
                let isCompound = ["Barbell", "Dumbbell"].contains(def.category.rawValue)
                    && ["Legs", "Back", "Chest"].contains(def.bodyPart.rawValue)
                if isCompound { compoundFactor += 1 }
            }
        }
        sessionCost += Double(sets) + Double(compoundFactor * 2)
        fatiguePoints += sessionCost * decay
    }

    let score = min(100, Int(round((fatiguePoints / 150.0) * 100)))
    let level: String
    if score > 60 { level = "High" }
    else if score > 30 { level = "Medium" }
    else { level = "Low" }
    return (score, level)
}
