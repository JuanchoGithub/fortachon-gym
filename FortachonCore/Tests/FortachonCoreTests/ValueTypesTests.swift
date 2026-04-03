import Testing
import Foundation
@testable import FortachonCore

struct ValueTypesTests {

    // MARK: - PerformedSet Codable

    @Test("PerformedSet encode/decode round-trip")
    func performedSet_codable() async throws {
        let set = PerformedSet(
            id: "s-1", reps: 10, weight: 80, time: nil,
            type: .normal, isComplete: true, completedAt: nil,
            rest: 90, isWeightInherited: false, isRepsInherited: false,
            isTimeInherited: false, actualRest: 95,
            historicalWeight: nil, historicalReps: nil,
            historicalTime: nil, storedBodyWeight: nil
        )
        let data = try JSONEncoder().encode(set)
        let decoded = try JSONDecoder().decode(PerformedSet.self, from: data)
        #expect(decoded.reps == 10)
        #expect(decoded.weight == 80)
        #expect(decoded.type == .normal)
        #expect(decoded.isComplete == true)
        #expect(decoded.rest == 90)
    }

    @Test("PerformedSet with timed type")
    func performedSet_timed() async throws {
        let set = PerformedSet(
            id: "s-2", reps: 1, weight: 0, time: 60,
            type: .timed, isComplete: true, completedAt: nil,
            rest: nil, isWeightInherited: false, isRepsInherited: false,
            isTimeInherited: false, actualRest: nil,
            historicalWeight: nil, historicalReps: nil,
            historicalTime: nil, storedBodyWeight: nil
        )
        #expect(set.type == .timed)
        #expect(set.time == 60)
    }

    // MARK: - RestTimes

    @Test("RestTimes defaults")
    func restTimes_defaults() async throws {
        let rt = RestTimes()
        #expect(rt.normal == 90)
        #expect(rt.warmup == 60)
        #expect(rt.drop == 30)
        #expect(rt.timed == 10)
        #expect(rt.effort == 90)
        #expect(rt.failure == 300)
    }

    // MARK: - WorkoutExercise

    @Test("WorkoutExercise Codable round-trip")
    func workoutExercise_codable() async throws {
        let ex = WorkoutExercise(
            id: "we-1", exerciseId: "ex-1", sets: [],
            restTime: RestTimes(), note: nil, barWeight: nil,
            supersetId: nil, previousVersion: nil
        )
        let data = try JSONEncoder().encode(ex)
        let decoded = try JSONDecoder().decode(WorkoutExercise.self, from: data)
        #expect(decoded.exerciseId == "ex-1")
        #expect(decoded.sets.count == 0)
    }

    // MARK: - SupersetDefinition

    @Test("SupersetDefinition Codable")
    func supersetDefinition_codable() async throws {
        let def = SupersetDefinition(id: "ss-1", name: "A", color: "#FF0000")
        let data = try JSONEncoder().encode(def)
        let decoded = try JSONDecoder().decode(SupersetDefinition.self, from: data)
        #expect(decoded.name == "A")
        #expect(decoded.color == "#FF0000")
    }

    // MARK: - findBestSet

    @Test("findBestSet picks highest 1RM from mixed sets")
    func test_findBestSet() async throws {
        let sets: [PerformedSet] = [
            PerformedSet(id: "1", reps: 10, weight: 80, type: .normal, isComplete: true),
            PerformedSet(id: "2", reps: 5, weight: 100, type: .normal, isComplete: true),
            PerformedSet(id: "3", reps: 3, weight: 50, type: .warmup, isComplete: true),
        ]
        let best = findBestSet(sets)
        #expect(best?.id == "2") // 100*5^0.10 = 117 > 80*10^0.10 = 101
    }

    @Test("findBestSet returns nil for empty or no normal sets")
    func test_findBestSet_emptySets() async throws {
        #expect(findBestSet([]) == nil)
        let warmups: [PerformedSet] = [
            PerformedSet(id: "1", reps: 10, weight: 40, type: .warmup, isComplete: true)
        ]
        #expect(findBestSet(warmups) == nil)
    }

    // MARK: - getTimerDuration

    @Test("getTimerDuration doubles on last set")
    func test_timerDuration_doublesLast() async throws {
        let ex = WorkoutExercise(
            id: "we-1", exerciseId: "ex-1",
            sets: [
                PerformedSet(id: "1", reps: 10, weight: 80, type: .normal, isComplete: false),
                PerformedSet(id: "2", reps: 10, weight: 80, type: .normal, isComplete: false),
            ],
            restTime: RestTimes()
        )
        let first = getTimerDuration(set: ex.sets[0], workoutExercise: ex, setIndex: 0)
        let last = getTimerDuration(set: ex.sets[1], workoutExercise: ex, setIndex: 1)
        #expect(first == 90)
        #expect(last == 180)
    }

    @Test("getTimerDuration respects set.rest override")
    func test_timerDuration_customRest() async throws {
        let ex = WorkoutExercise(
            id: "we-1", exerciseId: "ex-1",
            sets: [PerformedSet(id: "1", reps: 10, weight: 80, type: .normal, isComplete: false, rest: 45)],
            restTime: RestTimes()
        )
        #expect(getTimerDuration(set: ex.sets[0], workoutExercise: ex, setIndex: 0) == 45)
    }

    @Test("getTimerDuration uses warmup rest for warmup sets")
    func test_timerDuration_warmupRest() async throws {
        let ex = WorkoutExercise(
            id: "we-1", exerciseId: "ex-1",
            sets: [PerformedSet(id: "1", reps: 10, weight: 40, type: .warmup, isComplete: false)],
            restTime: RestTimes()
        )
        // Last warmup doubles: 60 * 2 = 120
        #expect(getTimerDuration(set: ex.sets[0], workoutExercise: ex, setIndex: 0) == 120)
    }

    // MARK: - groupExercises

    @Test("groupExercises singles only")
    func groupExercises_singles() async throws {
        let exercises: [WorkoutExercise] = [
            WorkoutExercise(id: "we-1", exerciseId: "ex-1", sets: [], restTime: RestTimes()),
            WorkoutExercise(id: "we-2", exerciseId: "ex-2", sets: [], restTime: RestTimes()),
        ]
        let grouped = groupExercises(exercises)
        #expect(grouped.count == 2)
        if case .single(_, index: 0) = grouped[0] {}
        else { Issue.record("Expected single at 0") }
        if case .single(_, index: 1) = grouped[1] {}
        else { Issue.record("Expected single at 1") }
    }

    @Test("groupExercises groups superset")
    func groupExercises_superset() async throws {
        let exercises: [WorkoutExercise] = [
            WorkoutExercise(id: "we-1", exerciseId: "ex-1", sets: [], restTime: RestTimes(), supersetId: "ss-1"),
            WorkoutExercise(id: "we-2", exerciseId: "ex-2", sets: [], restTime: RestTimes(), supersetId: "ss-1"),
            WorkoutExercise(id: "we-3", exerciseId: "ex-3", sets: [], restTime: RestTimes()),
        ]
        let grouped = groupExercises(exercises)
        #expect(grouped.count == 2)
        if case .superset(let items, id: _, definition: _, indices: _) = grouped[0] {
            #expect(items.count == 2)
        } else { Issue.record("Expected superset at 0") }
        if case .single(_, index: 2) = grouped[1] {}
        else { Issue.record("Expected single at 1") }
    }
}
