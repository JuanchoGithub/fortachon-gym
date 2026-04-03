import Foundation

// MARK: - Movement Patterns

public let STRENGTH_SYMMETRY_RATIOS: [String: Int] = [
    "OHT": 2, "BENCH": 3, "ROW": 3,
    "VERTICAL_PULL": 3, "SQUAT": 4, "DEADLIFT": 5
]

public let MOVEMENT_PATTERNS: [String: Set<String>] = [
    "SQUAT": ["ex-2", "ex-101", "ex-108", "ex-109", "ex-113", "ex-160"],
    "DEADLIFT": ["ex-3", "ex-98", "ex-43"],
    "BENCH": ["ex-1", "ex-11", "ex-12", "ex-22", "ex-25", "ex-28", "ex-31", "ex-34", "ex-37"],
    "OHT": ["ex-4", "ex-60", "ex-67", "ex-68", "ex-70"],
    "ROW": ["ex-5", "ex-38", "ex-39", "ex-40", "ex-48"],
    "VERTICAL_PULL": ["ex-10", "ex-50", "ex-52", "ex-6", "ex-44"]
]

public struct AnchorExercises: Sendable {
    public let SQUAT: String, BENCH: String, DEADLIFT: String, OHT: String
    public init(squat: String, bench: String, deadlift: String, oht: String) {
        SQUAT = squat; BENCH = bench; DEADLIFT = deadlift; OHT = oht
    }
}
public let ANCHOR_EXERCISES = AnchorExercises(squat: "ex-2", bench: "ex-1", deadlift: "ex-3", oht: "ex-4")

public let EXERCISE_RATIOS: [String: (anchor: String, ratio: Double)] = [
    "ex-101": ("SQUAT", 0.85), "ex-109": ("SQUAT", 0.50), "ex-9": ("SQUAT", 2.50),
    "ex-102": ("SQUAT", 1.10), "ex-113": ("SQUAT", 0.90), "ex-160": ("SQUAT", 0.30),
    "ex-100": ("SQUAT", 0.40), "ex-99": ("SQUAT", 0.35),
    "ex-98": ("DEADLIFT", 0.75), "ex-43": ("DEADLIFT", 1.10),
    "ex-12": ("BENCH", 0.35), "ex-25": ("BENCH", 0.80), "ex-11": ("BENCH", 0.25),
    "ex-22": ("BENCH", 1.05), "ex-87": ("BENCH", 0.90), "ex-31": ("BENCH", 1.20),
    "ex-24": ("BENCH", 1.10), "ex-23": ("BENCH", 0.60),
    "ex-60": ("OHT", 0.35), "ex-67": ("OHT", 1.10)
]

public let CATEGORY_RATIOS: [String: Double] = [
    "Barbell": 1.0, "Dumbbell": 0.45, "Machine": 1.2,
    "Cable": 1.3, "Kettlebell": 0.4, "Smith Machine": 1.1,
    "Bodyweight": 1.0, "Assisted Bodyweight": 1.0,
    "Plyometrics": 0, "Reps Only": 0, "Cardio": 0, "Duration": 0
]

public let BODY_PART_ANCHORS: [String: String] = [
    "Chest": "BENCH", "Shoulders": "OHT", "Triceps": "BENCH",
    "Legs": "SQUAT", "Glutes": "DEADLIFT", "Back": "DEADLIFT", "Biceps": "DEADLIFT"
]

// MARK: - PatternMax

public struct PatternMax: Codable, Sendable {
    public let exerciseId: String
    public let weight: Double
    public let reps: Int
    public init(exerciseId: String, weight: Double, reps: Int) {
        self.exerciseId = exerciseId; self.weight = weight; self.reps = reps
    }
}

// MARK: - StrengthProfile

public struct StrengthProfile: Sendable {
    public let SQUAT: PatternMax
    public let BENCH: PatternMax
    public let DEADLIFT: PatternMax
    public let OVERHEAD: PatternMax
    public let ROW: PatternMax
    public let VERTICAL_PULL: PatternMax

    public init(
        SQUAT: PatternMax = PatternMax(exerciseId: "", weight: 0, reps: 0),
        BENCH: PatternMax = PatternMax(exerciseId: "", weight: 0, reps: 0),
        DEADLIFT: PatternMax = PatternMax(exerciseId: "", weight: 0, reps: 0),
        OVERHEAD: PatternMax = PatternMax(exerciseId: "", weight: 0, reps: 0),
        ROW: PatternMax = PatternMax(exerciseId: "", weight: 0, reps: 0),
        VERTICAL_PULL: PatternMax = PatternMax(exerciseId: "", weight: 0, reps: 0)
    ) {
        self.SQUAT = SQUAT; self.BENCH = BENCH; self.DEADLIFT = DEADLIFT
        self.OVERHEAD = OVERHEAD; self.ROW = ROW; self.VERTICAL_PULL = VERTICAL_PULL
    }
    public subscript(key: String) -> PatternMax {
        switch key {
        case "SQUAT": SQUAT
        case "BENCH": BENCH
        case "DEADLIFT": DEADLIFT
        case "OHT", "OVERHEAD": OVERHEAD
        case "ROW": ROW
        case "VERTICAL_PULL": VERTICAL_PULL
        default: PatternMax(exerciseId: "", weight: 0, reps: 0)
        }
    }
    public func patternMax() -> PatternMax {
        [SQUAT, BENCH, DEADLIFT, OVERHEAD, ROW, VERTICAL_PULL]
            .max { $0.weight < $1.weight } ?? PatternMax(exerciseId: "", weight: 0, reps: 0)
    }
}

// MARK: - calculateMaxStrengthProfile

public func calculateMaxStrengthProfile(
    _ history: [WorkoutSession], allExercises: [Exercise]
) -> StrengthProfile {
    var best: [String: PatternMax] = [:]
    for session in history {
        for exercise in session.exercises {
            guard let def = allExercises.first(where: { $0.id == exercise.exerciseId }) else { continue }
            for set in exercise.sets where set.isComplete && set.type == .normal {
                let oneRM = calculate1RM(weight: set.weight, reps: set.reps)
                guard oneRM > 0 else { continue }
                for (pattern, ids) in MOVEMENT_PATTERNS {
                    guard ids.contains(def.id) else { continue }
                    let current = best[pattern]?.weight ?? 0
                    if Double(oneRM) > current {
                        best[pattern] = PatternMax(
                            exerciseId: def.id, weight: Double(oneRM), reps: set.reps)
                    }
                }
            }
        }
    }
    return StrengthProfile(
        SQUAT: best["SQUAT"] ?? PatternMax(exerciseId: "", weight: 0, reps: 0),
        BENCH: best["BENCH"] ?? PatternMax(exerciseId: "", weight: 0, reps: 0),
        DEADLIFT: best["DEADLIFT"] ?? PatternMax(exerciseId: "", weight: 0, reps: 0),
        OVERHEAD: best["OHT"] ?? PatternMax(exerciseId: "", weight: 0, reps: 0),
        ROW: best["ROW"] ?? PatternMax(exerciseId: "", weight: 0, reps: 0),
        VERTICAL_PULL: best["VERTICAL_PULL"] ?? PatternMax(exerciseId: "", weight: 0, reps: 0)
    )
}

// MARK: - Normalized Scores

public struct NormalizedScores: Sendable {
    public let squat: Double, bench: Double, deadlift: Double
    public let overhead: Double, row: Double, verticalPull: Double
    public func max() -> Double {
        [squat, bench, deadlift, overhead, row, verticalPull].max() ?? 0
    }
}

public func calculateNormalizedStrengthScores(_ profile: StrengthProfile) -> NormalizedScores {
    let allZeros = profile.patternMax().weight == 0
    if allZeros {
        return NormalizedScores(squat: 0, bench: 0, deadlift: 0,
            overhead: 0, row: 0, verticalPull: 0)
    }
    let sq = profile.SQUAT.weight / 4.0
    let bn = profile.BENCH.weight / 3.0
    let dl = profile.DEADLIFT.weight / 5.0
    let oh = profile.OVERHEAD.weight / 2.0
    let rw = profile.ROW.weight / 3.0
    let vp = profile.VERTICAL_PULL.weight / 3.0
    let m = [sq, bn, dl, oh, rw, vp].max() ?? 0
    let scale = m > 0 ? (100 / m) : 0
    return NormalizedScores(
        squat: round(sq * scale), bench: round(bn * scale),
        deadlift: round(dl * scale), overhead: round(oh * scale),
        row: round(rw * scale), verticalPull: round(vp * scale)
    )
}

// MARK: - getInferredMax

public func getInferredMax(_ exercise: Exercise, profile: StrengthProfile) -> Double? {
    if let (anchorKey, ratio) = EXERCISE_RATIOS[exercise.id] {
        let anchor1RM: Double
        switch anchorKey {
        case "SQUAT": anchor1RM = profile.SQUAT.weight
        case "BENCH": anchor1RM = profile.BENCH.weight
        case "DEADLIFT": anchor1RM = profile.DEADLIFT.weight
        case "OHT": anchor1RM = profile.OVERHEAD.weight
        default: return nil
        }
        guard anchor1RM > 0 else { return nil }
        return anchor1RM * ratio
    }
    if let anchorKey = BODY_PART_ANCHORS[exercise.bodyPart.rawValue] {
        let anchor1RM = profile[anchorKey].weight
        guard anchor1RM > 0 else { return nil }
        let catR = CATEGORY_RATIOS[exercise.category.rawValue] ?? 0
        guard catR > 0 else { return nil }
        return anchor1RM * catR
    }
    return nil
}

// detectPreferredIncrement lives in AnalyticsUtils already
