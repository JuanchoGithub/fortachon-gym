// MARK: - ExerciseCategory

/// Identifies the equipment category for an exercise.
/// Mirrors `ExerciseCategory` from types/index.ts.
public enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case bodyweight = "Bodyweight"
    case assistedBodyweight = "Assisted Bodyweight"
    case kettlebell = "Kettlebell"
    case plyometrics = "Plyometrics"
    case repsOnly = "Reps Only"
    case cardio = "Cardio"
    case duration = "Duration"
    case smithMachine = "Smith Machine"
}

// MARK: - BodyPart

/// The primary body part / region targeted by an exercise.
/// Mirrors `BodyPart` from types/index.ts.
public enum BodyPart: String, Codable, CaseIterable, Sendable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case glutes = "Glutes"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case core = "Core"
    case fullBody = "Full Body"
    case calves = "Calves"
    case forearms = "Forearms"
    case mobility = "Mobility"
    case cardio = "Cardio"
}

// MARK: - SetType

/// The type of a performed set.
/// Mirrors `SetType` from types/index.ts.
public enum SetType: String, Codable, CaseIterable, Sendable, Equatable {
    case normal = "normal"
    case warmup = "warmup"
    case drop = "drop"
    case failure = "failure"
    case timed = "timed"
}