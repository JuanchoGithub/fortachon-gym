import Foundation

// MARK: - RoutineLevel & SurveyAnswers

public enum RoutineLevel: String, Codable, CaseIterable, Sendable {
    case beginner, intermediate, advanced
}

public struct SurveyAnswers: Codable {
    public let experience: RoutineLevel
    public let goal: UserGoal
    public let equipment: EquipmentType
    public let time: TimePreference
    public init(experience: RoutineLevel, goal: UserGoal, equipment: EquipmentType, time: TimePreference) {
        self.experience = experience; self.goal = goal
        self.equipment = equipment; self.time = time
    }
}

public enum EquipmentType: String, Codable, CaseIterable, Sendable {
    case gym, dumbbell, bodyweight
}

public enum TimePreference: String, Codable, CaseIterable, Sendable {
    case short, medium, long
}

// MARK: - RoutineFocus

public enum RoutineFocus: String, Codable, CaseIterable, Sendable {
    case push, pull, legs, full_body, upper, lower, cardio
}

// MARK: - Exercise slot maps

typealias ExerciseMap = [String: String]
let EXERCISE_MAP: [EquipmentType: ExerciseMap] = [
    .gym: [
        "chest_compound": "ex-1", "chest_iso": "ex-26",
        "back_vertical": "ex-10", "back_horizontal": "ex-5",
        "shoulder_press": "ex-4", "shoulder_iso": "ex-56",
        "legs_quad": "ex-2", "legs_ham": "ex-16", "legs_iso": "ex-17",
        "tricep": "ex-85", "bicep": "ex-7", "core": "ex-20",
    ],
    .dumbbell: [
        "chest_compound": "ex-12", "chest_iso": "ex-11",
        "back_vertical": "ex-40", "back_horizontal": "ex-40",
        "shoulder_press": "ex-60", "shoulder_iso": "ex-56",
        "legs_quad": "ex-109", "legs_ham": "ex-98", "legs_iso": "ex-99",
        "tricep": "ex-86", "bicep": "ex-13", "core": "ex-117",
    ],
    .bodyweight: [
        "chest_compound": "ex-23", "chest_iso": "ex-24",
        "back_vertical": "ex-6", "back_horizontal": "ex-42",
        "shoulder_press": "ex-62", "shoulder_iso": "ex-129",
        "legs_quad": "ex-160", "legs_ham": "ex-104", "legs_iso": "ex-162",
        "tricep": "ex-89", "bicep": "ex-50", "core": "ex-15",
    ],
]

let BEGINNER_GYM_SWAPS: [String: String] = [
    "ex-1": "ex-31", "ex-2": "ex-109", "ex-5": "ex-38",
    "ex-4": "ex-67", "ex-6": "ex-10", "ex-98": "ex-16",
    "ex-24": "ex-89",
]

let BEGINNER_BODYWEIGHT_SWAPS: [String: String] = [
    "ex-6": "ex-42", "ex-24": "ex-89",
]

let FOCUS_SLOTS: [RoutineFocus: [String]] = [
    .push: ["chest_compound", "shoulder_press", "chest_iso", "shoulder_iso", "tricep"],
    .pull: ["back_vertical", "back_horizontal", "legs_ham", "bicep"],
    .legs: ["legs_quad", "legs_ham", "legs_iso", "core"],
    .upper: ["chest_compound", "back_vertical", "shoulder_press", "back_horizontal", "bicep", "tricep"],
    .lower: ["legs_quad", "legs_ham", "legs_iso", "core"],
    .full_body: ["legs_quad", "chest_compound", "back_horizontal", "core"],
    .cardio: [],
]

let BEGINNER_A_SLOTS = ["legs_quad", "chest_compound", "back_horizontal", "core"]
let BEGINNER_B_SLOTS = ["legs_ham", "shoulder_press", "back_vertical", "tricep"]

// MARK: - Helpers

private func makeSet(reps: Int, type: SetType = .normal, time: Int? = nil) -> PerformedSet {
    PerformedSet(id: "s-\(UUID().uuidString.prefix(6))",
                 reps: reps, weight: 0, time: time, type: type, isComplete: false)
}

private func makeExercise(id: String, sets: Int, reps: Int, restTime: RestTimes, time: Int? = nil) -> WorkoutExercise {
    WorkoutExercise(id: "we-\(UUID().uuidString.prefix(6))", exerciseId: id,
                    sets: (0..<sets).map { _ in makeSet(reps: reps, time: time) },
                    restTime: restTime)
}

private func resolveSlot(_ slot: String, equipment: EquipmentType, experience: RoutineLevel) -> String {
    let map = EXERCISE_MAP[equipment] ?? EXERCISE_MAP[.gym]!
    let oid = map[slot] ?? EXERCISE_MAP[.gym]![slot]!
    if experience == .beginner {
        switch equipment {
        case .gym: return BEGINNER_GYM_SWAPS[oid] ?? oid
        case .dumbbell: return oid == "ex-98" ? "ex-104" : oid
        case .bodyweight: return BEGINNER_BODYWEIGHT_SWAPS[oid] ?? oid
        }
    }
    return oid
}

private func buildRoutine(slots: [String], settings: SurveyAnswers,
                          sets: Int, reps: Int, rest: Int) -> Routine {
    var rt = RestTimes(); rt.normal = rest
    let exercises = slots.map { slot in
        let id = resolveSlot(slot, equipment: settings.equipment, experience: settings.experience)
        let timed = (id == "ex-15")
        let fReps = timed ? 1 : reps
        let fTime = timed ? (settings.goal == .strength ? 60 : 45) : nil
        return makeExercise(id: id, sets: sets, reps: fReps, restTime: rt, time: fTime)
    }
    return Routine(id: "gen-\(UUID().uuidString)", name: "", description: "",
                   exercises: exercises, routineType: .strength)
}

// MARK: - Public API

public func generateSmartRoutine(focus: RoutineFocus, settings: SurveyAnswers) -> Routine {
    var sets = 3, reps = 10, rest = 60
    switch settings.goal {
    case .strength: sets = 5; reps = 5; rest = 180
    case .endurance: sets = 3; reps = 15; rest = 45
    default: break
    }
    if settings.time == .short {
        sets = max(2, sets - 1)
        rest = max(30, rest - 30)
    }
    let slots = FOCUS_SLOTS[focus] ?? []
    return buildRoutine(slots: slots, settings: settings, sets: sets, reps: reps, rest: rest)
}

public func generateRoutines(_ settings: SurveyAnswers) -> [Routine] {
    var sets = 3, reps = 10, rest = 60
    switch settings.goal {
    case .strength: sets = 5; reps = 5; rest = 180
    case .endurance: sets = 3; reps = 15; rest = 45
    default: break
    }
    if settings.time == .short {
        sets = max(2, sets - 1)
        rest = max(30, rest - 30)
    }
    var routines: [Routine]
    switch settings.experience {
    case .beginner:
        routines = [
            buildRoutine(slots: BEGINNER_A_SLOTS, settings: settings, sets: sets, reps: reps, rest: rest),
            buildRoutine(slots: BEGINNER_B_SLOTS, settings: settings, sets: sets, reps: reps, rest: rest),
        ]
    case .intermediate:
        routines = [
            buildRoutine(slots: FOCUS_SLOTS[.upper]!, settings: settings, sets: sets, reps: reps, rest: rest),
            buildRoutine(slots: FOCUS_SLOTS[.lower]!, settings: settings, sets: sets, reps: reps, rest: rest),
        ]
    case .advanced:
        routines = [
            buildRoutine(slots: FOCUS_SLOTS[.push]!, settings: settings, sets: sets, reps: reps, rest: rest),
            buildRoutine(slots: FOCUS_SLOTS[.pull]!, settings: settings, sets: sets, reps: reps, rest: rest),
            buildRoutine(slots: FOCUS_SLOTS[.legs]!, settings: settings, sets: sets, reps: reps, rest: rest),
        ]
    }
    for i in routines.indices {
        routines[i] = Routine(id: routines[i].id, name: routines[i].name, description: routines[i].description,
                              exercises: routines[i].exercises, isTemplate: true, routineType: .strength)
    }
    return routines
}
