import Testing
import Foundation
@testable import FortachonCore

struct LifterProfileTests {

    @Test("LifterDNA returns beginner for <5 sessions")
    func lifterDNA_beginner() async throws {
        let session = makeSession(exercises: [("ex-1", 4, 100)])
        let dna = calculateLifterDNA([session])
        #expect(dna.experienceLevel == 0)
        #expect(dna.rawVolume == 400)
    }

    @Test("LifterDNA returns 0 for empty history")
    func lifterDNA_empty() async throws {
        let dna = calculateLifterDNA([])
        #expect(dna.experienceLevel == 0)
        #expect(dna.rawVolume == 0)
    }

    @Test("inferUserProfile returns intermediate for empty history")
    func inferProfile_empty() async throws {
        let profile = inferUserProfile([])
        #expect(profile.experience == .intermediate)
        #expect(profile.goal == .muscle)
    }

    @Test("calculateMedianWorkoutDuration returns medium for <5 sessions")
    func medianDuration_default() async throws {
        #expect(calculateMedianWorkoutDuration([]) == .medium)
        #expect(calculateMedianWorkoutDuration([makeSession(exercises:[])]) == .medium)
    }

    @Test("calculateMedianWorkoutDuration returns short for fast sessions")
    func medianDuration_short() async throws {
        let sessions = (0..<5).map { _ in makeSession(exercises: [], durationMin: 30) }
        #expect(calculateMedianWorkoutDuration(sessions) == .short)
    }

    @Test("calculateMedianWorkoutDuration returns long for slow sessions")
    func medianDuration_long() async throws {
        let sessions = (0..<5).map { _ in makeSession(exercises: [], durationMin: 90) }
        #expect(calculateMedianWorkoutDuration(sessions) == .long)
    }
}

private func makeExercise(id: String, reps: Int, weight: Double) -> WorkoutExercise {
    let uid = UUID().uuidString.prefix(4)
    return WorkoutExercise(
        id: "we-\(uid)", exerciseId: id,
        sets: [PerformedSet(id: "s-\(uid)", reps: reps, weight: weight, type: .normal, isComplete: true)],
        restTime: RestTimes()
    )
}

private func makeSession(exercises: [(String, Int, Double)], durationMin: Double = 60) -> WorkoutSession {
    let exs = exercises.map { makeExercise(id: $0.0, reps: $0.1, weight: $0.2) }
    let start = Date.now.timeIntervalSince1970 * 1000
    return WorkoutSession(
        id: "ws-\(UUID().uuidString.prefix(4))",
        routineId: "rt-1", routineName: "T",
        startTime: start, endTime: start + durationMin * 60_000,
        exercises: exs
    )
}
