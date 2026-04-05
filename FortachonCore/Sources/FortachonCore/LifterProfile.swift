import Foundation

// MARK: - calculateLifterDNA (Deprecated - use WorkoutAnalytics version)

// This function is deprecated. Use calculateLifterDNA(history:currentBodyWeight:) from WorkoutAnalytics.swift instead.
// The function signature below is kept for backward compatibility but redirects to the new implementation.

@available(*, deprecated, message: "Use calculateLifterDNA(history:currentBodyWeight:) from WorkoutAnalytics.swift")
public func calculateLifterDNA(_ history: [WorkoutSession], allExercises: [Exercise] = []) -> LifterStats {
    if history.isEmpty {
        return LifterStats(
            consistencyScore: 0, volumeScore: 0, intensityScore: 0,
            experienceLevel: 0, archetype: .beginner, favMuscle: "N/A",
            efficiencyScore: 0, rawConsistency: 0, rawVolume: 0, rawIntensity: 0)
    }
    if history.count < 5 {
        let totalVol = history.reduce(0) { acc, s in
            let sVol = s.exercises.reduce(0) { ae, ex in
                let eVol = ex.sets.reduce(0) { se, st in
                    se + (st.isComplete ? st.weight * Double(st.reps) : 0)
                }
                return ae + eVol
            }
            return acc + Int(sVol)
        }
        return LifterStats(
            consistencyScore: 0, volumeScore: 0, intensityScore: 0,
            experienceLevel: 0, archetype: .beginner, favMuscle: "N/A",
            efficiencyScore: 0, rawConsistency: 0, rawVolume: Int(totalVol), rawIntensity: 0)
    }

    let now = Date().timeIntervalSince1970 * 1000
    let last30 = history.filter { now - Double($0.startTime) < 30 * 86400 * 1000 }
    let consistency = min(100, round(Double(last30.count / 12 * 100)))

    let top20 = Array(history.prefix(20))
    var volCount: [String: Int] = [:]
    var totalVol = 0.0, totalReps = 0.0, setCount = 0
    let barbellParts = Set(["Chest", "Back", "Legs", "Shoulders"])
    let barbellCats = Set(["Barbell", "Dumbbell"])
    var compoundVol = 0.0, compoundReps = 0.0

    for s in top20 {
        for ex in s.exercises {
            let def = allExercises.first { $0.id == ex.exerciseId }
            for set in ex.sets where set.isComplete {
                let v = set.weight * Double(set.reps)
                totalVol += v; totalReps += Double(set.reps); setCount += 1
                let bp = def?.bodyPart.rawValue ?? "Full Body"
                volCount[bp, default: 0] += 1
                let cat = def?.category.rawValue ?? ""
                if barbellCats.contains(cat) && barbellParts.contains(bp) {
                    compoundVol += v; compoundReps += Double(set.reps)
                }
            }
        }
    }
    let avgRepsPerSet = setCount > 0 ? totalReps / Double(setCount) : 0
    let compoundAvg = compoundVol > 0 ? compoundReps / (compoundVol / max(avgRepsPerSet, 1)) : 0
    let avgR = compoundAvg > 0 ? compoundAvg : avgRepsPerSet
    var archetype: LifterArchetype = .hybrid
    if avgR <= 6.5 { archetype = .powerbuilder }
    else if avgR <= 12 { archetype = .bodybuilder }
    else if avgR > 13 { archetype = .endurance }

    let avgVol = totalVol / Double(top20.count)
    var favMuscle = "Full Body", maxC = 0
    for (bp, c) in volCount { if c > maxC { maxC = c; favMuscle = bp } }

    var eff: Double = 100
    let densities = top20.map { calculateSessionDensity($0) }.filter { $0 > 0 }
    if densities.count >= 4 {
        let d0 = densities[0]
        let davg = densities.dropFirst(1).prefix(3).reduce(0, +) / 3
        if davg > 0 { eff = min(100, round(d0 / davg * 100)) }
    }

    return LifterStats(
        consistencyScore: Int(consistency),
        volumeScore: min(100, Int(avgVol / 10000 * 100)),
        intensityScore: avgRepsPerSet <= 5 ? 95 : avgRepsPerSet <= 8 ? 85 : avgRepsPerSet <= 12 ? 75 : avgRepsPerSet <= 15 ? 60 : 40,
        experienceLevel: history.count,
        archetype: archetype,
        favMuscle: favMuscle,
        efficiencyScore: Int(eff),
        rawConsistency: last30.count,
        rawVolume: Int(avgVol),
        rawIntensity: round(avgRepsPerSet * 10) / 10)
}

// MARK: - inferUserProfile

public func inferUserProfile(
    _ history: [WorkoutSession], allExercises: [Exercise] = []
) -> SurveyAnswers {
    guard !history.isEmpty else {
        return SurveyAnswers(experience: .intermediate, goal: .muscle, equipment: .gym, time: .medium)
    }
    let top10 = Array(history.prefix(10))
    var bb = 0, db = 0, mc = 0, bw = 0, total = 0
    var totalReps = 0, setCount = 0

    for s in top10 {
        for ex in s.exercises {
            if let def = allExercises.first(where: { $0.id == ex.exerciseId }) {
                total += 1
                switch def.category {
                case .barbell: bb += 1
                case .dumbbell: db += 1
                case .machine, .cable: mc += 1
                case .bodyweight, .assistedBodyweight: bw += 1
                default: break
                }
            }
            for set in ex.sets where set.isComplete {
                totalReps += set.reps; setCount += 1
            }
        }
    }
    var equipment: EquipmentType = .gym
    if total > 0 {
        if Double(bb) / Double(total) > 0.3 || Double(mc) / Double(total) > 0.3 { equipment = .gym }
        else if Double(db) / Double(total) > 0.4 { equipment = .dumbbell }
        else if Double(bw) / Double(total) > 0.5 { equipment = .bodyweight }
    }
    let avgReps = setCount > 0 ? Double(totalReps) / Double(setCount) : 10
    var goal: UserGoal = .muscle
    if avgReps < 6 { goal = .strength }
    else if avgReps > 12 { goal = .endurance }
    let dur = calculateMedianWorkoutDuration(history)
    let time: TimePreference
    switch dur { case .short: time = .short; case .medium: time = .medium; case .long: time = .long }
    let exp: RoutineLevel
    if history.count < 20 { exp = .beginner }
    else if history.count < 100 { exp = .intermediate }
    else { exp = .advanced }

    return SurveyAnswers(experience: exp, goal: goal, equipment: equipment, time: time)
}
