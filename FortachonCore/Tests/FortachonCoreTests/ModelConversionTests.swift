import Testing
import Foundation
@testable import FortachonCore

struct ModelConversionTests {

    @Test("Exercise roundtrip struct → Model → struct")
    func exercise_roundtrip() async throws {
        let original = Exercise(
            id: "ex-1", name: "Bench Press", bodyPart: .chest,
            category: .barbell, notes: "Keep elbows in",
            isTimed: false, isUnilateral: false,
            primaryMuscles: ["Pectorals"]
        )
        let model = ExerciseM(
            id: original.id, name: original.name,
            bodyPart: original.bodyPart.rawValue,
            category: original.category.rawValue,
            notes: original.notes, isTimed: original.isTimed ?? false,
            isUnilateral: original.isUnilateral ?? false,
            primaryMuscles: original.primaryMuscles ?? []
        )
        let decoded = Exercise(from: model)
        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.bodyPart == original.bodyPart)
        #expect(decoded.category == original.category)
        #expect(decoded.notes == original.notes)
    }

    @Test("PerformedSet roundtrip struct → Model → struct")
    func performedSet_roundtrip() async throws {
        let original = PerformedSet(
            id: "s-1", reps: 10, weight: 80, time: nil,
            type: .normal, isComplete: true, completedAt: 1700000000,
            rest: 90, actualRest: 95
        )
        let model = PerformedSetM(
            id: original.id, reps: original.reps, weight: original.weight,
            time: original.time, type: original.type.rawValue,
            isComplete: original.isComplete,
            completedAt: original.completedAt.map { Date(timeIntervalSince1970: $0) },
            rest: original.rest, actualRest: original.actualRest
        )
        let decoded = PerformedSet(from: model)
        #expect(decoded.id == original.id)
        #expect(decoded.reps == original.reps)
        #expect(decoded.weight == original.weight)
        #expect(decoded.type == original.type)
        #expect(decoded.isComplete == original.isComplete)
    }

    @Test("WorkoutExercise roundtrip struct → Model → struct")
    func workoutExercise_roundtrip() async throws {
        let set = PerformedSet(id: "s-1", reps: 5, weight: 100, type: .normal, isComplete: true)
        let setModel = PerformedSetM(
            id: set.id, reps: set.reps, weight: set.weight,
            type: set.type.rawValue, isComplete: set.isComplete
        )
        let rt = RestTimes(normal: 120, warmup: 60, drop: 30,
                          timed: 10, effort: 180, failure: 300)
        let exerciseModel = WorkoutExerciseM(
            id: "we-1", exerciseId: "ex-1", restTime: rt,
            note: "Go slow", supersetId: nil
        )
        exerciseModel.sets.append(setModel)
        let decoded = WorkoutExercise(from: exerciseModel)
        #expect(decoded.id == "we-1")
        #expect(decoded.exerciseId == "ex-1")
        #expect(decoded.sets.count == 1)
        #expect(decoded.restTime.normal == 120)
        #expect(decoded.note == "Go slow")
    }

    @Test("WorkoutSession roundtrip struct → Model → struct")
    func workoutSession_roundtrip() async throws {
        let exModel = WorkoutExerciseM(id: "we-1", exerciseId: "ex-1")
        let wsModel = WorkoutSessionM(
            id: "ws-1", routineId: "rt-1", routineName: "Push Day",
            startTime: Date(timeIntervalSince1970: 1700000),
            endTime: Date(timeIntervalSince1970: 1703600),
            prCount: 2
        )
        wsModel.exercises.append(exModel)
        let decoded = WorkoutSession(from: wsModel)
        #expect(decoded.id == "ws-1")
        #expect(decoded.routineId == "rt-1")
        #expect(decoded.routineName == "Push Day")
        #expect(decoded.prCount == 2)
        #expect(decoded.exercises.count == 1)
    }

    @Test("Routine roundtrip struct → Model → struct")
    func routine_roundtrip() async throws {
        let exModel = WorkoutExerciseM(id: "we-1", exerciseId: "ex-1")
        let rtModel = RoutineM(
            id: "rt-1", name: "Push", desc: "Chest and shoulders",
            isTemplate: true, type: "strength"
        )
        rtModel.exercises.append(exModel)
        rtModel.tags = ["push", "upper"]
        let decoded = Routine(from: rtModel)
        #expect(decoded.id == "rt-1")
        #expect(decoded.name == "Push")
        #expect(decoded.isTemplate == true)
        #expect(decoded.routineType == .strength)
        #expect(decoded.tags == ["push", "upper"])
    }

    @Test("makeInMemoryContainer creates container")
    func inMemoryContainer() async throws {
        let container = try makeInMemoryContainer()
        #expect(container != nil)
    }
}
