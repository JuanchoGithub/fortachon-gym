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
    public let notes: String
    public let isCustom: Bool
    public let trainingDayOnly: Bool
    public let restDayOnly: Bool
    public let stock: Int?

    public init(id: String, supplement: String, dosage: String, time: String,
                notes: String = "", isCustom: Bool = false,
                trainingDayOnly: Bool = false, restDayOnly: Bool = false,
                stock: Int? = nil) {
        self.id = id; self.supplement = supplement; self.dosage = dosage
        self.time = time; self.notes = notes; self.isCustom = isCustom
        self.trainingDayOnly = trainingDayOnly; self.restDayOnly = restDayOnly
        self.stock = stock
    }
}

// MARK: - SupplementInfo

/// User profile data for supplement plan generation.
public struct SupplementInfo: Codable, Sendable, Equatable {
    public let dob: String
    public let weight: Double
    public let height: Double
    public let gender: String
    public let activityLevel: String
    public let trainingDays: [String]
    public let trainingTime: String
    public let routineType: String
    public let objective: String
    public let proteinConsumption: Double?
    public let proteinUnknown: Bool
    public let deficiencies: [String]
    public let desiredSupplements: [String]
    public let allergies: [String]
    public let medicalConditions: String
    public let consumptionPreferences: String
    public let hydration: Double

    public init(dob: String, weight: Double, height: Double, gender: String,
                activityLevel: String, trainingDays: [String], trainingTime: String,
                routineType: String, objective: String, proteinConsumption: Double? = nil,
                proteinUnknown: Bool = false, deficiencies: [String] = [],
                desiredSupplements: [String] = [], allergies: [String] = [],
                medicalConditions: String = "", consumptionPreferences: String = "",
                hydration: Double = 2.0) {
        self.dob = dob; self.weight = weight; self.height = height
        self.gender = gender; self.activityLevel = activityLevel
        self.trainingDays = trainingDays; self.trainingTime = trainingTime
        self.routineType = routineType; self.objective = objective
        self.proteinConsumption = proteinConsumption; self.proteinUnknown = proteinUnknown
        self.deficiencies = deficiencies; self.desiredSupplements = desiredSupplements
        self.allergies = allergies; self.medicalConditions = medicalConditions
        self.consumptionPreferences = consumptionPreferences; self.hydration = hydration
    }
}

// MARK: - SupplementPlan

/// A complete supplement plan with user info and generated items.
public struct SupplementPlan: Codable, Sendable, Equatable {
    public let info: SupplementInfo
    public var plan: [SupplementPlanItem]
    public let warnings: [String]
    public let generalTips: [String]
    public let createdAt: TimeInterval

    public init(info: SupplementInfo, plan: [SupplementPlanItem],
                warnings: [String] = [], generalTips: [String] = [],
                createdAt: TimeInterval = Date().timeIntervalSince1970) {
        self.info = info; self.plan = plan; self.warnings = warnings
        self.generalTips = generalTips; self.createdAt = createdAt
    }
}

// MARK: - SupplementSuggestion

/// A suggestion to modify the supplement plan.
public struct SupplementSuggestion: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let reason: String
    public let action: SupplementSuggestionAction
    public let identifier: String

    public init(id: String, title: String, reason: String,
                action: SupplementSuggestionAction, identifier: String) {
        self.id = id; self.title = title; self.reason = reason
        self.action = action; self.identifier = identifier
    }
}

/// Action types for supplement suggestions.
public enum SupplementSuggestionAction: Codable, Sendable, Equatable {
    case add(item: SupplementPlanItem)
    case update(itemId: String, updates: SupplementPlanUpdates)
    case remove(itemId: String)
}

/// Updates to apply to an existing supplement item.
public struct SupplementPlanUpdates: Codable, Sendable, Equatable {
    public var time: String?
    public var dosage: String?
    public var notes: String?
    public var trainingDayOnly: Bool?
    public var restDayOnly: Bool?
    public var stock: Int?

    public init(time: String? = nil, dosage: String? = nil, notes: String? = nil,
                trainingDayOnly: Bool? = nil, restDayOnly: Bool? = nil, stock: Int? = nil) {
        self.time = time; self.dosage = dosage; self.notes = notes
        self.trainingDayOnly = trainingDayOnly; self.restDayOnly = restDayOnly
        self.stock = stock
    }
}

// MARK: - SupplementExplanation

/// Explanation for a supplement (what it does, why take it).
public struct SupplementExplanation: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let description: String
    public let benefits: [String]
    public let sideEffects: [String]
    public let dosage: String
    public let timing: String
    public let stackWith: [String]

    public init(id: String, name: String, category: String, description: String,
                benefits: [String] = [], sideEffects: [String] = [],
                dosage: String = "", timing: String = "", stackWith: [String] = []) {
        self.id = id; self.name = name; self.category = category
        self.description = description; self.benefits = benefits
        self.sideEffects = sideEffects; self.dosage = dosage
        self.timing = timing; self.stackWith = stackWith
    }
}

// MARK: - SupplementLibraryItem

/// A predefined supplement in the library.
public struct SupplementLibraryItem: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let key: String
    public let category: String
    public let descriptionKey: String
    public let defaultDose: String
    public let defaultTime: String
    public let benefits: [String]

    public init(id: String, key: String, category: String, descriptionKey: String,
                defaultDose: String, defaultTime: String, benefits: [String] = []) {
        self.id = id; self.key = key; self.category = category
        self.descriptionKey = descriptionKey; self.defaultDose = defaultDose
        self.defaultTime = defaultTime; self.benefits = benefits
    }
}
