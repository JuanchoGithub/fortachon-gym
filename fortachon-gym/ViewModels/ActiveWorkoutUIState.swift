import SwiftUI
import FortachonCore

// MARK: - SnapshotState (for reorder undo)

struct SnapshotState {
    var exerciseOrder: [String] = []
    var exercises: [(weId: String, exerciseId: String, supersetId: String?, sets: [(id: String, reps: Int, weight: Double, type: String)])] = []
}

// MARK: - PromotionBannerState

struct PromotionBannerState: Identifiable {
    let id = UUID()
    let exerciseIndex: Int
    let targetExerciseId: String
    let targetExerciseName: String
}

// MARK: - Active Workout UI State
// P0 #2: Centralizes ALL UI state from ActiveWorkoutView (~35 @State properties).
// This class is @Observable so changes automatically trigger view recalculation.
// All properties in ActiveWorkoutView that have a counterpart here must be removed
// and replaced with uiState.propertyName references.

@Observable
class ActiveWorkoutUIState {
    
    // MARK: - Exercise Expansion & Navigation
    
    var expandedIds: Set<String> = []
    var collapsedSupersetIds: Set<String> = []
    var scrollToExerciseId: String? = nil
    
    // MARK: - Mode Flags
    
    var isReorderMode = false
    var pendingReorderState: SnapshotState?
    var draggedExerciseIndex: Int? = nil
    
    // MARK: - Sheet Presentation
    
    var showAddExercise = false
    var showNotesEditor = false
    var showWorkoutDetailsModal = false
    var showSupersetManager = false
    var showSupersetPlayer = false
    var supersetPlayerId: String? = nil
    var showPlateCalculator = false
    var showExerciseDetails = false
    var showRPEEditor = false
    var detailsExerciseDef: FortachonCore.ExerciseM?
    
    // MARK: - Validation & Confirmation
    
    var showFinishConfirmation = false
    var showValidationErrors = false
    var showStaleWorkoutModal = false
    
    // MARK: - Rest Timer (Inline Overlay)
    
    var showRestTimer = false
    var restRemaining: TimeInterval = 0
    var restTotal: TimeInterval = 0
    var activeRestExerciseIndex: Int? = nil
    var activeRestExerciseName = ""
    
    // MARK: - RPE Editor
    
    var rpeEditingExerciseIndex: Int? = nil
    var rpeEditingSetIndex: Int? = nil
    
    // MARK: - Rest Config
    
    var showRestConfig = false
    var restConfigExerciseIndex: Int? = nil
    
    // MARK: - Per-Exercise Notes Editing
    
    var notesExerciseIndex: Int? = nil
    var exerciseNoteText = ""
    var showExerciseNoteEditor = false
    
    // MARK: - Bodyweight Input
    
    var showBodyweightInput = false
    var bodyweightInput: Double = 0
    var bodyweightExerciseIndex: Int? = nil
    
    // MARK: - Timed Set
    
    var showSetTimer = false
    var setTimerRemaining: TimeInterval = 0
    var setTimerTotal: TimeInterval = 0
    var showTimedSetStart = false
    var timedSetExerciseIndex: Int? = nil
    var timedSetCountdown = 3
    
    // MARK: - Coach Suggestion
    
    var showCoachSuggestion = false
    var coachSuggestionResult: CoachSuggestionResult?
    
    // MARK: - Exercise Upgrade/Rollback
    
    var showingUpgradeAlert: (exerciseWeId: String, targetExerciseId: String, targetName: String)? = nil
    var exerciseUpgrades: [String: String] = [:]
    var showExercisePicker = false
    var upgradePickerExerciseIndex: Int?
    
    // MARK: - Smart Weight Suggestion (Phase 3)
    
    var showWeightSuggestion = false
    var weightSuggestion: (exerciseName: String, currentWeight: Double, suggestedWeight: Double, setIndex: Int, exerciseIndex: Int)? = nil
    
    // MARK: - Insight & Promotion Banners
    
    var insightBannerState: InsightBannerState? = nil
    var promotionBannerState: PromotionBannerState? = nil
    
    // MARK: - Muscle Freshness
    
    var showFreshnessDetail = false
    var freshnessDetailExerciseId = ""
    
    // MARK: - Set Completion Animation
    
    var completedSetAnimation: Set<String> = []
    
    // MARK: - Auto 1RM Updates
    
    var pending1RMUpdates: [(exerciseName: String, oldMax: Double, newMax: Double)] = []
    var show1RMBanner = false
    
    // MARK: - Stored Bodyweight
    
    var storedBodyWeight: Double = 0
}

// MARK: - SnapshotState Extension (from WorkoutSessionM)

extension SnapshotState {
    init(from session: FortachonCore.WorkoutSessionM) {
        exerciseOrder = session.exercises.map { $0.weId }
        exercises = session.exercises.map { ex in
            (
                weId: ex.weId,
                exerciseId: ex.exerciseId,
                supersetId: ex.supersetId,
                sets: ex.sets.map { (id: $0.setId, reps: $0.reps, weight: $0.weight, type: $0.setTypeStr) }
            )
        }
    }
}