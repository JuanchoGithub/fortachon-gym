import Foundation

// MARK: - Filter Constants
// Mirrors constants/filters.ts

/// All available body part filter options
public let bodyPartOptions: [String] = [
    "Chest", "Back", "Legs", "Glutes", "Shoulders", "Biceps", "Triceps",
    "Core", "Full Body", "Calves", "Forearms", "Mobility", "Cardio"
]

/// All available exercise category filter options
public let categoryOptions: [String] = [
    "Barbell", "Dumbbell", "Machine", "Cable", "Bodyweight",
    "Assisted Bodyweight", "Kettlebell", "Plyometrics", "Reps Only",
    "Cardio", "Duration", "Smith Machine"
]

/// All available muscle group filter options
public let muscleGroupOptions: [String] = [
    Muscle.pectorals, Muscle.upperChest, Muscle.lowerChest, Muscle.serratusAnterior,
    Muscle.lats, Muscle.traps, Muscle.rhomboids, Muscle.lowerBack, Muscle.teresMajor, Muscle.spinalErectors,
    Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts, Muscle.rotatorCuff,
    Muscle.biceps, Muscle.triceps, Muscle.brachialis, Muscle.forearms, Muscle.wristFlexors, Muscle.wristExtensors,
    Muscle.quads, Muscle.hamstrings, Muscle.glutes, Muscle.adductors, Muscle.abductors,
    Muscle.calves, Muscle.soleus, Muscle.gastrocnemius, Muscle.tibialisAnterior, Muscle.hipFlexors,
    Muscle.abs, Muscle.obliques, Muscle.transverseAbdominis,
    Muscle.cardiovascularSystem
]
