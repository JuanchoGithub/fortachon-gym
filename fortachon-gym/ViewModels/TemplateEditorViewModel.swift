import Foundation
import SwiftData
import FortachonCore
import Observation

/// Template exercise item for editing
@Observable
class TemplateExerciseItem: Identifiable, Equatable {
    let id: String
    var exerciseId: String
    var exerciseName: String
    var bodyPart: String
    
    // Set configuration
    var defaultSets: Int
    var defaultReps: Int
    var setType: SetType
    var restTime: Int
    
    // Timed exercise flag
    var isTimed: Bool
    
    init(
        id: String = UUID().uuidString,
        exerciseId: String,
        exerciseName: String,
        bodyPart: String,
        defaultSets: Int = 3,
        defaultReps: Int = 10,
        setType: SetType = .normal,
        restTime: Int = 90,
        isTimed: Bool = false
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.bodyPart = bodyPart
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.setType = setType
        self.restTime = restTime
        self.isTimed = isTimed
    }
    
    static func == (lhs: TemplateExerciseItem, rhs: TemplateExerciseItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// ViewModel for template editing
@Observable
@MainActor
final class TemplateEditorViewModel {
    
    // MARK: - State
    
    var templateName: String = ""
    var templateDescription: String = ""
    var templateType: String = "strength"
    var exercises: [TemplateExerciseItem] = []
    var hasChanges: Bool = false
    var validationErrors: [String] = []
    var showValidationErrors: Bool = false
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let allExercises: [ExerciseM]
    private var originalRoutine: RoutineM?
    
    // MARK: - Init
    
    init(modelContext: ModelContext, allExercises: [ExerciseM], routine: RoutineM? = nil) {
        self.modelContext = modelContext
        self.allExercises = allExercises
        self.originalRoutine = routine
        
        if let routine = routine {
            templateName = routine.name
            templateDescription = routine.desc
            templateType = routine.routineTypeStr
            
            for ex in routine.exercises {
                let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
                let item = TemplateExerciseItem(
                    exerciseId: ex.exerciseId,
                    exerciseName: exerciseDef?.name ?? ex.exerciseId,
                    bodyPart: exerciseDef?.bodyPartStr ?? "Full Body",
                    defaultSets: ex.sets.count,
                    defaultReps: ex.sets.first?.reps ?? 10,
                    setType: SetType(rawValue: ex.sets.first?.setTypeStr ?? "normal") ?? .normal,
                    restTime: ex.restNormal,
                    isTimed: exerciseDef?.isTimed ?? false
                )
                exercises.append(item)
            }
        }
    }
    
    // MARK: - Exercise Management
    
    func addExercise(_ exerciseId: String) {
        guard let exerciseDef = allExercises.first(where: { $0.id == exerciseId }) else { return }
        
        // Check if already added
        guard !exercises.contains(where: { $0.exerciseId == exerciseId }) else { return }
        
        let item = TemplateExerciseItem(
            exerciseId: exerciseId,
            exerciseName: exerciseDef.name,
            bodyPart: exerciseDef.bodyPartStr,
            isTimed: exerciseDef.isTimed
        )
        exercises.append(item)
        hasChanges = true
    }
    
    func removeExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        hasChanges = true
    }
    
    func removeExercise(_ item: TemplateExerciseItem) {
        exercises.removeAll { $0.id == item.id }
        hasChanges = true
    }
    
    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        hasChanges = true
    }
    
    // MARK: - Save
    
    func saveTemplate() -> RoutineM? {
        // Validate
        validationErrors = []
        if templateName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors.append("Template name is required.")
        }
        if exercises.isEmpty {
            validationErrors.append("Add at least one exercise.")
        }
        if !validationErrors.isEmpty {
            showValidationErrors = true
            return nil
        }
        
        let routine: RoutineM
        if let existing = originalRoutine {
            routine = existing
        } else {
            routine = RoutineM(
                id: "rt-\(UUID().uuidString)",
                name: templateName,
                desc: templateDescription,
                isTemplate: true,
                type: templateType
            )
        }
        
        routine.name = templateName
        routine.desc = templateDescription
        routine.routineTypeStr = templateType
        
        // Clear existing exercises
        routine.exercises.removeAll()
        
        // Add exercises
        for item in exercises {
            let we = WorkoutExerciseM(
                id: "we-\(UUID().uuidString)",
                exerciseId: item.exerciseId
            )
            we.restNormal = item.restTime
            
            if item.isTimed {
                // Timed exercise: one set placeholder
                we.sets.append(PerformedSetM(id: "set-\(UUID().uuidString)", reps: 0, weight: 0, type: "timed"))
            } else {
                // Regular sets
                for _ in 0..<item.defaultSets {
                    we.sets.append(PerformedSetM(
                        id: "set-\(UUID().uuidString)",
                        reps: item.defaultReps,
                        weight: 0,
                        type: item.setType.rawValue
                    ))
                }
            }
            
            routine.exercises.append(we)
        }
        
        hasChanges = false
        return routine
    }
    
    // MARK: - Duplicate
    
    func duplicateTemplate() -> RoutineM? {
        guard let original = originalRoutine else { return nil }
        
        let newRoutine = RoutineM(
            id: "rt-\(UUID().uuidString)",
            name: "\(original.name) (Copy)",
            desc: original.desc,
            isTemplate: true,
            type: original.routineTypeStr
        )
        
        for ex in original.exercises {
            let newEx = WorkoutExerciseM(
                id: "we-\(UUID().uuidString)",
                exerciseId: ex.exerciseId
            )
            newEx.restNormal = ex.restNormal
            newEx.restWarmup = ex.restWarmup
            newEx.restDrop = ex.restDrop
            
            for set in ex.sets {
                newEx.sets.append(PerformedSetM(
                    id: "set-\(UUID().uuidString)",
                    reps: set.reps,
                    weight: set.weight,
                    type: set.setTypeStr
                ))
            }
            
            newRoutine.exercises.append(newEx)
        }
        
        return newRoutine
    }
}