import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Muscle Recovery Constants

/// Standard recovery times for each muscle group in hours based on anatomical muscles
public let muscleRecoveryTimes: [String: Int] = [
    Muscle.abs: 24,
    Muscle.forearms: 24,
    Muscle.calves: 48,
    Muscle.biceps: 48,
    Muscle.triceps: 48,
    Muscle.sideDelts: 48,
    Muscle.rearDelts: 48,
    Muscle.rotatorCuff: 48,
    Muscle.pectorals: 72,
    Muscle.upperChest: 72,
    Muscle.lowerChest: 72,
    Muscle.lats: 72,
    Muscle.frontDelts: 60,
    Muscle.traps: 60,
    Muscle.rhomboids: 60,
    Muscle.hipFlexors: 60,
    Muscle.adductors: 72,
    Muscle.abductors: 72,
    Muscle.quads: 96,
    Muscle.hamstrings: 96,
    Muscle.glutes: 96,
    Muscle.lowerBack: 96,
    Muscle.spinalErectors: 96,
]

public let defaultRecoveryHours = 72

// MARK: - Session Density Calculation

/// Calculates volume/minute density for a session
public func calculateSessionDensity(_ exercises: [WorkoutExercise], startTime: Date, endTime: Date) -> Double {
    let durationMinutes = endTime.timeIntervalSince(startTime) / 60.0
    guard durationMinutes >= 5 else { return 0 }
    
    let totalVolume = exercises.reduce(0.0) { acc, ex in
        acc + ex.sets.reduce(0.0) { setAcc, set in
            setAcc + (set.isComplete ? (set.weight * Double(set.reps)) : 0)
        }
    }
    
    return totalVolume / durationMinutes
}

/// Calculates average density from history
public func calculateAverageDensity(_ sessions: [(exercises: [WorkoutExercise], startTime: Date, endTime: Date)], limit: Int = 10) -> Double {
    let densities = sessions.prefix(limit).map { calculateSessionDensity($0.exercises, startTime: $0.startTime, endTime: $0.endTime) }.filter { $0 > 0 }
    guard !densities.isEmpty else { return 0 }
    return densities.reduce(0, +) / Double(densities.count)
}

// MARK: - Muscle Freshness Calculation

/// Calculates freshness for each muscle based on workout history (advanced version with anatomical muscles)
/// - Parameters:
///   - sessions: Array of past workout sessions (most recent first) with exercises, start/end times
///   - exercises: All available exercise definitions
///   - capacityBaseline: Base capacity (15 for muscle, 10 for strength, 20 for endurance)
///   - lookbackHours: How far back to consider (default 144h = 6 days)
///   - bioAdaptiveEnabled: Whether to apply adaptive recovery modifier
public func calculateMuscleFreshnessAdvanced(
    sessions: [(exercises: [WorkoutExercise], startTime: Date, endTime: Date)],
    exercises: [Exercise],
    capacityBaseline: Double = 15.0,
    lookbackHours: Double = 144.0,
    bioAdaptiveEnabled: Bool = false
) -> [MuscleFreshness] {
    let now = Date()
    let lookbackInterval = lookbackHours * 3600
    
    // Filter relevant history
    let relevantSessions = sessions.filter { now.timeIntervalSince($0.startTime) < lookbackInterval }
    guard !relevantSessions.isEmpty else { return [] }
    
    // Calculate recovery efficiency multiplier
    var recoveryEfficiencyMult: Double = 1.0
    if bioAdaptiveEnabled, sessions.count >= 2 {
        let lastDensity = calculateSessionDensity(sessions[0].exercises, startTime: sessions[0].startTime, endTime: sessions[0].endTime)
        let avgDensity = calculateAverageDensity(Array(sessions.dropFirst()), limit: 5)
        if lastDensity > 0 && avgDensity > 0 {
            let ratio = lastDensity / avgDensity
            recoveryEfficiencyMult = max(0.8, min(1.2, 1.0 / ratio))
        }
    }
    
    // Build exercise lookup map
    let exerciseMap = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    
    // Accumulate fatigue per muscle
    var muscleFatigueAccumulation: [String: Double] = [:]
    var muscleLastWorkout: [String: Date] = [:]
    var muscleVolume: [String: Double] = [:]
    
    for session in relevantSessions {
        let hoursAgo = now.timeIntervalSince(session.startTime) / 3600.0
        
        for ex in session.exercises {
            guard let def = exerciseMap[ex.exerciseId] else { continue }
            
            // Calculate stress units from completed sets
            var stressUnits: Double = 0
            for set in ex.sets {
                guard set.isComplete else { continue }
                
                var intensityMult: Double = 1.0
                if set.reps > 0 && set.reps <= 6 {
                    intensityMult = 1.65
                } else if set.reps > 12 {
                    intensityMult = 0.8
                }
                
                switch set.type {
                case .failure: intensityMult += 0.3
                case .drop: intensityMult += 0.1
                case .warmup: intensityMult = 0.5
                default: break
                }
                
                stressUnits += intensityMult
            }
            
            guard stressUnits > 0 else { continue }
            
            let appliedStress = stressUnits * recoveryEfficiencyMult
            
            // Track volume for primary muscles
            let sessionVolume = ex.sets.reduce(0.0) { acc, set in
                acc + (set.isComplete ? (set.weight * Double(set.reps)) : 0)
            }
            
            // Accumulate fatigue for primary muscles
            let primaryMuscles = def.primaryMuscles ?? []
            let secondaryMuscles = def.secondaryMuscles ?? []
            let allMuscles = Set(primaryMuscles + secondaryMuscles)
            for muscle in allMuscles {
                let recoveryDuration = Double(muscleRecoveryTimes[muscle] ?? defaultRecoveryHours)
                guard hoursAgo < recoveryDuration else { continue }
                
                let timeFactor = 1.0 - (hoursAgo / recoveryDuration)
                let isPrimary = primaryMuscles.contains(muscle)
                let stressMultiplier = isPrimary ? 1.0 : 0.5
                let fatigue = ((appliedStress * stressMultiplier) / capacityBaseline) * 100.0 * timeFactor
                
                muscleFatigueAccumulation[muscle, default: 0] += fatigue
                
                // Track most recent workout date
                if let existing = muscleLastWorkout[muscle] {
                    if session.startTime > existing {
                        muscleLastWorkout[muscle] = session.startTime
                    }
                } else {
                    muscleLastWorkout[muscle] = session.startTime
                }
                
                // Track volume
                muscleVolume[muscle, default: 0] += sessionVolume * stressMultiplier
            }
        }
    }
    
    // Convert to freshness results
    var results: [MuscleFreshness] = []
    for (muscle, fatigue) in muscleFatigueAccumulation {
        let freshness = max(0, 100.0 - fatigue)
        results.append(MuscleFreshness(
            muscleName: formatMuscleName(muscle),
            freshnessPercent: round(freshness),
            lastWorkoutDate: muscleLastWorkout[muscle],
            volumeInWindow: muscleVolume[muscle] ?? 0
        ))
    }
    
    return results.sorted { $0.muscleName < $1.muscleName }
}


/// Formats muscle key to display name
public func formatMuscleName(_ key: String) -> String {
    let muscleDisplayNames: [String: String] = [
        Muscle.abs: "Abs",
        Muscle.forearms: "Forearms",
        Muscle.calves: "Calves",
        Muscle.biceps: "Biceps",
        Muscle.triceps: "Triceps",
        Muscle.sideDelts: "Side Delts",
        Muscle.rearDelts: "Rear Delts",
        Muscle.rotatorCuff: "Rotator Cuff",
        Muscle.pectorals: "Chest",
        Muscle.upperChest: "Upper Chest",
        Muscle.lowerChest: "Lower Chest",
        Muscle.lats: "Lats",
        Muscle.frontDelts: "Front Delts",
        Muscle.traps: "Traps",
        Muscle.rhomboids: "Rhomboids",
        Muscle.hipFlexors: "Hip Flexors",
        Muscle.adductors: "Adductors",
        Muscle.abductors: "Abductors",
        Muscle.quads: "Quads",
        Muscle.hamstrings: "Hamstrings",
        Muscle.glutes: "Glutes",
        Muscle.lowerBack: "Lower Back",
        Muscle.spinalErectors: "Spinal Erectors",
    ]
    return muscleDisplayNames[key] ?? key.capitalized
}

// MARK: - Muscle Freshness for Exercise Lookup

/// Get the muscle freshness percentage for a specific exercise
/// Returns the average freshness of all primary muscles, or nil if no data
public func getExerciseFreshness(
    exerciseId: String,
    freshnessData: [MuscleFreshness],
    exercises: [Exercise]
) -> Double? {
    guard let exercise = exercises.first(where: { $0.id == exerciseId }) else { return nil }
    
    let musclesToCheck = exercise.primaryMuscles ?? []
    guard !musclesToCheck.isEmpty else { return nil }
    
    let freshnessMap = Dictionary(uniqueKeysWithValues: freshnessData.map { ($0.muscleName, $0.freshnessPercent) })
    
    var totalFreshness: Double = 0
    var count = 0
    for muscle in musclesToCheck {
        let displayName = formatMuscleName(muscle)
        if let freshness = freshnessMap[displayName] {
            totalFreshness += freshness
            count += 1
        }
    }
    
    guard count > 0 else { return nil }
    return totalFreshness / Double(count)
}

// MARK: - Freshness Color Utility

/// Get color for freshness percentage
public func getFreshnessColor(_ percent: Double) -> SwiftUI.Color {
    let pct = max(0, min(100, percent))
    if pct <= 20 {
        // Red to orange
        return SwiftUI.Color(red: 0.9, green: 0.2 + pct * 0.015, blue: 0.1)
    } else if pct <= 60 {
        // Orange to yellow-green
        let t = (pct - 20) / 40.0
        return SwiftUI.Color(red: 0.9 - t * 0.3, green: 0.5 + t * 0.3, blue: 0.1)
    } else {
        // Yellow-green to green
        let t = (pct - 60) / 40.0
        return SwiftUI.Color(red: 0.2 + t * 0.1, green: 0.7 + t * 0.3, blue: 0.1 + t * 0.1)
    }
}

// MARK: - Systemic Fatigue

/// Calculates overall systemic fatigue level
public func calculateSystemicFatigue(
    sessions: [(exercises: [WorkoutExercise], startTime: Date, endTime: Date)],
    exercises: [Exercise]
) -> (score: Double, level: String) {
    let now = Date()
    let twoWeeks: TimeInterval = 14 * 24 * 3600
    let recent = sessions.filter { now.timeIntervalSince($0.startTime) < twoWeeks }
    
    var fatiguePoints: Double = 0
    for session in recent {
        let daysAgo = now.timeIntervalSince(session.startTime) / (24 * 3600)
        let decay = max(0, 1.0 - (daysAgo / 10.0))
        
        var sessionCost: Double = 5
        let completedSets = session.exercises.reduce(0) { acc, ex in
            acc + ex.sets.filter { $0.isComplete }.count
        }
        
        var compoundFactor: Double = 0
        for ex in session.exercises {
            let def = exercises.first { $0.id == ex.exerciseId }
            if let def = def,
               ["Barbell", "Dumbbell"].contains(def.category.rawValue),
               ["Legs", "Back", "Chest"].contains(def.bodyPart.rawValue) {
                compoundFactor += 1
            }
        }
        
        sessionCost += Double(completedSets) + (compoundFactor * 2)
        fatiguePoints += sessionCost * decay
    }
    
    let score = min(100, round((fatiguePoints / 150) * 100))
    let level: String
    if score > 60 { level = "High" }
    else if score > 30 { level = "Medium" }
    else { level = "Low" }
    
    return (score, level)
}