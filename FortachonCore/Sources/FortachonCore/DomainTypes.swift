import Foundation

// MARK: - Recommendation Types

public enum RecommendationType: String, Codable, Sendable {
    case rest, workout, promotion, activeRecovery, imbalance, deload
}

public struct Recommendation: Sendable {
    public let type: RecommendationType
    public let title: String
    public let reason: String
    public let suggestedBodyParts: [BodyPart]
    public let relevantRoutineIds: [String]
    public let generatedRoutine: Routine?
    public let systemicFatigue: (score: Double, level: String)?
    public init(type: RecommendationType, title: String, reason: String,
                suggestedBodyParts: [BodyPart] = [], relevantRoutineIds: [String] = [],
                generatedRoutine: Routine? = nil,
                systemicFatigue: (score: Double, level: String)? = nil) {
        self.type = type; self.title = title; self.reason = reason
        self.suggestedBodyParts = suggestedBodyParts
        self.relevantRoutineIds = relevantRoutineIds
        self.generatedRoutine = generatedRoutine
        self.systemicFatigue = systemicFatigue
    }
}

// MARK: - CheckInReason

public enum CheckInReason: String, Codable, CaseIterable, Sendable {
    case busy, deload, injury, vacation, takingBreak
    public var label: String {
        switch self {
        case .busy: return "I'm busy this week"
        case .deload: return "I need a deload"
        case .injury: return "I'm injured"
        case .vacation: return "On vacation"
        case .takingBreak: return "Just needed a break"
        }
    }
    public var emoji: String {
        switch self {
        case .busy: return "💼"
        case .deload: return "🔄"
        case .injury: return "🩹"
        case .vacation: return "🏖️"
        case .takingBreak: return "😌"
        }
    }
}

// MARK: - MUSCLES

public enum MUSCLES {
    public static let pectorals = "Pectorals"
    public static let quads = "Quads"
    public static let hamstrings = "Hamstrings"
    public static let glutes = "Glutes"
    public static let lats = "Lats"
    public static let traps = "Traps"
    public static let biceps = "Biceps"
    public static let triceps = "Triceps"
    public static let frontDelts = "Front Delts"
    public static let sideDelts = "Side Delts"
    public static let rearDelts = "Rear Delts"
    public static let lowerBack = "Lower Back"
    public static let calves = "Calves"
    public static let abs = "Abs"
    public static let forearms = "Forearms"
}

public enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
    case barbell = "Barbell", dumbbell = "Dumbbell", machine = "Machine", cable = "Cable"
    case bodyweight = "Bodyweight", assistedBodyweight = "Assisted Bodyweight"
    case kettlebell = "Kettlebell", plyometrics = "Plyometrics"
    case repsOnly = "Reps Only", cardio = "Cardio", duration = "Duration"
    case smithMachine = "Smith Machine"
}

public enum BodyPart: String, Codable, CaseIterable, Sendable {
    case chest = "Chest", back = "Back", legs = "Legs", glutes = "Glutes"
    case shoulders = "Shoulders", biceps = "Biceps", triceps = "Triceps"
    case core = "Core", fullBody = "Full Body"
    case calves = "Calves", forearms = "Forearms"
    case mobility = "Mobility", cardio = "Cardio"
}

public enum SetType: String, Codable, CaseIterable, Sendable, Equatable {
    case normal = "normal", warmup = "warmup", drop = "drop", failure = "failure", timed = "timed"
    
    public var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .warmup: return "Warmup"
        case .drop: return "Drop Set"
        case .failure: return "Failure"
        case .timed: return "Timed"
        }
    }
}

public enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case kg, lbs
}
