import Foundation
import SwiftData

// MARK: - Exercise Model

@Model
public final class ExerciseM {
    public var id: String
    public var name: String
    public var bodyPartStr: String
    public var categoryStr: String
    public var notes: String?
    public var isTimed: Bool
    public var isUnilateral: Bool
    public var primaryMuscles: [String] = []
    public var secondaryMuscles: [String] = []
    // Extended fields for localization and instructions
    public var instructions: String
    public var exerciseNamesEN: String?
    public var exerciseNamesES: String?
    public var difficultyStr: String?
    public var updatedAt: Date?
    public var deletedAt: Date?
    public init(id: String, name: String, bodyPart: String, category: String,
                notes: String? = nil, isTimed: Bool = false, isUnilateral: Bool = false,
                primaryMuscles: [String] = [], secondaryMuscles: [String] = [],
                instructions: String = "", exerciseNamesEN: String? = nil,
                exerciseNamesES: String? = nil, difficulty: String? = nil,
                updatedAt: Date? = nil, deletedAt: Date? = nil) {
        self.id = id; self.name = name; self.bodyPartStr = bodyPart
        self.categoryStr = category; self.notes = notes
        self.isTimed = isTimed; self.isUnilateral = isUnilateral
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.instructions = instructions
        self.exerciseNamesEN = exerciseNamesEN
        self.exerciseNamesES = exerciseNamesES
        self.difficultyStr = difficulty
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

// MARK: - PerformedSet Model

@Model
public final class PerformedSetM {
    public var setId: String
    public var reps: Int
    public var weight: Double
    public var setTime: Int?
    public var setTypeStr: String
    public var isComplete: Bool
    public var completedAt: Date?
    public var restTime: Int?
    public var actualRestTime: Int?
    // Historical comparison fields
    public var historicalWeight: Double?
    public var historicalReps: Int?
    // Inheritance flags for supersets
    public var isWeightInherited: Bool
    public var isRepsInherited: Bool
    public var isTimeInherited: Bool
    // RPE (Rate of Perceived Exertion)
    public var rpe: Int?
    // Body weight at time of set
    public var storedBodyWeight: Double?
    // Cardio distance in km
    public var distance: Double?
    
    public init(id: String, reps: Int, weight: Double, time: Int? = nil,
                type: String, isComplete: Bool = false, completedAt: Date? = nil,
                rest: Int? = nil, actualRest: Int? = nil,
                historicalWeight: Double? = nil, historicalReps: Int? = nil,
                isWeightInherited: Bool = false, isRepsInherited: Bool = false,
                isTimeInherited: Bool = false, rpe: Int? = nil,
                storedBodyWeight: Double? = nil, distance: Double? = nil) {
        self.setId = id; self.reps = reps; self.weight = weight; setTime = time
        setTypeStr = type; self.isComplete = isComplete
        self.completedAt = completedAt; restTime = rest; actualRestTime = actualRest
        self.historicalWeight = historicalWeight
        self.historicalReps = historicalReps
        self.isWeightInherited = isWeightInherited
        self.isRepsInherited = isRepsInherited
        self.isTimeInherited = isTimeInherited
        self.rpe = rpe
        self.storedBodyWeight = storedBodyWeight
        self.distance = distance
    }
}

// MARK: - WorkoutExercise Model

@Model
public final class WorkoutExerciseM {
    public var weId: String
    public var exerciseId: String
    @Relationship(deleteRule: .cascade)
    public var sets: [PerformedSetM] = []
    public var restNormal: Int = 90
    public var restWarmup: Int = 60
    public var restDrop: Int = 30
    public var restTimed: Int = 10
    public var restEffort: Int = 90
    public var restFailure: Int = 300
    public var note: String?
    public var supersetId: String?
    // Bar/kettlebell weight
    public var barWeight: Double
    // Previous version storage (for rollback after exercise upgrade)
    public var prevExerciseId: String?
    public var prevSetsJson: String?
    public var prevNote: String?
    
    public init(id: String, exerciseId: String, restTime: RestTimes = RestTimes(),
                note: String? = nil, supersetId: String? = nil, barWeight: Double = 0) {
        self.weId = id; self.exerciseId = exerciseId
        restNormal = restTime.normal; restWarmup = restTime.warmup
        restDrop = restTime.drop; restTimed = restTime.timed
        restEffort = restTime.effort; restFailure = restTime.failure
        self.note = note; self.supersetId = supersetId
        self.barWeight = barWeight
    }
}

// MARK: - Superset Model

@Model
public final class SupersetM {
    public var ssId: String
    public var name: String
    public var color: String?
    public init(id: String, name: String, color: String? = nil) {
        self.ssId = id; self.name = name; self.color = color
    }
}

// MARK: - WorkoutSession Model

@Model
public final class WorkoutSessionM {
    public var wsId: String
    public var routineId: String
    public var routineName: String
    public var startTime: Date
    public var endTime: Date
    public var prCount: Int
    public var notes: String
    public var prAnnounced: Bool
    @Relationship(deleteRule: .cascade)
    public var exercises: [WorkoutExerciseM] = []
    @Relationship(deleteRule: .cascade)
    public var supersets: [SupersetM] = []
    public var updatedAt: Date
    public var deletedAt: Date?
    
    public init(id: String, routineId: String, routineName: String,
                startTime: Date, endTime: Date, prCount: Int = 0,
                notes: String = "", prAnnounced: Bool = false) {
        self.wsId = id; self.routineId = routineId; self.routineName = routineName
        self.startTime = startTime; self.endTime = endTime
        self.prCount = prCount; self.notes = notes; self.prAnnounced = prAnnounced
        self.updatedAt = Date()
    }
}

// MARK: - Routine Model

@Model
public final class RoutineM {
    public var rtId: String
    public var name: String
    public var desc: String
    public var isTemplate: Bool
    public var routineTypeStr: String
    public var tags: [String] = []
    @Relationship(deleteRule: .cascade)
    public var exercises: [WorkoutExerciseM] = []
    @Relationship(deleteRule: .cascade)
    public var supersets: [SupersetM] = []
    public var hiitWork: Int?
    public var hiitRest: Int?
    public var hiitPrep: Int?
    public var updatedAt: Date
    public var deletedAt: Date?
    public init(id: String, name: String, desc: String,
                isTemplate: Bool = false, type: String = "strength") {
        self.rtId = id; self.name = name; self.desc = desc
        self.isTemplate = isTemplate; routineTypeStr = type
        self.updatedAt = Date()
    }
}

// MARK: - Model → Struct Conversion

extension Exercise {
    public init(from m: ExerciseM) {
        // Parse instructions from JSON string array or use as plain text
        let instructions: [String]?
        if let data = m.instructions.data(using: .utf8),
           let parsed = try? JSONDecoder().decode([String].self, from: data) {
            instructions = parsed
        } else if !m.instructions.isEmpty {
            instructions = [m.instructions]
        } else {
            instructions = nil
        }

        // Parse difficulty
        let difficulty: ExerciseDifficulty?
        if let diffStr = m.difficultyStr {
            difficulty = ExerciseDifficulty(rawValue: diffStr)
        } else {
            difficulty = nil
        }

        self.init(id: m.id, name: m.name,
                  bodyPart: BodyPart(rawValue: m.bodyPartStr) ?? .fullBody,
                  category: ExerciseCategory(rawValue: m.categoryStr) ?? .bodyweight,
                  notes: m.notes, isTimed: m.isTimed,
                  isUnilateral: m.isUnilateral,
                  primaryMuscles: m.primaryMuscles,
                  secondaryMuscles: m.secondaryMuscles,
                  instructions: instructions,
                  exerciseNamesEN: m.exerciseNamesEN,
                  exerciseNamesES: m.exerciseNamesES,
                  difficulty: difficulty,
                  updatedAt: m.updatedAt?.timeIntervalSince1970,
                  deletedAt: m.deletedAt?.timeIntervalSince1970)
    }
}

extension PerformedSet {
    public init(from m: PerformedSetM) {
        self.init(id: m.setId, reps: m.reps, weight: m.weight,
                  time: m.setTime,
                  type: SetType(rawValue: m.setTypeStr) ?? .normal,
                  isComplete: m.isComplete,
                  completedAt: m.completedAt?.timeIntervalSince1970,
                  rest: m.restTime,
                  isWeightInherited: m.isWeightInherited,
                  isRepsInherited: m.isRepsInherited,
                  isTimeInherited: m.isTimeInherited,
                  actualRest: m.actualRestTime,
                  historicalWeight: m.historicalWeight,
                  historicalReps: m.historicalReps,
                  storedBodyWeight: m.storedBodyWeight,
                  rpe: m.rpe,
                  distance: m.distance)
    }
}

extension WorkoutExercise {
    public init(from m: WorkoutExerciseM) {
        let sets = m.sets.map { PerformedSet(from: $0) }
        let rt = RestTimes(normal: m.restNormal, warmup: m.restWarmup,
                           drop: m.restDrop, timed: m.restTimed,
                           effort: m.restEffort, failure: m.restFailure)
        self.init(id: m.weId, exerciseId: m.exerciseId, sets: sets,
                  restTime: rt, note: m.note, barWeight: m.barWeight,
                  supersetId: m.supersetId)
    }
}

extension WorkoutSession {
    public init(from m: WorkoutSessionM) {
        let exercises = m.exercises.map { WorkoutExercise(from: $0) }
        self.init(id: m.wsId, routineId: m.routineId,
                  routineName: m.routineName,
                  startTime: m.startTime.timeIntervalSince1970 * 1000,
                  endTime: m.endTime.timeIntervalSince1970 * 1000,
                  exercises: exercises, prCount: m.prCount,
                  deletedAt: m.deletedAt?.timeIntervalSince1970)
    }
}

extension Routine {
    public init(from m: RoutineM) {
        let exercises = m.exercises.map { WorkoutExercise(from: $0) }
        let hiit: HiitConfig?
        if let w = m.hiitWork, let r = m.hiitRest {
            hiit = HiitConfig(workTime: w, restTime: r, prepareTime: m.hiitPrep)
        } else { hiit = nil }
        self.init(id: m.rtId, name: m.name, description: m.desc,
                  exercises: exercises, isTemplate: m.isTemplate,
                  routineType: RoutineType(rawValue: m.routineTypeStr) ?? .strength,
                  hiitConfig: hiit, tags: m.tags)
    }
}

// MARK: - UserPreferences Model

@Model
public final class UserPreferencesM {
    public var id: UUID
    public var weightUnitStr: String
    public var mainGoalStr: String
    public var hasCompletedOnboarding: Bool
    public var lastCheckInDate: Date?
    public var lastCheckInReason: String?
    // Profile fields
    public var gender: String?
    public var heightCm: Double?
    // App behavior settings
    public var fontSize: String = "normal"
    public var smartGoalDetection: Bool = true
    public var bioAdaptiveEngine: Bool = true
    public var localizedExerciseNames: Bool = false
    public var notificationsEnabled: Bool = false
    public var selectedVoiceURI: String?
    // Rest timer defaults
    public var restNormal: Int = 90
    public var restWarmup: Int = 60
    public var restDrop: Int = 30
    public var restTimed: Int = 10
    public var restEffort: Int = 90
    public var restFailure: Int = 300
    // Audio coach
    public var audioCoachEnabled: Bool = true
    // Promotion snoozes
    public var promotionSnoozes: String = "{}"
    // Auto-updated 1RMs
    public var autoUpdated1RMs: String = "{}"
    // History chart configs (JSON)
    public var historyChartConfigs: String = "[]"
    @Relationship
    public var activeSupplements: [SupplementLogM] = []
    public init(id: UUID = UUID(), weightUnit: String = "kg", goal: String = "muscle",
                hasCompletedOnboarding: Bool = false, lastCheckInDate: Date? = nil,
                lastCheckInReason: String? = nil, gender: String? = nil,
                heightCm: Double? = nil, fontSize: String = "normal",
                smartGoalDetection: Bool = true, bioAdaptiveEngine: Bool = true,
                localizedExerciseNames: Bool = false, notificationsEnabled: Bool = false,
                selectedVoiceURI: String? = nil, restNormal: Int = 90, restWarmup: Int = 60,
                restDrop: Int = 30, restTimed: Int = 10, restEffort: Int = 90, restFailure: Int = 300,
                audioCoachEnabled: Bool = true, promotionSnoozes: String = "{}",
                autoUpdated1RMs: String = "{}", historyChartConfigs: String = "[]") {
        self.id = id; weightUnitStr = weightUnit; mainGoalStr = goal
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.lastCheckInDate = lastCheckInDate
        self.lastCheckInReason = lastCheckInReason
        self.gender = gender; self.heightCm = heightCm
        self.fontSize = fontSize; self.smartGoalDetection = smartGoalDetection
        self.bioAdaptiveEngine = bioAdaptiveEngine
        self.localizedExerciseNames = localizedExerciseNames
        self.notificationsEnabled = notificationsEnabled
        self.selectedVoiceURI = selectedVoiceURI
        self.restNormal = restNormal; self.restWarmup = restWarmup
        self.restDrop = restDrop; self.restTimed = restTimed
        self.restEffort = restEffort; self.restFailure = restFailure
        self.audioCoachEnabled = audioCoachEnabled
    }
    public var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitStr) ?? .kg }
    public var mainGoal: UserGoal { UserGoal(rawValue: mainGoalStr) ?? .muscle }
}

// MARK: - WeightEntry Model

@Model
public final class WeightEntryM {
    public var id: UUID
    public var weight: Double
    public var date: Date
    
    public init(id: UUID = UUID(), weight: Double, date: Date = Date()) {
        self.id = id
        self.weight = weight
        self.date = date
    }
}

// MARK: - SupplementLog Model

@Model
public final class SupplementLogM {
    public var id: UUID
    public var name: String
    public var dosage: String
    public var timingStr: String
    public var notes: String
    public var isSnoozed: Bool
    public var snoozedUntil: Date?
    public var takenDate: Date?
    public var stock: Int
    public var isCustom: Bool
    public var trainingDayOnly: Bool
    public var restDayOnly: Bool
    public var planId: String?
    public var takenHistory: [Date]
    
    public init(id: UUID = UUID(), name: String, dosage: String = "", timing: String = "daily",
                notes: String = "", isSnoozed: Bool = false, snoozedUntil: Date? = nil,
                takenDate: Date? = nil, stock: Int = 30, isCustom: Bool = true,
                trainingDayOnly: Bool = false, restDayOnly: Bool = false,
                planId: String? = nil, takenHistory: [Date] = []) {
        self.id = id; self.name = name; self.dosage = dosage
        timingStr = timing; self.notes = notes; self.isSnoozed = isSnoozed
        self.snoozedUntil = snoozedUntil; self.takenDate = takenDate
        self.stock = stock; self.isCustom = isCustom
        self.trainingDayOnly = trainingDayOnly; self.restDayOnly = restDayOnly
        self.planId = planId; self.takenHistory = takenHistory
    }
}

// MARK: - ExerciseM Helpers

extension ExerciseM {
    /// Returns the localized exercise name based on user preferences
    /// - Parameter useSpanish: Whether to use Spanish names
    /// - Returns: Localized exercise name
    public func displayName(useSpanish: Bool) -> String {
        if useSpanish {
            return localizedExerciseName(for: id, locale: "es", defaultName: name)
        }
        return name
    }
    
    /// Parses instructions from JSON string array
    public var instructionsAsSteps: [String]? {
        guard !instructions.isEmpty else { return nil }
        if let data = instructions.data(using: .utf8),
           let parsed = try? JSONDecoder().decode([String].self, from: data) {
            return parsed
        }
        return [instructions]
    }
}

// MARK: - ModelContainer Factory

public func makeInMemoryContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: ExerciseM.self, PerformedSetM.self,
                              WorkoutExerciseM.self, SupersetM.self,
                              WorkoutSessionM.self, RoutineM.self,
                              UserPreferencesM.self, SupplementLogM.self,
                              configurations: config)
}