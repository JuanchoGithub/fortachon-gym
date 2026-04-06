import SwiftUI
import FortachonCore

// MARK: - Progression Result

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

// MARK: - Active Workout ViewModel
// Note: This ViewModel is unused — ActiveWorkoutView handles all workout logic directly.
// Kept for backward compatibility with project references.

@MainActor
class ActiveWorkoutViewModel: ObservableObject {
    @Published var showRestTimer = false
    @Published var restRemaining: TimeInterval = 0
    @Published var restTotal: TimeInterval = 0
    @Published var isMinimized = false
    @Published var pending1RMUpdates: [(exerciseName: String, oldMax: Double, newMax: Double)] = []
    @Published var progressionResults: [ProgressionResult] = []
    @Published var showStaleModal = false
}