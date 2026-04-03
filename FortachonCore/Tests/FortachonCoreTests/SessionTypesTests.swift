import Testing
import Foundation
@testable import FortachonCore

struct SessionTypesTests {

    // MARK: - WorkoutSession Codable

    @Test("WorkoutSession encode/decode round-trip")
    func workoutSession_codable() async throws {
        let session = WorkoutSession(
            id: "ws-1", routineId: "rt-1", routineName: "Push Day",
            startTime: 1700000000, endTime: 1700003600,
            lastUpdated: 1700003600, exercises: [
                WorkoutExercise(
                    id: "we-1", exerciseId: "ex-1",
                    sets: [PerformedSet(id: "s-1", reps: 10, weight: 80, type: .normal, isComplete: true)],
                    restTime: RestTimes()
                )
            ],
            supersets: nil, prCount: 1, updatedAt: 1700003600, deletedAt: nil
        )
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(WorkoutSession.self, from: data)
        #expect(decoded.id == "ws-1")
        #expect(decoded.routineName == "Push Day")
        #expect(decoded.exercises.count == 1)
        #expect(decoded.exercises[0].sets[0].reps == 10)
        #expect(decoded.prCount == 1)
        #expect(decoded.deletedAt == nil)
    }

    // MARK: - Routine Codable

    @Test("Routine encode/decode round-trip")
    func routine_codable() async throws {
        let routine = Routine(
            id: "rt-1", name: "Push Day", description: "Chest & Shoulders",
            exercises: [], supersets: nil, isTemplate: true,
            lastUsed: nil, originId: nil, routineType: .strength,
            hiitConfig: nil, tags: ["push", "upper"],
            updatedAt: 1700000000, deletedAt: nil
        )
        let data = try JSONEncoder().encode(routine)
        let decoded = try JSONDecoder().decode(Routine.self, from: data)
        #expect(decoded.name == "Push Day")
        #expect(decoded.isTemplate == true)
        #expect(decoded.routineType == .strength)
        #expect(decoded.tags == ["push", "upper"])
    }

    @Test("Routine with HIIT config")
    func routine_withHiit() async throws {
        let config = HiitConfig(workTime: 30, restTime: 15, prepareTime: 10)
        let routine = Routine(
            id: "rt-2", name: "HIIT", description: "", exercises: [],
            routineType: .hiit, hiitConfig: config
        )
        #expect(routine.hiitConfig?.workTime == 30)
        #expect(routine.hiitConfig?.restTime == 15)
        #expect(routine.hiitConfig?.prepareTime == 10)
    }

    // MARK: - calculateRecords

    @Test("calculateRecords finds max weight, reps, volume")
    func calculateRecords_values() async throws {
        let s1 = PerformedSet(id: "s1", reps: 10, weight: 80, type: .normal, isComplete: true)
        let s2 = PerformedSet(id: "s2", reps: 5, weight: 100, type: .normal, isComplete: true)
        let s3 = PerformedSet(id: "s3", reps: 12, weight: 70, type: .warmup, isComplete: true) // warmup excluded

        let sess = WorkoutSession(
            id: "ws-1", routineId: "rt-1", routineName: "T",
            startTime: 1700000000, endTime: 1700003600, exercises: [
                WorkoutExercise(id: "we-1", exerciseId: "ex-1", sets: [s1, s2, s3], restTime: RestTimes())
            ]
        )
        let history: [(session: WorkoutSession, sets: [PerformedSet])] = [
            (sess, sess.exercises[0].sets)
        ]
        let records = calculateRecords(history)
        #expect(records.maxWeight?.value == 100)
        // warmup excluded from records, so max normal reps is 10
        #expect(records.maxReps?.value == 10)  // wait, warmup is included in sets but calculateRecords filters to .normal
        // warmup excluded, max normal volume: 10*80=800
        #expect(records.maxVolume?.value == 800) // 12*70 = 840 > 10*80=800 > 5*100=500
    }

    @Test("calculateRecords returns nil for empty history")
    func calculateRecords_empty() async throws {
        let records = calculateRecords([])
        #expect(records.maxWeight == nil)
        #expect(records.maxReps == nil)
        #expect(records.maxVolume == nil)
    }

    // MARK: - generate1RMProtocol

    @Test("generate1RMProtocol returns 4 steps with correct percentages")
    func oneRMProtocol_steps() async throws {
        let steps = generate1RMProtocol(target1RM: 100)
        #expect(steps.count == 4)
        #expect(steps[0].percentage == 0.5)  // 50%
        #expect(steps[1].percentage == 0.75) // 75%
        #expect(steps[2].percentage == 0.9)  // 90%
        #expect(steps[3].percentage == 1.0)  // 100%
        #expect(steps[0].type == .warmup)
        #expect(steps[3].type == .attempt)
    }

    // MARK: - calculateWarmupWeights

    @Test("calculateWarmupWeights 3-set: 50/75/90%")
    func warmupWeights_threeSets() async throws {
        let result = calculateWarmupWeights(workingWeight: 100, count: 3)
        #expect(result == [50.0, 75.0, 90.0])
    }

    @Test("calculateWarmupWeights rounds to increment")
    func warmupWeights_rounds() async throws {
        let result = calculateWarmupWeights(workingWeight: 103, count: 3, increment: 2.5)
        // 51.5→50, 77.25→77.5, 92.7→92.5
        #expect(result[0] == 52.5)
        #expect(result[1] == 77.5)
        #expect(result[2] == 92.5)
    }

    @Test("calculateWarmupWeights zero working weight")
    func warmupWeights_zero() async throws {
        #expect(calculateWarmupWeights(workingWeight: 0, count: 3) == [0, 0, 0])
    }

    @Test("calculateWarmupWeights single set")
    func warmupWeights_single() async throws {
        #expect(calculateWarmupWeights(workingWeight: 100, count: 1) == [60.0])
    }
}
