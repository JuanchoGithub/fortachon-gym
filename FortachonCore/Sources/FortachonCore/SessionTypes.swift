import Foundation

// MARK: - RoutineType

public enum RoutineType: String, Codable, CaseIterable, Sendable {
    case strength = "strength"
    case hiit = "hiit"
}

// MARK: - HiitConfig

public struct HiitConfig: Codable, Sendable {
    public let workTime: Int
    public let restTime: Int
    public let prepareTime: Int?
    public init(workTime: Int, restTime: Int, prepareTime: Int? = nil) {
        self.workTime = workTime; self.restTime = restTime
        self.prepareTime = prepareTime
    }
}

// MARK: - WorkoutSession

public struct WorkoutSession: Codable, Identifiable, Sendable {
    public let id: String
    public let routineId: String
    public let routineName: String
    public let startTime: Double
    public let endTime: Double
    public let lastUpdated: Double?
    public var exercises: [WorkoutExercise]
    public let supersets: [String: SupersetDefinition]?
    public let prCount: Int?
    public let updatedAt: Double?
    public let deletedAt: Double?

    public init(id: String, routineId: String, routineName: String,
                startTime: Double, endTime: Double, lastUpdated: Double? = nil,
                exercises: [WorkoutExercise], supersets: [String: SupersetDefinition]? = nil,
                prCount: Int? = nil, updatedAt: Double? = nil, deletedAt: Double? = nil) {
        self.id = id; self.routineId = routineId; self.routineName = routineName
        self.startTime = startTime; self.endTime = endTime; self.lastUpdated = lastUpdated
        self.exercises = exercises; self.supersets = supersets
        self.prCount = prCount; self.updatedAt = updatedAt; self.deletedAt = deletedAt
    }
}

// MARK: - Routine

public struct Routine: Codable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public var description: String
    public var exercises: [WorkoutExercise]
    public let supersets: [String: SupersetDefinition]?
    public var isTemplate: Bool
    public let lastUsed: Double?
    public let originId: String?
    public let routineType: RoutineType
    public let hiitConfig: HiitConfig?
    public var tags: [String]
    public let updatedAt: Double?
    public let deletedAt: Double?

    public init(id: String, name: String, description: String,
                exercises: [WorkoutExercise], supersets: [String: SupersetDefinition]? = nil,
                isTemplate: Bool = false, lastUsed: Double? = nil, originId: String? = nil,
                routineType: RoutineType = .strength, hiitConfig: HiitConfig? = nil,
                tags: [String] = [], updatedAt: Double? = nil, deletedAt: Double? = nil) {
        self.id = id; self.name = name; self.description = description
        self.exercises = exercises; self.supersets = supersets
        self.isTemplate = isTemplate; self.lastUsed = lastUsed; self.originId = originId
        self.routineType = routineType; self.hiitConfig = hiitConfig
        self.tags = tags; self.updatedAt = updatedAt; self.deletedAt = deletedAt
    }
}

// MARK: - calculateRecords

public struct RecordEntry: Sendable {
    public let value: Double
    public let set: PerformedSet
    public let session: WorkoutSession
}

public struct PersonalRecords: Sendable {
    public let maxWeight: RecordEntry?
    public let maxReps: RecordEntry?
    public let maxVolume: RecordEntry?
}

public func calculateRecords(_ history: [(session: WorkoutSession, sets: [PerformedSet])]) -> PersonalRecords {
    var maxW: (Double, PerformedSet, WorkoutSession)?
    var maxR: (Double, PerformedSet, WorkoutSession)?
    var maxV: (Double, PerformedSet, WorkoutSession)?
    for (session, sets) in history {
        for set in sets where set.type == .normal {
            if maxW == nil || set.weight > maxW!.0 { maxW = (set.weight, set, session) }
            if maxR == nil || Double(set.reps) > maxR!.0 { maxR = (Double(set.reps), set, session) }
            let vol = set.weight * Double(set.reps)
            if maxV == nil || vol > maxV!.0 { maxV = (vol, set, session) }
        }
    }
    let mk: ((Double, PerformedSet, WorkoutSession) -> RecordEntry) = { v, s, sess in
        RecordEntry(value: v, set: s, session: sess)
    }
    return PersonalRecords(
        maxWeight: maxW.map(mk), maxReps: maxR.map(mk), maxVolume: maxV.map(mk)
    )
}

// MARK: - generate1RMProtocol

public enum ProtocolStepType: String, Codable, Sendable {
    case warmup, attempt
}

public struct ProtocolStep: Codable, Sendable {
    public let reps: Int
    public let percentage: Double
    public let rest: Int
    public let type: ProtocolStepType
    public init(reps: Int, percentage: Double, rest: Int, type: ProtocolStepType) {
        self.reps = reps; self.percentage = percentage
        self.rest = rest; self.type = type
    }
}

public func generate1RMProtocol(target1RM: Int) -> [ProtocolStep] {
    [
        ProtocolStep(reps: 10, percentage: 0.5, rest: 60, type: .warmup),
        ProtocolStep(reps: 5, percentage: 0.75, rest: 120, type: .warmup),
        ProtocolStep(reps: 1, percentage: 0.9, rest: 180, type: .warmup),
        ProtocolStep(reps: 1, percentage: 1.0, rest: 300, type: .attempt),
    ]
}

// MARK: - calculateWarmupWeights

public func calculateWarmupWeights(workingWeight: Double, count: Int, increment: Double = 2.5) -> [Double] {
    let rnd: (Double) -> Double = { w in
        increment == 0 ? w : round(w / increment) * increment
    }
    if workingWeight == 0 { return Array(repeating: 0, count: count) }
    if count == 3 {
        return [rnd(workingWeight * 0.5), rnd(workingWeight * 0.75), rnd(workingWeight * 0.9)]
    } else if count == 1 {
        return [rnd(workingWeight * 0.6)]
    } else if count == 2 {
        return [rnd(workingWeight * 0.5), rnd(workingWeight * 0.8)]
    }
    return Array(repeating: 0, count: count)
}
