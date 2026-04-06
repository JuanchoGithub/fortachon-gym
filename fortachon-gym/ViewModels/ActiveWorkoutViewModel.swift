import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Progression Result & Stale Info

struct ProgressionResult: Identifiable {
    let id = UUID()
    let exerciseId: String
    let exerciseName: String
    let isRepPR: Bool
    let oldMaxReps: Int
    let newMaxReps: Int
    let weight: Double
    let shouldIncreaseWeight: Bool
    let suggestedNewWeight: Double
}

struct StaleWorkoutInfo {
    let lastActivity: Date
    let hoursInactive: Int
    let completedSets: Int
    let totalSets: Int
}

// MARK: - Active Workout ViewModel

@MainActor
class ActiveWorkoutViewModel: ObservableObject {
    @Published var session: WorkoutSessionM
    @Published var showRestTimer = false
    @Published var restRemaining: TimeInterval = 0
    @Published var restTotal: TimeInterval = 0
    @Published var isMinimized = false
    @Published var isReorderMode = false
    @Published var pendingReorderState: SnapshotState?
    @Published var pending1RMUpdates: [(exerciseName: String, oldMax: Double, newMax: Double)] = []
    @Published var progressionResults: [ProgressionResult] = []
    @Published var showStaleModal = false
    @Published var staleWorkoutInfo: StaleWorkoutInfo?
    @Published var validationErrors: [String] = []
    @Published var elapsed: TimeInterval = 0
    @Published var expandedIds: Set<String> = []
    @Published var coachSuggestions: [UpgradeSuggestion] = []
    @Published var historicalData: [String: (avgWeight: Double, avgReps: Int)] = [:]
    
    let audioCoach: AudioCoach
    private let modelContext: ModelContext
    private var timerTask: Task<Void, Never>?
    private let sessionStartTime: Date
    
    init(session: WorkoutSessionM, modelContext: ModelContext) {
        self.session = session
        self.modelContext = modelContext
        self.sessionStartTime = session.startTime
        self.audioCoach = AudioCoach()
    }
    
    // MARK: - Timer
    
    func startTimer() {
        timerTask = Task.detached { [start = self.sessionStartTime] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                if !Task.isCancelled {
                    await MainActor.run {
                        self.elapsed = Date().timeIntervalSince(start)
                    }
                }
            }
        }
    }
    
    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    // MARK: - Set Completion
    
    func completeSet(
        exerciseIndex: Int,
        setIndex: Int,
        exerciseDef: ExerciseM?,
        onSetComplete: ((PerformedSetM) -> Void)? = nil
    ) {
        guard exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        
        let set = session.exercises[exerciseIndex].sets[setIndex]
        set.isComplete = !set.isComplete
        
        if set.isComplete {
            set.completedAt = Date()
            
            // Set type for rest timer
            let setType = SetType(rawValue: set.setTypeStr) ?? .normal
            restRemaining = TimeInterval(restFor(setType))
            restTotal = restRemaining
            showRestTimer = true
            
            // Audio announcement
            let exerciseName = exerciseDef?.name ?? session.exercises[exerciseIndex].exerciseId
            let setNumber = session.exercises[exerciseIndex].sets.prefix(setIndex + 1)
                .filter { $0.setTypeStr == set.setTypeStr }.count
            audioCoach.announceSetComplete(
                exerciseName: exerciseName,
                setNumber: setNumber,
                weight: set.weight,
                reps: set.reps
            )
            
            // Historical comparison
            if let hist = historicalData[session.exercises[exerciseIndex].exerciseId] {
                set.historicalWeight = hist.avgWeight
                set.historicalReps = hist.avgReps
            }
            
            // Check progression
            if let result = checkAndApplyProgression(
                exerciseIndex: exerciseIndex,
                exerciseDef: exerciseDef
            ) {
                progressionResults.append(result)
                // Check for 1RM update
                let newE1RM = ProgressionUtils.estimate1RM(
                    weight: result.weight,
                    reps: result.newMaxReps
                )
                pending1RMUpdates.append((
                    exerciseName: result.exerciseName,
                    oldMax: 0, // Will be set externally
                    newMax: newE1RM
                ))
            }
            
            onSetComplete?(set)
            
            // Announce rest complete via notification
            if restTotal > 0 {
                scheduleRestTimerNotification(after: Int(restTotal))
            }
        } else {
            set.completedAt = nil
        }
    }
    
    // MARK: - Set Editing
    
    func addSet(exerciseIndex: Int) {
        guard exerciseIndex < session.exercises.count else { return }
        let ex = session.exercises[exerciseIndex]
        let last = ex.sets.last
        let lastWeight = last?.weight ?? 0
        let lastReps = last?.reps ?? 0
        let lastType = last?.setTypeStr ?? "normal"
        ex.sets.append(PerformedSetM(
            id: "set-\(UUID())",
            reps: lastReps,
            weight: lastWeight,
            type: lastType
        ))
    }
    
    func updateSetWeight(exerciseIndex: Int, setIndex: Int, weight: Double) {
        guard exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        session.exercises[exerciseIndex].sets[setIndex].weight = weight
    }
    
    func updateSetReps(exerciseIndex: Int, setIndex: Int, reps: Int) {
        guard exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        session.exercises[exerciseIndex].sets[setIndex].reps = reps
    }
    
    func updateSetRPE(exerciseIndex: Int, setIndex: Int, rpe: Int) {
        guard exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        session.exercises[exerciseIndex].sets[setIndex].rpe = rpe
    }
    
    func updateSetType(exerciseIndex: Int, setIndex: Int, type: SetType) {
        guard exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        session.exercises[exerciseIndex].sets[setIndex].setTypeStr = type.rawValue
    }
    
    // MARK: - Rest Timer
    
    func startRestTimer(seconds: Int) {
        restRemaining = TimeInterval(seconds)
        restTotal = TimeInterval(seconds)
        showRestTimer = true
    }
    
    // MARK: - Progression
    
    func checkAndApplyProgression(
        exerciseIndex: Int,
        exerciseDef: ExerciseM?
    ) -> ProgressionResult? {
        guard exerciseIndex < session.exercises.count else { return nil }
        
        let ex = session.exercises[exerciseIndex]
        let exerciseId = ex.exerciseId
        let exerciseName = exerciseDef?.name ?? exerciseId
        
        // Find max reps at current weight (±5kg tolerance)
        let weightTolerance: Double = 5.0
        let completedSets = ex.sets.filter { $0.isComplete && $0.setTypeStr == "normal" }
        guard let currentSet = completedSets.last else { return nil }
        
        let historicalMaxReps = ProgressionUtils.getHistoricalMaxReps(
            exerciseId: exerciseId,
            targetWeight: currentSet.weight,
            weightTolerance: weightTolerance,
            modelContext: modelContext
        )
        
        let currentMaxReps = ex.sets
            .filter { $0.isComplete && $0.setTypeStr == "normal" }
            .map { $0.reps }
            .max() ?? 0
        
        if currentMaxReps > historicalMaxReps && currentSet.weight > 0 {
            // Determine if upper or lower body
            let isUpperBody = ExerciseUtils.isUpperBody(exerciseId: exerciseId)
            
            // Calculate suggested weight increase
            let newWeight = ProgressionUtils.autoIncreaseWeight(
                currentWeight: currentSet.weight,
                isUpperBody: isUpperBody
            )
            
            return ProgressionResult(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                isRepPR: true,
                oldMaxReps: historicalMaxReps,
                newMaxReps: currentMaxReps,
                weight: currentSet.weight,
                shouldIncreaseWeight: newWeight > currentSet.weight,
                suggestedNewWeight: newWeight
            )
        }
        
        return nil
    }
    
    // MARK: - Stale Detection
    
    func checkWorkoutStaleness() -> Bool {
        let hoursSinceStart = Date().timeIntervalSince(sessionStartTime) / 3600.0
        if hoursSinceStart >= 3.0 {
            let completedSets = session.exercises.reduce(0) { sum, ex in
                sum + ex.sets.filter { $0.isComplete }.count
            }
            let totalSets = session.exercises.reduce(0) { $0 + $1.sets.count }
            
            staleWorkoutInfo = StaleWorkoutInfo(
                lastActivity: sessionStartTime,
                hoursInactive: Int(hoursSinceStart),
                completedSets: completedSets,
                totalSets: totalSets
            )
            showStaleModal = true
            return true
        }
        return false
    }
    
    // MARK: - Validation
    
    func validateWorkout() -> [String] {
        var errors: [String] = []
        if session.exercises.isEmpty {
            errors.append("No exercises added. Add at least one exercise to finish.")
        }
        for ex in session.exercises {
            let hasCompletedSets = ex.sets.contains { $0.isComplete }
            if !hasCompletedSets {
                let name = ex.exerciseId
                errors.append("\"\(name)\" has no completed sets.")
            }
        }
        return errors
    }
    
    // MARK: - End Workout
    
    func endWorkout(onComplete: @escaping () -> Void) {
        session.endTime = Date()
        modelContext.insert(session)
        try? modelContext.save()
        stopTimer()
        onComplete()
    }
    
    // MARK: - Historical Data
    
    func loadHistoricalData(allExercises: [ExerciseM]) {
        let lookup = HistoricalLookup(modelContext: modelContext)
        var data: [String: (avgWeight: Double, avgReps: Int)] = [:]
        for ex in session.exercises {
            if let hist = lookup.getLastSessionValues(for: ex.exerciseId) {
                data[ex.exerciseId] = hist
            }
        }
        historicalData = data
    }
    
    func generateSuggestions(allExercises: [ExerciseM]) {
        let exerciseIds = session.exercises.map { $0.exerciseId }
        let lookup = HistoricalLookup(modelContext: modelContext)
        let frequency = lookup.getExerciseFrequency()
        coachSuggestions = UpgradeSuggestions.generate(
            currentExerciseIds: exerciseIds,
            allExercises: allExercises,
            frequency: frequency
        )
    }
    
    // MARK: - Expansion & Exercise Management
    
    func toggleExpand(_ id: String) {
        if expandedIds.contains(id) {
            expandedIds.remove(id)
        } else {
            expandedIds.insert(id)
        }
    }
    
    func handleUpgrade(_ suggestion: UpgradeSuggestion) {
        guard let idx = session.exercises.firstIndex(where: { $0.exerciseId == suggestion.currentExerciseId }) else { return }
        session.exercises[idx].exerciseId = suggestion.targetExerciseId
        coachSuggestions.removeAll { $0.id == suggestion.id }
    }
    
    func addExercise(_ id: String) {
        let we = WorkoutExerciseM(id: "we-\(UUID())", exerciseId: id)
        we.sets.append(PerformedSetM(id: "w1", reps: 0, weight: 0, type: "warmup"))
        for _ in 0..<3 {
            we.sets.append(PerformedSetM(id: "set-\(UUID())", reps: 0, weight: 0, type: "normal"))
        }
        session.exercises.append(we)
        expandedIds.insert(we.weId)
        generateSuggestions(allExercises: [])
    }
    
    // MARK: - Helpers
    
    private func restFor(_ t: SetType) -> Int {
        switch t {
        case .warmup: return 60
        case .drop: return 30
        case .failure: return 300
        case .timed: return 10
        default: return 90
        }
    }
    
    private func scheduleRestTimerNotification(after seconds: Int) {
        // Use local notification or just the in-app timer
        // This is handled by the RestTimerView overlay
    }
}

// MARK: - Progression Utilities

enum ProgressionUtils {
    /// Calculate estimated 1RM using Brzycki formula
    static func estimate1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        guard reps <= 36 else { return weight } // Formula breaks beyond 36 reps
        let result = weight * (36.0 / (37.0 - Double(reps)))
        return round(result * 10) / 10 // Round to 1 decimal
    }
    
    /// Calculate suggested weight increase
    static func autoIncreaseWeight(currentWeight: Double, isUpperBody: Bool) -> Double {
        let increment: Double = isUpperBody ? 2.5 : 5.0
        let newWeight = currentWeight + increment
        // Round to nearest 0.5 or 1.0
        return round(newWeight * 2) / 2
    }
    
    /// Get historical max reps for an exercise at a given weight
    @MainActor static func getHistoricalMaxReps(
        exerciseId: String,
        targetWeight: Double,
        weightTolerance: Double,
        modelContext: ModelContext
    ) -> Int {
        let lookup = HistoricalLookup(modelContext: modelContext)
        let sessions = lookup.getRecentSessions(limit: 50)
        var maxReps = 0
        
        for session in sessions {
            for ex in session.exercises where ex.exerciseId == exerciseId {
                for set in ex.sets where set.isComplete && set.setTypeStr == "normal" {
                    let weightDiff = abs(set.weight - targetWeight)
                    if weightDiff <= weightTolerance && set.reps > maxReps {
                        maxReps = set.reps
                    }
                }
            }
        }
        
        return maxReps
    }
}

// MARK: - Exercise Utilities

enum ExerciseUtils {
    static func isUpperBody(exerciseId: String) -> Bool {
        let upperBodyPrefixes = ["ex-1", "ex-4", "ex-5", "ex-6", "ex-7", "ex-8",
                                "ex-10", "ex-11", "ex-12", "ex-13", "ex-14",
                                "ex-21", "ex-22", "ex-23", "ex-24", "ex-25",
                                "ex-26", "ex-27", "ex-28", "ex-29", "ex-30",
                                "ex-31", "ex-32", "ex-33", "ex-34", "ex-35",
                                "ex-36", "ex-37", "ex-38", "ex-39", "ex-40",
                                "ex-41", "ex-42", "ex-44", "ex-47", "ex-48",
                                "ex-49", "ex-50", "ex-51", "ex-52", "ex-53",
                                "ex-54", "ex-55", "ex-56", "ex-57", "ex-58",
                                "ex-63", "ex-64", "ex-65", "ex-66", "ex-67",
                                "ex-68", "ex-69", "ex-70", "ex-71", "ex-72",
                                "ex-73", "ex-74", "ex-75", "ex-76", "ex-77",
                                "ex-78", "ex-79", "ex-80", "ex-81", "ex-82",
                                "ex-83", "ex-84", "ex-85"]
        return upperBodyPrefixes.contains(exerciseId)
    }
}