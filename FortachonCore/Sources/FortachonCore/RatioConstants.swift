import Foundation

// MARK: - Ratio Constants
// Mirrors constants/ratios.ts

/// Biomechanical ratio between an anchor exercise and a related exercise.
public struct ExerciseRatio: Sendable {
    public let targetId: String
    public let ratio: Double

    public init(targetId: String, ratio: Double) {
        self.targetId = targetId
        self.ratio = ratio
    }
}

/// Anchor exercise IDs used as reference points for strength estimation.
public enum AnchorExercise: String, Sendable {
    case squat = "ex-2"
    case bench = "ex-1"
    case deadlift = "ex-3"
    case ohp = "ex-4"
}

/// Mappings from accessory exercise IDs to their anchor and ratio.
/// Mirrors EXERCISE_RATIOS from constants/ratios.ts
public let exerciseRatios: [String: (anchorId: String, ratio: Double)] = [
    // --- SQUAT ACCESSORIES ---
    "ex-101": (anchorId: AnchorExercise.squat.rawValue, ratio: 0.85),   // Front Squat
    "ex-109": (anchorId: AnchorExercise.squat.rawValue, ratio: 0.50),   // Goblet Squat
    "ex-9":   (anchorId: AnchorExercise.squat.rawValue, ratio: 2.50),   // Leg Press
    "ex-102": (anchorId: AnchorExercise.squat.rawValue, ratio: 1.10),   // Hack Squat
    "ex-113": (anchorId: AnchorExercise.squat.rawValue, ratio: 0.90),   // Jefferson Squat
    "ex-160": (anchorId: AnchorExercise.squat.rawValue, ratio: 0.30),   // Air Squat
    "ex-100": (anchorId: AnchorExercise.squat.rawValue, ratio: 0.40),   // Bulgarian Split Squat (Per leg)
    "ex-99":  (anchorId: AnchorExercise.squat.rawValue, ratio: 0.35),   // Walking Lunge (Per leg)

    // --- DEADLIFT ACCESSORIES ---
    "ex-98":  (anchorId: AnchorExercise.deadlift.rawValue, ratio: 0.75),   // RDL
    "ex-43":  (anchorId: AnchorExercise.deadlift.rawValue, ratio: 1.10),   // Rack Pull
    "ex-134": (anchorId: AnchorExercise.deadlift.rawValue, ratio: 0.40),   // KB Swing
    "ex-51":  (anchorId: AnchorExercise.deadlift.rawValue, ratio: 0.90),   // Shrugs

    // --- BENCH ACCESSORIES ---
    "ex-12": (anchorId: AnchorExercise.bench.rawValue, ratio: 0.35),   // Incline DB Press (Per hand)
    "ex-25": (anchorId: AnchorExercise.bench.rawValue, ratio: 0.80),   // Incline Barbell
    "ex-11": (anchorId: AnchorExercise.bench.rawValue, ratio: 0.25),   // DB Fly (Per hand)
    "ex-22": (anchorId: AnchorExercise.bench.rawValue, ratio: 1.05),   // Decline Bench
    "ex-87": (anchorId: AnchorExercise.bench.rawValue, ratio: 0.90),   // Close Grip Bench
    "ex-31": (anchorId: AnchorExercise.bench.rawValue, ratio: 1.20),   // Machine Chest Press
    "ex-24": (anchorId: AnchorExercise.bench.rawValue, ratio: 1.10),   // Dips
    "ex-23": (anchorId: AnchorExercise.bench.rawValue, ratio: 0.60),   // Pushups
    "ex-32": (anchorId: AnchorExercise.bench.rawValue, ratio: 0.50),   // Low-to-High Cable Fly
    "ex-33": (anchorId: AnchorExercise.bench.rawValue, ratio: 0.50),   // High-to-Low Cable Fly

    // --- OHP ACCESSORIES ---
    "ex-60":  (anchorId: AnchorExercise.ohp.rawValue, ratio: 0.35), // Arnold Press (Per hand)
    "ex-67":  (anchorId: AnchorExercise.ohp.rawValue, ratio: 1.10), // Machine Shoulder Press
    "ex-56":  (anchorId: AnchorExercise.ohp.rawValue, ratio: 0.15), // Lateral Raise
    "ex-4":   (anchorId: AnchorExercise.ohp.rawValue, ratio: 1.00), // Self
    "ex-146": (anchorId: AnchorExercise.ohp.rawValue, ratio: 0.80), // KB Clean & Press
    "ex-145": (anchorId: AnchorExercise.ohp.rawValue, ratio: 0.40), // Turkish Get Up

    // --- BAND / REPS ONLY OVERRIDES ---
    "ex-83": (anchorId: AnchorExercise.deadlift.rawValue, ratio: 0.40), // Band Curl

    // --- BACK / VERTICAL PULL NORMALIZATION ---
    "ex-10": (anchorId: "VERTICAL_PULL", ratio: 1.30), // Lat Pulldown
    "ex-50": (anchorId: "VERTICAL_PULL", ratio: 1.00), // Chin-Up
    "ex-6":  (anchorId: "VERTICAL_PULL", ratio: 1.00), // Pull Up
    "ex-44": (anchorId: "VERTICAL_PULL", ratio: 1.10), // Straight-Arm Pulldown
]

/// Fallback anchor exercise per body part.
public let bodyPartAnchors: [String: String] = [
    "Chest": AnchorExercise.bench.rawValue,
    "Shoulders": AnchorExercise.ohp.rawValue,
    "Triceps": AnchorExercise.bench.rawValue,
    "Legs": AnchorExercise.squat.rawValue,
    "Glutes": AnchorExercise.deadlift.rawValue,
    "Back": AnchorExercise.deadlift.rawValue,
    "Biceps": AnchorExercise.deadlift.rawValue,
]

/// Multiplier against the Anchor (Barbell = 1.0).
public let categoryRatios: [String: Double] = [
    "Barbell": 1.0,
    "Dumbbell": 0.45,
    "Machine": 1.2,
    "Cable": 1.3,
    "Kettlebell": 0.4,
    "Smith Machine": 1.1,
    "Bodyweight": 1.0,
    "Assisted Bodyweight": 1.0,
    "Plyometrics": 0,
    "Reps Only": 0,
    "Cardio": 0,
    "Duration": 0,
]

/// Parent → Child exercise ratios for cascade suggestions.
public let parentChildExercises: [String: [ExerciseRatio]] = [
    // Barbell Squat
    AnchorExercise.squat.rawValue: [
        ExerciseRatio(targetId: "ex-101", ratio: 0.85),
        ExerciseRatio(targetId: "ex-109", ratio: 0.50),
        ExerciseRatio(targetId: "ex-9",   ratio: 2.5),
        ExerciseRatio(targetId: "ex-102", ratio: 1.1),
    ],
    // Deadlift
    AnchorExercise.deadlift.rawValue: [
        ExerciseRatio(targetId: "ex-98", ratio: 0.75),
        ExerciseRatio(targetId: "ex-43", ratio: 1.1),
    ],
    // Bench Press
    AnchorExercise.bench.rawValue: [
        ExerciseRatio(targetId: "ex-12", ratio: 0.35),
        ExerciseRatio(targetId: "ex-25", ratio: 0.8),
        ExerciseRatio(targetId: "ex-11", ratio: 0.25),
        ExerciseRatio(targetId: "ex-22", ratio: 1.05),
        ExerciseRatio(targetId: "ex-87", ratio: 0.9),
    ],
    // Overhead Press
    AnchorExercise.ohp.rawValue: [
        ExerciseRatio(targetId: "ex-60", ratio: 0.35),
        ExerciseRatio(targetId: "ex-67", ratio: 1.1),
    ],
]
