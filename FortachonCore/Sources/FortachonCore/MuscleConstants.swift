import Foundation

// MARK: - Muscle Group Constants
// Mirrors constants/muscles.ts

public enum Muscle {
    // Chest
    public static let pectorals = "Pectorals"
    public static let upperChest = "Upper Chest"
    public static let lowerChest = "Lower Chest"
    public static let serratusAnterior = "Serratus Anterior"

    // Back
    public static let lats = "Lats"
    public static let traps = "Traps"
    public static let rhomboids = "Rhomboids"
    public static let lowerBack = "Lower Back"
    public static let teresMajor = "Teres Major"
    public static let spinalErectors = "Spinal Erectors"

    // Shoulders
    public static let frontDelts = "Front Delts"
    public static let sideDelts = "Side Delts"
    public static let rearDelts = "Rear Delts"
    public static let rotatorCuff = "Rotator Cuff"

    // Arms
    public static let biceps = "Biceps"
    public static let triceps = "Triceps"
    public static let brachialis = "Brachialis"
    public static let forearms = "Forearms"
    public static let wristFlexors = "Wrist Flexors"
    public static let wristExtensors = "Wrist Extensors"

    // Legs
    public static let quads = "Quads"
    public static let hamstrings = "Hamstrings"
    public static let glutes = "Glutes"
    public static let adductors = "Adductors"
    public static let abductors = "Abductors"
    public static let calves = "Calves"
    public static let soleus = "Soleus"
    public static let gastrocnemius = "Gastrocnemius"
    public static let tibialisAnterior = "Tibialis Anterior"
    public static let hipFlexors = "Hip Flexors"

    // Core
    public static let abs = "Abs"
    public static let obliques = "Obliques"
    public static let transverseAbdominis = "Transverse Abdominis"

    // Cardio
    public static let cardiovascularSystem = "Cardiovascular System"
}

// MARK: - Body Part to Muscles Mapping
// Mirrors BODY_PART_TO_MUScles from constants/muscles.ts

public let bodyPartToMuscles: [String: [String]] = [
    "Chest": [Muscle.pectorals, Muscle.upperChest, Muscle.lowerChest, Muscle.serratusAnterior],
    "Back": [Muscle.lats, Muscle.traps, Muscle.rhomboids, Muscle.lowerBack, Muscle.teresMajor, Muscle.spinalErectors],
    "Shoulders": [Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts, Muscle.rotatorCuff],
    "Biceps": [Muscle.biceps, Muscle.brachialis, Muscle.forearms],
    "Triceps": [Muscle.triceps],
    "Legs": [Muscle.quads, Muscle.hamstrings, Muscle.adductors, Muscle.abductors, Muscle.tibialisAnterior],
    "Glutes": [Muscle.glutes],
    "Core": [Muscle.abs, Muscle.obliques, Muscle.transverseAbdominis, Muscle.lowerBack],
    "Calves": [Muscle.calves, Muscle.soleus, Muscle.gastrocnemius],
    "Forearms": [Muscle.forearms, Muscle.wristFlexors, Muscle.wristExtensors],
    "Full Body": Array(allMuscleGroups),
    "Cardio": [Muscle.cardiovascularSystem, Muscle.quads, Muscle.calves],
    "Mobility": Array(allMuscleGroups),
]

/// All unique muscle group strings
public let allMuscleGroups: Set<String> = Set([
    Muscle.pectorals, Muscle.upperChest, Muscle.lowerChest, Muscle.serratusAnterior,
    Muscle.lats, Muscle.traps, Muscle.rhomboids, Muscle.lowerBack, Muscle.teresMajor, Muscle.spinalErectors,
    Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts, Muscle.rotatorCuff,
    Muscle.biceps, Muscle.triceps, Muscle.brachialis, Muscle.forearms, Muscle.wristFlexors, Muscle.wristExtensors,
    Muscle.quads, Muscle.hamstrings, Muscle.glutes, Muscle.adductors, Muscle.abductors, Muscle.calves, Muscle.soleus, Muscle.gastrocnemius, Muscle.tibialisAnterior, Muscle.hipFlexors,
    Muscle.abs, Muscle.obliques, Muscle.transverseAbdominis,
    Muscle.cardiovascularSystem,
])
