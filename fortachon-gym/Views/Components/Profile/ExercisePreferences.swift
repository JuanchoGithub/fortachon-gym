import Foundation

// MARK: - Exercise Difficulty

public enum ExerciseDifficulty: String, Codable, CaseIterable {
    case beginner, intermediate, advanced
    
    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    public var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "orange"
        case .advanced: return "red"
        }
    }
}

// MARK: - Exercise Preferences Manager

@MainActor
public class ExercisePreferences {
    public static let shared = ExercisePreferences()
    
    private let favoritesKey = "fortachon_favorite_exercises"
    private let lastUsedKey = "fortachon_exercise_last_used"
    private let difficultyKey = "fortachon_exercise_difficulty"
    private let customExercisesKey = "fortachon_custom_exercises_ids"
    
    private init() {}
    
    // MARK: - Favorites
    
    public var favoriteExerciseIds: Set<String> {
        get {
            let ids = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
            return Set(ids)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: favoritesKey)
        }
    }
    
    public func isFavorite(_ exerciseId: String) -> Bool {
        return favoriteExerciseIds.contains(exerciseId)
    }
    
    public func toggleFavorite(_ exerciseId: String) {
        var favorites = favoriteExerciseIds
        if favorites.contains(exerciseId) {
            favorites.remove(exerciseId)
        } else {
            favorites.insert(exerciseId)
        }
        favoriteExerciseIds = favorites
    }
    
    public func setFavorite(_ exerciseId: String, favorite: Bool) {
        var favorites = favoriteExerciseIds
        if favorite {
            favorites.insert(exerciseId)
        } else {
            favorites.remove(exerciseId)
        }
        favoriteExerciseIds = favorites
    }
    
    // MARK: - Last Used Tracking
    
    public func recordExerciseUsed(_ exerciseId: String) {
        UserDefaults.standard.set(Date(), forKey: "\(lastUsedKey).\(exerciseId)")
    }
    
    public func lastUsedDate(for exerciseId: String) -> Date? {
        return UserDefaults.standard.object(forKey: "\(lastUsedKey).\(exerciseId)") as? Date
    }
    
    public func daysSinceLastUsed(_ exerciseId: String) -> Int? {
        guard let date = lastUsedDate(for: exerciseId) else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }
    
    public func lastUsedFormatted(_ exerciseId: String) -> String? {
        guard let days = daysSinceLastUsed(exerciseId) else { return nil }
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days)d ago"
        } else if days < 30 {
            return "\(days / 7)w ago"
        } else {
            return "\(days / 30)mo ago"
        }
    }
    
    // MARK: - Difficulty
    
    public func setDifficulty(_ exerciseId: String, difficulty: ExerciseDifficulty) {
        UserDefaults.standard.set(difficulty.rawValue, forKey: "\(difficultyKey).\(exerciseId)")
    }
    
    public func getDifficulty(_ exerciseId: String) -> ExerciseDifficulty? {
        guard let raw = UserDefaults.standard.string(forKey: "\(difficultyKey).\(exerciseId)"),
              let difficulty = ExerciseDifficulty(rawValue: raw) else {
            return nil
        }
        return difficulty
    }
    
    // MARK: - Custom Exercise Tracking
    
    public func markExerciseAsCustom(_ exerciseId: String) {
        var customs = customExerciseIds
        customs.insert(exerciseId)
        customExerciseIds = customs
    }
    
    public var customExerciseIds: Set<String> {
        get {
            let ids = UserDefaults.standard.stringArray(forKey: customExercisesKey) ?? []
            return Set(ids)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: customExercisesKey)
        }
    }
    
    public func isCustomExercise(_ exerciseId: String) -> Bool {
        return customExerciseIds.contains(exerciseId)
    }
}