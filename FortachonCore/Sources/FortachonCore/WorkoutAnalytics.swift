import Foundation

// MARK: - LifterDNA Stats

public struct LifterStats: Sendable {
    public let consistencyScore: Int
    public let volumeScore: Int
    public let intensityScore: Int
    public let experienceLevel: Int
    public let archetype: LifterArchetype
    public let favMuscle: String
    public let efficiencyScore: Int
    public let rawConsistency: Int
    public let rawVolume: Int
    public let rawIntensity: Double
    
    public init(consistencyScore: Int, volumeScore: Int, intensityScore: Int,
                experienceLevel: Int, archetype: LifterArchetype, favMuscle: String,
                efficiencyScore: Int, rawConsistency: Int, rawVolume: Int, rawIntensity: Double) {
        self.consistencyScore = consistencyScore
        self.volumeScore = volumeScore
        self.intensityScore = intensityScore
        self.experienceLevel = experienceLevel
        self.archetype = archetype
        self.favMuscle = favMuscle
        self.efficiencyScore = efficiencyScore
        self.rawConsistency = rawConsistency
        self.rawVolume = rawVolume
        self.rawIntensity = rawIntensity
    }
}

public enum LifterArchetype: String, Sendable {
    case powerbuilder
    case bodybuilder
    case endurance
    case hybrid
    case beginner
}

// MARK: - Muscle Freshness

public struct MuscleFreshness: Sendable {
    public let muscleName: String
    public let freshnessPercent: Double // 0 = completely fatigued, 100 = fully recovered
    public let lastWorkoutDate: Date?
    public let volumeInWindow: Double
    
    public init(muscleName: String, freshnessPercent: Double, lastWorkoutDate: Date?, volumeInWindow: Double) {
        self.muscleName = muscleName
        self.freshnessPercent = freshnessPercent
        self.lastWorkoutDate = lastWorkoutDate
        self.volumeInWindow = volumeInWindow
    }
}

// MARK: - Strength Profile

public struct StrengthProfileEntry: Sendable {
    public let patternName: String
    public let maxWeight: Double
    public let exerciseName: String
    public let normalizedScore: Double
    
    public init(patternName: String, maxWeight: Double, exerciseName: String, normalizedScore: Double) {
        self.patternName = patternName
        self.maxWeight = maxWeight
        self.exerciseName = exerciseName
        self.normalizedScore = normalizedScore
    }
}

// MARK: - Movement Pattern Display Names and Denominators
// Note: MOVEMENT_PATTERNS, EXERCISE_RATIOS, BODY_PART_ANCHORS, CATEGORY_RATIOS
// are defined in StrengthProfile.swift

private let MOVEMENT_PATTERN_DISPLAY_NAMES: [String: String] = [
    "SQUAT": "Squat",
    "DEADLIFT": "Deadlift",
    "BENCH": "Bench",
    "OHT": "Overhead Press",
    "ROW": "Row",
    "VERTICAL_PULL": "Vertical Pull"
]

private let MOVEMENT_PATTERN_DENOMINATORS: [String: Double] = [
    "OHT": 2,
    "BENCH": 3,
    "ROW": 3,
    "VERTICAL_PULL": 3,
    "SQUAT": 4,
    "DEADLIFT": 5
]

// MARK: - Analytics Calculations

/// Calculate estimated 1RM using Epley formula
public func calculate1RM(weight: Double, reps: Int) -> Double {
    if reps <= 0 { return 0 }
    if reps == 1 { return weight }
    return weight * (1.0 + Double(reps) / 30.0)
}

/// Calculate LifterDNA stats from workout history
public func calculateLifterDNA(history: [(startTime: Date, endTime: Date, exercises: [(exerciseId: String, sets: [(reps: Int, weight: Double, isComplete: Bool, type: String)])])], currentBodyWeight: Double = 70) -> LifterStats {
    if history.count < 5 {
        return LifterStats(
            consistencyScore: 0,
            volumeScore: 0,
            intensityScore: 0,
            experienceLevel: history.count,
            archetype: .beginner,
            favMuscle: "N/A",
            efficiencyScore: 0,
            rawConsistency: 0,
            rawVolume: 0,
            rawIntensity: 0
        )
    }
    
    let now = Date()
    let last30Days = history.filter { abs(now.timeIntervalSince($0.startTime)) < 30 * 24 * 60 * 60 }
    let monthlyCount = last30Days.count
    let consistencyScore = min(100, Int(Double(monthlyCount) / 12.0 * 100.0))
    
    // Calculate weighted rep averages and volume
    var weightedRepSum: Double = 0
    var totalVolumeForWeightedAvg: Double = 0
    var totalRawVolume: Double = 0
    var compoundWeightedRepSum: Double = 0
    var compoundTotalVolume: Double = 0
    var muscleCounts: [String: Int] = [:]
    
    let analyzedHistory = Array(history.prefix(20))
    
    for session in analyzedHistory {
        for ex in session.exercises {
            // Count muscle groups
            if let bodyPart = getBodyPartForExercise(exerciseId: ex.exerciseId) {
                muscleCounts[bodyPart, default: 0] += 1
            }
            
            for set in ex.sets where set.isComplete {
                totalRawVolume += set.weight * Double(set.reps)
                let effectiveWeight = set.weight > 0 ? set.weight : (currentBodyWeight > 0 ? currentBodyWeight : 70)
                let setVolume = effectiveWeight * Double(set.reps)
                weightedRepSum += Double(set.reps) * setVolume
                totalVolumeForWeightedAvg += setVolume
                
                // Check if compound exercise
                if isCompoundExercise(exerciseId: ex.exerciseId) {
                    compoundWeightedRepSum += Double(set.reps) * setVolume
                    compoundTotalVolume += setVolume
                }
            }
        }
    }
    
    let globalAvgReps = totalVolumeForWeightedAvg > 0 ? weightedRepSum / totalVolumeForWeightedAvg : 0
    let compoundAvgReps = compoundTotalVolume > 0 ? compoundWeightedRepSum / compoundTotalVolume : 0
    
    // Determine archetype
    let archetype: LifterArchetype
    if compoundAvgReps > 0 && compoundAvgReps <= 6.5 {
        archetype = .powerbuilder
    } else if globalAvgReps > 0 && globalAvgReps <= 7.5 {
        archetype = .powerbuilder
    } else if globalAvgReps > 7.5 && globalAvgReps <= 13 {
        archetype = .bodybuilder
    } else if globalAvgReps > 13 {
        archetype = .endurance
    } else {
        archetype = .hybrid
    }
    
    let avgSessionVolume = analyzedHistory.count > 0 ? totalRawVolume / Double(analyzedHistory.count) : 0
    let volumeScore = min(100, Int(avgSessionVolume / 10000.0 * 100.0))
    
    let effectiveAvgReps = compoundAvgReps > 0 ? compoundAvgReps : globalAvgReps
    let intensityScore: Int
    if effectiveAvgReps <= 5 {
        intensityScore = 95
    } else if effectiveAvgReps <= 8 {
        intensityScore = 85
    } else if effectiveAvgReps <= 12 {
        intensityScore = 75
    } else if effectiveAvgReps <= 15 {
        intensityScore = 60
    } else {
        intensityScore = 40
    }
    
    // Favorite muscle
    var favMuscle = "Full Body"
    var maxCount = 0
    for (muscle, count) in muscleCounts where count > maxCount {
        maxCount = count
        favMuscle = muscle
    }
    
    // Efficiency score based on density
    var densities: [Double] = []
    for session in analyzedHistory {
        let duration = session.endTime.timeIntervalSince(session.startTime) / 60.0
        var vol: Double = 0
        for ex in session.exercises {
            for set in ex.sets where set.isComplete {
                vol += set.weight * Double(set.reps)
            }
        }
        if duration > 5 {
            densities.append(vol / duration)
        }
    }
    
    var efficiencyScore = 100
    if densities.count >= 4 {
        let currentDensity = densities[0]
        let avgDensity = densities[1..<min(5, densities.count)].reduce(0, +) / Double(min(4, densities.count - 1))
        if avgDensity > 0 {
            efficiencyScore = min(100, Int(currentDensity / avgDensity * 100))
        }
    }
    
    return LifterStats(
        consistencyScore: consistencyScore,
        volumeScore: volumeScore,
        intensityScore: intensityScore,
        experienceLevel: history.count,
        archetype: archetype,
        favMuscle: favMuscle,
        efficiencyScore: efficiencyScore,
        rawConsistency: monthlyCount,
        rawVolume: Int(avgSessionVolume),
        rawIntensity: round(effectiveAvgReps * 10) / 10
    )
}

/// Calculate muscle freshness for fatigue monitor
public func calculateMuscleFreshness(
    history: [(startTime: Date, exercises: [(exerciseId: String, sets: [(reps: Int, weight: Double, isComplete: Bool)])])],
    allMuscles: [String] = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Core"]
) -> [MuscleFreshness] {
    let now = Date()
    let windowDays = 7.0
    let windowStart = now.addingTimeInterval(-windowDays * 24 * 60 * 60)
    let fullRecoveryHours = 72.0 // Full recovery in 72 hours
    
    return allMuscles.map { muscle in
        // Find all workouts that hit this muscle in the window
        var muscleVolume: Double = 0
        var lastWorkout: Date?
        
        for session in history {
            if session.startTime < windowStart { continue }
            
            for ex in session.exercises {
                let exMuscle = getBodyPartForExercise(exerciseId: ex.exerciseId)
                if exMuscle == muscle {
                    for set in ex.sets where set.isComplete {
                        muscleVolume += set.weight * Double(set.reps)
                    }
                    if lastWorkout == nil || session.startTime > lastWorkout! {
                        lastWorkout = session.startTime
                    }
                }
            }
        }
        
        // Calculate freshness based on time since last workout and volume
        let freshnessPercent: Double
        if let lastWorkout = lastWorkout {
            let hoursSince = now.timeIntervalSince(lastWorkout) / 3600.0
            let timeRecoveryFactor = min(1.0, hoursSince / fullRecoveryHours)
            
            // Higher volume means slower recovery
            let volumePenalty = min(0.3, muscleVolume / 10000.0 * 0.3)
            freshnessPercent = max(0, min(100, (timeRecoveryFactor - volumePenalty) * 100))
        } else {
            freshnessPercent = 100
        }
        
        return MuscleFreshness(
            muscleName: muscle,
            freshnessPercent: round(freshnessPercent),
            lastWorkoutDate: lastWorkout,
            volumeInWindow: muscleVolume
        )
    }
}

/// Calculate strength profile for all movement patterns
public func calculateStrengthProfile(
    history: [(startTime: Date, exercises: [(exerciseId: String, sets: [(reps: Int, weight: Double, isComplete: Bool, type: String)])])]
) -> [StrengthProfileEntry] {
    let sixMonthsAgo = Date().addingTimeInterval(-180 * 24 * 60 * 60)
    
    return MOVEMENT_PATTERNS.map { (patternName, exerciseIds) in
        var maxNormalized1RM: Double = 0
        var bestExerciseName = MOVEMENT_PATTERN_DISPLAY_NAMES[patternName] ?? patternName
        let denominator = MOVEMENT_PATTERN_DENOMINATORS[patternName] ?? 3.0
        
        for exerciseId in exerciseIds {
            let ratio = EXERCISE_RATIOS[exerciseId]?.ratio ?? CATEGORY_RATIOS[getCategoryForExercise(exerciseId: exerciseId)] ?? 1.0
            
            for session in history {
                if session.startTime < sixMonthsAgo { continue }
                
                for ex in session.exercises where ex.exerciseId == exerciseId {
                    for set in ex.sets where set.isComplete && set.type == "normal" && set.reps > 0 && set.reps <= 12 {
                        let e1rm = calculate1RM(weight: set.weight, reps: set.reps)
                        let normalized = e1rm / ratio
                        if normalized > maxNormalized1RM {
                            maxNormalized1RM = normalized
                            bestExerciseName = getExerciseName(exerciseId: exerciseId)
                        }
                    }
                }
            }
        }
        
        let normalizedScore = maxNormalized1RM / denominator
        
        return StrengthProfileEntry(
            patternName: MOVEMENT_PATTERN_DISPLAY_NAMES[patternName] ?? patternName,
            maxWeight: round(maxNormalized1RM),
            exerciseName: bestExerciseName,
            normalizedScore: round(normalizedScore * 10) / 10
        )
    }
}

/// Calculate normalized strength scores for symmetry radar chart
public func calculateNormalizedStrengthScores(
    history: [(startTime: Date, exercises: [(exerciseId: String, sets: [(reps: Int, weight: Double, isComplete: Bool, type: String)])])]
) -> [String: Double] {
    let profile = calculateStrengthProfile(history: history)
    var scores: [String: Double] = [:]
    
    for entry in profile {
        scores[entry.patternName] = entry.normalizedScore
    }
    
    // Normalize to 0-100 scale
    let maxScore = scores.values.max() ?? 1
    let scale = maxScore > 0 ? 100.0 / maxScore : 0
    
    return scores.mapValues { $0 * scale }
}

// MARK: - Helper Functions

private func getBodyPartForExercise(exerciseId: String) -> String? {
    let mapping: [String: String] = [
        "ex-1": "Chest", "ex-11": "Chest", "ex-12": "Chest", "ex-22": "Chest", "ex-25": "Chest", "ex-28": "Chest", "ex-31": "Chest", "ex-34": "Chest", "ex-37": "Chest",
        "ex-2": "Legs", "ex-101": "Legs", "ex-108": "Legs", "ex-109": "Legs", "ex-113": "Legs", "ex-160": "Legs",
        "ex-3": "Back", "ex-98": "Back", "ex-43": "Back",
        "ex-4": "Shoulders", "ex-60": "Shoulders", "ex-67": "Shoulders", "ex-68": "Shoulders", "ex-70": "Shoulders",
        "ex-5": "Back", "ex-38": "Back", "ex-39": "Back", "ex-40": "Back", "ex-48": "Back",
        "ex-10": "Back", "ex-50": "Back", "ex-52": "Back", "ex-6": "Back", "ex-44": "Back",
        "ex-7": "Arms", "ex-8": "Arms", "ex-9": "Arms",
        "ex-13": "Core", "ex-14": "Core", "ex-15": "Core"
    ]
    return mapping[exerciseId]
}

private func getCategoryForExercise(exerciseId: String) -> String {
    // Barbell exercises
    let barbellIds = ["ex-1", "ex-2", "ex-3", "ex-4", "ex-5", "ex-10"]
    if barbellIds.contains(exerciseId) { return "Barbell" }
    
    // Dumbbell exercises
    let dumbbellIds = ["ex-11", "ex-12", "ex-22", "ex-25", "ex-28", "ex-31", "ex-34", "ex-37", "ex-60", "ex-67", "ex-68", "ex-70"]
    if dumbbellIds.contains(exerciseId) { return "Dumbbell" }
    
    return "Barbell" // Default fallback
}

private func getExerciseName(exerciseId: String) -> String {
    let names: [String: String] = [
        "ex-1": "Bench Press",
        "ex-2": "Squat",
        "ex-3": "Deadlift",
        "ex-4": "Overhead Press",
        "ex-5": "Barbell Row",
        "ex-6": "Pull-Up",
        "ex-10": "Lat Pulldown",
        "ex-11": "Incline DB Press",
        "ex-12": "DB Fly",
        "ex-22": "Cable Crossover",
        "ex-25": "Pec Deck",
        "ex-28": "DB Bench Press",
        "ex-31": "Decline DB Press",
        "ex-34": "Decline Bench",
        "ex-37": "Push-Up",
        "ex-38": "Seated Row",
        "ex-39": "Single-Arm Row",
        "ex-40": "T-Bar Row",
        "ex-43": "RDL",
        "ex-44": "Straight-Arm Pulldown",
        "ex-48": "Chest-Supported Row",
        "ex-50": "Close-Grip Pulldown",
        "ex-52": "Kneeling Pulldown",
        "ex-60": "DB Shoulder Press",
        "ex-67": "Lateral Raise",
        "ex-68": "Front Raise",
        "ex-70": "Reverse Fly",
        "ex-98": "Trap Bar Deadlift",
        "ex-101": "Leg Press",
        "ex-108": "Hack Squat",
        "ex-109": "Bulgarian Split Squat",
        "ex-113": "Goblet Squat",
        "ex-160": "Front Squat"
    ]
    return names[exerciseId] ?? "Unknown"
}

private func isCompoundExercise(exerciseId: String) -> Bool {
    let compoundIds = ["ex-1", "ex-2", "ex-3", "ex-4", "ex-5", "ex-6", "ex-10",
                       "ex-98", "ex-101", "ex-108", "ex-109", "ex-113", "ex-160"]
    return compoundIds.contains(exerciseId)
}