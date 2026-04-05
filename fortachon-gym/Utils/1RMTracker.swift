import Foundation

// MARK: - 1RM Record

struct OneRMRecord: Codable, Identifiable {
    let id: UUID
    let exerciseId: String
    let exerciseName: String
    let estimated1RM: Double
    let weight: Double
    let reps: Int
    let date: Date
    
    init(
        id: UUID = UUID(),
        exerciseId: String,
        exerciseName: String,
        estimated1RM: Double,
        weight: Double,
        reps: Int,
        date: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.estimated1RM = estimated1RM
        self.weight = weight
        self.reps = reps
        self.date = date
    }
}

// MARK: - 1RM Tracker

@MainActor
final class OneRMTracker {
    
    // MARK: - Constants
    
    private static let storageKey = "fortachon_1rm_records"
    private static let current1RMsKey = "fortachon_current_1rms"
    private static let improvementThreshold = 0.025 // 2.5%
    
    // MARK: - Storage
    
    /// Get all 1RM records.
    func getAllRecords() -> [OneRMRecord] {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return [] }
        return (try? JSONDecoder().decode([OneRMRecord].self, from: data)) ?? []
    }
    
    /// Save a new 1RM record.
    func saveRecord(_ record: OneRMRecord) {
        var records = getAllRecords()
        records.append(record)
        records.sort { $0.date > $1.date }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
    
    /// Get current 1RM for an exercise.
    func getCurrent1RM(for exerciseId: String) -> Double {
        guard let data = UserDefaults.standard.data(forKey: Self.current1RMsKey),
              let dict = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return 0
        }
        return dict[exerciseId] ?? 0
    }
    
    /// Update current 1RM for an exercise.
    func updateCurrent1RM(for exerciseId: String, to value: Double) {
        var dict: [String: Double] = [:]
        if let data = UserDefaults.standard.data(forKey: Self.current1RMsKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            dict = decoded
        }
        dict[exerciseId] = value
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: Self.current1RMsKey)
        }
    }
    
    // MARK: - Detection
    
    /// Detect if a set represents a new 1RM.
    /// - Parameters:
    ///   - exerciseId: The exercise ID
    ///   - exerciseName: The exercise name
    ///   - weight: Weight used
    ///   - reps: Reps completed
    /// - Returns: New 1RM record if detected, nil otherwise
    func detectNew1RM(
        exerciseId: String,
        exerciseName: String,
        weight: Double,
        reps: Int
    ) -> OneRMRecord? {
        guard reps > 0 && weight > 0 else { return nil }
        
        let current1RM = getCurrent1RM(for: exerciseId)
        
        // Use Epley formula: 1RM = weight × (1 + reps/30)
        let estimated1RM = weight * (1.0 + Double(reps) / 30.0)
        
        // Check if this is a meaningful improvement
        if current1RM == 0 || estimated1RM > current1RM * (1 + Self.improvementThreshold) {
            let record = OneRMRecord(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                estimated1RM: estimated1RM,
                weight: weight,
                reps: reps
            )
            saveRecord(record)
            updateCurrent1RM(for: exerciseId, to: estimated1RM)
            return record
        }
        
        return nil
    }
    
    // MARK: - History
    
    /// Get 1RM history for a specific exercise.
    func getHistory(for exerciseId: String) -> [OneRMRecord] {
        getAllRecords().filter { $0.exerciseId == exerciseId }
    }
    
    /// Get all unique exercises with 1RM records.
    func getExercisesWithRecords() -> [String: String] {
        let records = getAllRecords()
        var dict: [String: String] = [:]
        for record in records {
            if dict[record.exerciseId] == nil {
                dict[record.exerciseId] = record.exerciseName
            }
        }
        return dict
    }
    
    /// Get the latest 1RM for each exercise.
    func getLatest1RMs() -> [String: OneRMRecord] {
        var dict: [String: OneRMRecord] = [:]
        for record in getAllRecords() {
            if dict[record.exerciseId] == nil {
                dict[record.exerciseId] = record
            }
        }
        return dict
    }
    
    /// Clear all 1RM data.
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        UserDefaults.standard.removeObject(forKey: Self.current1RMsKey)
    }
}