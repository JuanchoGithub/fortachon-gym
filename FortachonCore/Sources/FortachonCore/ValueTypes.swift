import Foundation

// MARK: - RestTimes

public struct RestTimes: Codable, Sendable {
    public var normal, warmup, drop, timed, effort, failure: Int
    public init(normal: Int = 90, warmup: Int = 60, drop: Int = 30,
                timed: Int = 10, effort: Int = 90, failure: Int = 300) {
        self.normal = normal; self.warmup = warmup; self.drop = drop
        self.timed = timed; self.effort = effort; self.failure = failure
    }
}

// MARK: - PreviousVersion

public struct PreviousVersion: Codable, Sendable {
    public let exerciseId: String
    public let sets: [PerformedSet]
    public let note: String?
}

// MARK: - Exercise

public struct Exercise: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let bodyPart: BodyPart
    public let category: ExerciseCategory
    public let notes: String?
    public let isTimed: Bool?
    public let isUnilateral: Bool?
    public let primaryMuscles: [String]?
    public let secondaryMuscles: [String]?
    // Extended fields for localization and instructions
    public let instructions: [String]?
    public let exerciseNamesEN: String?
    public let exerciseNamesES: String?
    public let difficulty: ExerciseDifficulty?
    public let updatedAt: Double?
    public let deletedAt: Double?

    public init(id: String, name: String, bodyPart: BodyPart, category: ExerciseCategory,
                notes: String? = nil, isTimed: Bool? = nil, isUnilateral: Bool? = nil,
                primaryMuscles: [String]? = nil, secondaryMuscles: [String]? = nil,
                instructions: [String]? = nil, exerciseNamesEN: String? = nil,
                exerciseNamesES: String? = nil, difficulty: ExerciseDifficulty? = nil,
                updatedAt: Double? = nil, deletedAt: Double? = nil) {
        self.id = id; self.name = name; self.bodyPart = bodyPart
        self.category = category; self.notes = notes
        self.isTimed = isTimed; self.isUnilateral = isUnilateral
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.instructions = instructions
        self.exerciseNamesEN = exerciseNamesEN
        self.exerciseNamesES = exerciseNamesES
        self.difficulty = difficulty
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

// MARK: - ExerciseDifficulty

public enum ExerciseDifficulty: String, Codable, CaseIterable, Sendable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    /// Display name for the difficulty level
    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

// MARK: - PerformedSet

public struct PerformedSet: Codable, Identifiable, Sendable {
    public let id: String
    public var reps: Int
    public var weight: Double
    public let time: Int?
    public let type: SetType
    public let isComplete: Bool
    public let completedAt: Double?
    public let rest: Int?
    public let isWeightInherited: Bool?
    public let isRepsInherited: Bool?
    public let isTimeInherited: Bool?
    public let actualRest: Int?
    public let historicalWeight: Double?
    public let historicalReps: Int?
    public let historicalTime: Int?
    public let storedBodyWeight: Double?
    // RPE (Rate of Perceived Exertion) 1-10
    public let rpe: Int?
    // Cardio distance in km
    public let distance: Double?

    public init(id: String, reps: Int, weight: Double, time: Int? = nil,
                type: SetType, isComplete: Bool = false, completedAt: Double? = nil,
                rest: Int? = nil, isWeightInherited: Bool? = nil,
                isRepsInherited: Bool? = nil, isTimeInherited: Bool? = nil,
                actualRest: Int? = nil, historicalWeight: Double? = nil,
                historicalReps: Int? = nil, historicalTime: Int? = nil,
                storedBodyWeight: Double? = nil, rpe: Int? = nil,
                distance: Double? = nil) {
        self.id = id; self.reps = reps; self.weight = weight; self.time = time
        self.type = type; self.isComplete = isComplete; self.completedAt = completedAt
        self.rest = rest; self.isWeightInherited = isWeightInherited
        self.isRepsInherited = isRepsInherited
        self.isTimeInherited = isTimeInherited; self.actualRest = actualRest
        self.historicalWeight = historicalWeight
        self.historicalReps = historicalReps
        self.historicalTime = historicalTime
        self.storedBodyWeight = storedBodyWeight
        self.rpe = rpe
        self.distance = distance
    }
}

// MARK: - SupersetDefinition

public struct SupersetDefinition: Codable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public var color: String?
    public init(id: String, name: String, color: String? = nil) {
        self.id = id; self.name = name; self.color = color
    }
}

// MARK: - WorkoutExercise

public struct WorkoutExercise: Codable, Identifiable, Sendable {
    public let id: String
    public let exerciseId: String
    public var sets: [PerformedSet]
    public let restTime: RestTimes
    public let note: String?
    public let barWeight: Double?
    public let supersetId: String?
    public let previousVersion: PreviousVersion?

    public init(id: String, exerciseId: String, sets: [PerformedSet],
                restTime: RestTimes, note: String? = nil, barWeight: Double? = nil,
                supersetId: String? = nil, previousVersion: PreviousVersion? = nil) {
        self.id = id; self.exerciseId = exerciseId; self.sets = sets
        self.restTime = restTime; self.note = note; self.barWeight = barWeight
        self.supersetId = supersetId; self.previousVersion = previousVersion
    }
}

// MARK: - findBestSet

public func findBestSet(_ sets: [PerformedSet]) -> PerformedSet? {
    let normal = sets.filter { $0.type == .normal }
    guard !normal.isEmpty else { return nil }
    return normal.max { a, b in
        calculate1RM(weight: a.weight, reps: a.reps) <
        calculate1RM(weight: b.weight, reps: b.reps)
    }
}

// MARK: - getTimerDuration

public func getTimerDuration(set: PerformedSet, workoutExercise: WorkoutExercise, setIndex: Int) -> Int {
    if let rest = set.rest { return rest }
    let rt = workoutExercise.restTime
    var dur: Int
    switch set.type {
    case .warmup:  dur = rt.warmup
    case .drop:    dur = rt.drop
    case .timed:   dur = rt.timed
    case .failure: dur = rt.failure
    default:       dur = rt.normal
    }
    let isLast = setIndex == workoutExercise.sets.count - 1
    let isLastWarmup = set.type == .warmup
        && setIndex < workoutExercise.sets.count - 1
        && workoutExercise.sets[setIndex + 1].type != .warmup
    if isLast || isLastWarmup { dur *= 2 }
    return dur
}

// MARK: - groupExercises

public enum GroupedExerciseItem: Sendable {
    case single(WorkoutExercise, index: Int)
    case superset([WorkoutExercise], id: String, definition: SupersetDefinition?, indices: [Int])
}

public func groupExercises(_ exercises: [WorkoutExercise], supersets: [String: SupersetDefinition]? = nil) -> [GroupedExerciseItem] {
    var result: [GroupedExerciseItem] = []
    var group: [WorkoutExercise] = []
    var gId: String?
    var gIdx: [Int] = []
    func flush() {
        if let id = gId, !group.isEmpty {
            result.append(.superset(group, id: id, definition: supersets?[id], indices: gIdx))
            group = []; gIdx = []; gId = nil
        }
    }
    for (i, ex) in exercises.enumerated() {
        if let sid = ex.supersetId {
            if let cid = gId, cid != sid { flush() }
            group.append(ex); gIdx.append(i); gId = sid
        } else {
            flush()
            result.append(.single(ex, index: i))
        }
    }
    flush()
    return result
}
