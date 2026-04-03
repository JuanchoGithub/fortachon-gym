import Foundation

// MARK: - getRecommendation

/// Port of `getWorkoutRecommendation` from recommendationUtils.ts.
/// Given user's workout history, routines, exercises, and profile,
/// returns a smart recommendation for today's training.
public func getRecommendation(
    history: [WorkoutSession],
    routines: [Routine],
    exercises: [Exercise],
    userGoal: UserGoal = .muscle
) -> Recommendation? {
    // Empty state: beginner onboarding
    if history.isEmpty && routines.isEmpty {
        return Recommendation(
            type: .rest,
            title: "Welcome to Fortachon",
            reason: "Set up your training profile to get personalized workout recommendations.",
            suggestedBodyParts: []
        )
    }
    // Empty state: history but no routines
    if routines.isEmpty {
        return Recommendation(
            type: .rest,
            title: "Setup Needed",
            reason: "Add some routines to get started with training.",
            suggestedBodyParts: []
        )
    }

    let inferredProfile = inferUserProfile(history, allExercises: exercises)
    let effectiveGoal: UserGoal
    switch userGoal {
    case .strength: effectiveGoal = .strength
    case .muscle: effectiveGoal = .muscle
    case .endurance: effectiveGoal = .endurance
    }
    let customRoutines = routines.filter { !$0.id.hasPrefix("rt-") }
    let isOnboarding = customRoutines.count > 0 && history.count < 15

    let sortedHistory = history.sorted { $0.startTime > $1.startTime }
    let lastSession = sortedHistory.first
    let now = Date().timeIntervalSince1970 * 1000
    let calendar = Calendar.current
    let todayStart = calendar.startOfDay(for: Date()).timeIntervalSince1970 * 1000
    let trainedToday = lastSession.map { $0.startTime >= todayStart } ?? false

    // If trained today: show recovery / active recovery
    if trainedToday, let last = lastSession {
        let volume = last.exercises.reduce(0.0) { acc, ex in
            acc + ex.sets.reduce(0.0) { sAcc, s in
                sAcc + (s.isComplete ? s.weight * Double(s.reps) : 0)
            }
        }
        return Recommendation(
            type: .activeRecovery,
            title: "Workout Complete",
            reason: String(format: "Volume: %.0f kg. Time to recover.", volume),
            suggestedBodyParts: [.mobility],
            systemicFatigue: (score: 0, level: "Low")
        )
    }

    // Systemic fatigue (CNS overload check)
    let fatigue = calculateSystemicFatigue(history: history, exercises: exercises)
    if fatigue.level == "High" {
        let mobilityRoutines = routines.filter { r in
            r.exercises.contains { ex in
                exercises.contains { $0.id == ex.exerciseId && $0.bodyPart == .mobility }
            }
        }
        return Recommendation(
            type: .deload,
            title: "CNS Fatigue Detected",
            reason: String(format: "Your CNS load is high (%d percent). Consider active recovery.", fatigue.score),
            suggestedBodyParts: [.mobility, .cardio],
            relevantRoutineIds: mobilityRoutines.map { $0.id },
            systemicFatigue: (score: Double(fatigue.score), level: fatigue.level)
        )
    }

    // Onboarding phase: suggest onboarding routines
    if isOnboarding, let lastId = lastSession?.routineId,
       let lastIdx = customRoutines.firstIndex(where: { $0.id == lastId }),
       customRoutines.count > 0 {
        let nextIdx = (lastIdx + 1) % customRoutines.count
        let nextRoutine = customRoutines[nextIdx]
        return Recommendation(
            type: .workout,
            title: String(format: "Next Up: %@", nextRoutine.name),
            reason: String(format: "Continue your onboarding plan with %@.", nextRoutine.name),
            suggestedBodyParts: [],
            relevantRoutineIds: [nextRoutine.id],
            systemicFatigue: (score: Double(fatigue.score), level: fatigue.level)
        )
    }

    if isOnboarding, let first = customRoutines.first {
        return Recommendation(
            type: .workout,
            title: String(format: "Start: %@", first.name),
            reason: "Begin your onboarding plan.",
            suggestedBodyParts: [],
            relevantRoutineIds: [first.id],
            systemicFatigue: (score: Double(fatigue.score), level: fatigue.level)
        )
    }

    // Standard: freshness-based recommendation
    let freshness = calculateMuscleFreshness(
        history: history, exercises: exercises, userGoal: effectiveGoal
    )

    let avgFreshness: Double
    if freshness.isEmpty {
        avgFreshness = 100
    } else {
        avgFreshness = freshness.values.reduce(0, +) / Double(freshness.count)
    }

    // Push / Pull / Legs freshness groups
    let pushMuscles = [MUSCLES.pectorals, MUSCLES.frontDelts, MUSCLES.triceps]
    let pullMuscles = [MUSCLES.lats, MUSCLES.traps, MUSCLES.biceps]
    let legMuscles = [MUSCLES.quads, MUSCLES.hamstrings, MUSCLES.glutes]

    struct GroupScore {
        let id: String
        let score: Double
        let daysSince: Int
        let bodyParts: [BodyPart]
        let focus: RoutineFocus
    }

    func groupScore(id: String, muscles: [String], bodyParts: [BodyPart], focus: RoutineFocus) -> GroupScore {
        let scores: [Double] = muscles.map { m in
            freshness[m] ?? 100.0
        }
        let avgS = scores.isEmpty ? 100.0 : scores.reduce(0, +) / Double(scores.count)

        var lastTrained: Double = 0
        for session in sortedHistory {
            var hit = false
            for ex in session.exercises {
                if let def = exercises.first(where: { $0.id == ex.exerciseId }) {
                    if let pm = def.primaryMuscles, muscles.contains(where: pm.contains) {
                        hit = true; break
                    }
                }
            }
            if hit {
                lastTrained = session.startTime
                break
            }
        }
        let daysSince: Int
        if lastTrained == 0 {
            daysSince = 999
        } else {
            let diff = (now - lastTrained) / (24 * 60 * 60 * 1000)
            daysSince = Int(diff)
        }

        return GroupScore(id: id, score: avgS, daysSince: daysSince, bodyParts: bodyParts, focus: focus)
    }

    let push = groupScore(id: "Push", muscles: pushMuscles, bodyParts: [.chest, .shoulders, .triceps], focus: .push)
    let pull = groupScore(id: "Pull", muscles: pullMuscles, bodyParts: [.back, .biceps], focus: .pull)
    let legs = groupScore(id: "Legs", muscles: legMuscles, bodyParts: [.legs, .glutes], focus: .legs)
    let fullBodyGroup = groupScore(id: "Full Body", muscles: pushMuscles + pullMuscles + legMuscles, bodyParts: [.fullBody], focus: .full_body)

    let groups = [push, pull, legs, fullBodyGroup]
    let readyGroups = groups.filter { $0.daysSince >= 2 && $0.score > 80 }

    if readyGroups.isEmpty {
        // All fatigued: suggest active recovery
        return Recommendation(
            type: .activeRecovery,
            title: "Active Recovery",
            reason: "Your muscles need recovery. Try light cardio or mobility work.",
            suggestedBodyParts: [.cardio, .mobility],
            systemicFatigue: (score: Double(fatigue.score), level: fatigue.level)
        )
    }

    // Pick the freshest group
    let winner = readyGroups.sorted { a, b in
        if b.daysSince - a.daysSince > 2 { return b.daysSince > a.daysSince }
        return a.score > b.score
    }.first!

    var title: String
    var reason: String
    switch winner.id {
    case "Push":
        title = "Push Day"
        reason = "Your chest and shoulders are fresh. Time to push!"
    case "Pull":
        title = "Pull Day"
        reason = "Your back and biceps are recovered. Let us pull!"
    case "Legs":
        title = "Leg Day"
        reason = "Your legs have recovered. Time to train!"
    default:
        title = "\(winner.id) Day"
        reason = "Time for \(winner.id.lowercased()) training."
    }

    // Find matching routines
    let scoredRoutines = routines.map { r -> (routine: Routine, score: Double) in
        let matchCount = r.exercises.filter { ex in
            guard let def = exercises.first(where: { $0.id == ex.exerciseId }) else { return false }
            return winner.bodyParts.contains(def.bodyPart)
        }.count
        let ratio = r.exercises.isEmpty ? 0 : Double(matchCount) / Double(r.exercises.count)
        var score = ratio * 20.0
        if r.name.lowercased().contains(winner.id.lowercased()) { score += 10 }
        if !r.id.hasPrefix("rt-") { score += 5 }
        if r.id == lastSession?.routineId { score -= 50 }
        return (r, score)
    }
    let validRoutines = scoredRoutines.filter { $0.score > 5 }.sorted { $0.score > $1.score }
    let relevantIds = validRoutines.prefix(3).map { $0.routine.id }

    // Generate a smart routine if we have no matching ones
    let generatedRoutine: Routine?
    if validRoutines.isEmpty {
        let settings = SurveyAnswers(
            experience: inferredProfile.experience, goal: effectiveGoal,
            equipment: inferredProfile.equipment, time: inferredProfile.time
        )
        let routine = generateSmartRoutine(focus: winner.focus, settings: settings)
        generatedRoutine = Routine(
            id: routine.id, name: "\(winner.id) — Smart",
            description: "Auto-generated by Fortachon Coach",
            exercises: routine.exercises, isTemplate: true,
            routineType: .strength
        )
    } else {
        generatedRoutine = nil
    }

    return Recommendation(
        type: .workout,
        title: title,
        reason: reason,
        suggestedBodyParts: winner.bodyParts,
        relevantRoutineIds: relevantIds,
        generatedRoutine: generatedRoutine,
        systemicFatigue: (score: Double(fatigue.score), level: fatigue.level)
    )
}

// MARK: - SupplementPlanItem

/// A supplement plan item for the supplement action card.
public struct SupplementPlanItem: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let supplement: String
    public let dosage: String
    public let time: String
    public let trainingDayOnly: Bool
    public let restDayOnly: Bool

    public init(id: String, supplement: String, dosage: String, time: String,
                trainingDayOnly: Bool = false, restDayOnly: Bool = false) {
        self.id = id; self.supplement = supplement; self.dosage = dosage
        self.time = time; self.trainingDayOnly = trainingDayOnly
        self.restDayOnly = restDayOnly
    }
}
