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
    public init(id: String, name: String, bodyPart: String, category: String,
                notes: String? = nil, isTimed: Bool = false, isUnilateral: Bool = false,
                primaryMuscles: [String] = [], secondaryMuscles: [String] = []) {
        self.id = id; self.name = name; self.bodyPartStr = bodyPart
        self.categoryStr = category; self.notes = notes
        self.isTimed = isTimed; self.isUnilateral = isUnilateral
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
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
    public init(id: String, reps: Int, weight: Double, time: Int? = nil,
                type: String, isComplete: Bool = false, completedAt: Date? = nil,
                rest: Int? = nil, actualRest: Int? = nil) {
        self.setId = id; self.reps = reps; self.weight = weight; setTime = time
        setTypeStr = type; self.isComplete = isComplete
        self.completedAt = completedAt; restTime = rest; actualRestTime = actualRest
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
    public init(id: String, exerciseId: String, restTime: RestTimes = RestTimes(),
                note: String? = nil, supersetId: String? = nil) {
        self.weId = id; self.exerciseId = exerciseId
        restNormal = restTime.normal; restWarmup = restTime.warmup
        restDrop = restTime.drop; restTimed = restTime.timed
        restEffort = restTime.effort; restFailure = restTime.failure
        self.note = note; self.supersetId = supersetId
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
    @Relationship(deleteRule: .cascade)
    public var exercises: [WorkoutExerciseM] = []
    public var updatedAt: Date
    public var deletedAt: Date?
    public init(id: String, routineId: String, routineName: String,
                startTime: Date, endTime: Date, prCount: Int = 0) {
        self.wsId = id; self.routineId = routineId; self.routineName = routineName
        self.startTime = startTime; self.endTime = endTime
        self.prCount = prCount; self.updatedAt = Date()
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
        self.init(id: m.id, name: m.name,
                  bodyPart: BodyPart(rawValue: m.bodyPartStr) ?? .fullBody,
                  category: ExerciseCategory(rawValue: m.categoryStr) ?? .bodyweight,
                  notes: m.notes, isTimed: m.isTimed,
                  isUnilateral: m.isUnilateral,
                  primaryMuscles: m.primaryMuscles,
                  secondaryMuscles: m.secondaryMuscles)
    }
}

extension PerformedSet {
    public init(from m: PerformedSetM) {
        self.init(id: m.setId, reps: m.reps, weight: m.weight,
                  time: m.setTime,
                  type: SetType(rawValue: m.setTypeStr) ?? .normal,
                  isComplete: m.isComplete,
                  completedAt: m.completedAt?.timeIntervalSince1970,
                  rest: m.restTime, actualRest: m.actualRestTime)
    }
}

extension WorkoutExercise {
    public init(from m: WorkoutExerciseM) {
        let sets = m.sets.map { PerformedSet(from: $0) }
        let rt = RestTimes(normal: m.restNormal, warmup: m.restWarmup,
                           drop: m.restDrop, timed: m.restTimed,
                           effort: m.restEffort, failure: m.restFailure)
        self.init(id: m.weId, exerciseId: m.exerciseId, sets: sets,
                  restTime: rt, note: m.note, supersetId: m.supersetId)
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

// MARK: - ModelContainer Factory

public func makeInMemoryContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: ExerciseM.self, PerformedSetM.self,
                              WorkoutExerciseM.self, SupersetM.self,
                              WorkoutSessionM.self, RoutineM.self,
                              configurations: config)
}
