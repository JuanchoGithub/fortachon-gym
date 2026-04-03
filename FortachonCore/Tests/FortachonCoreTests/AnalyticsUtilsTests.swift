import Testing
import Foundation
@testable import FortachonCore

struct AnalyticsUtilsTests {

    // MARK: - calculateSessionDensity

    @Test("sessionDensity = volume / minute")
    func density_basic() async throws {
        let ex = WorkoutExercise(
            id: "we-1", exerciseId: "ex-1",
            sets: [PerformedSet(id: "s1", reps: 10, weight: 80, type: .normal, isComplete: true)],
            restTime: RestTimes()
        )
        let session = WorkoutSession(
            id: "ws-1", routineId: "rt-1", routineName: "T",
            startTime: 0, endTime: 3_600_000, exercises: [ex]
        )
        // volume = 80*10 = 800, duration = 3600000ms = 60min
        let density = calculateSessionDensity(session)
        #expect(abs(density - 800.0/60.0) < 0.01)
    }

    @Test("sessionDensity returns 0 for bad duration")
    func density_zeroDuration() async throws {
        let session = WorkoutSession(
            id: "ws-1", routineId: "rt-1", routineName: "T",
            startTime: 0, endTime: 0, exercises: []
        )
        #expect(calculateSessionDensity(session) == 0)
    }

    @Test("sessionDensity returns 0 for duration < 5 min")
    func density_shortSession() async throws {
        let session = WorkoutSession(
            id: "ws-1", routineId: "rt-1", routineName: "T",
            startTime: 0, endTime: 240_000, // 4 minutes
            exercises: [WorkoutExercise(id: "we-1", exerciseId: "ex-1", sets: [], restTime: RestTimes())]
        )
        #expect(calculateSessionDensity(session) == 0)
    }

    // MARK: - calculateAverageDensity

    @Test("averageDensity is rolling mean")
    func avgDensity_basic() async throws {
        let sessions = (0..<3).map { i in
            let ex = WorkoutExercise(
                id: "we-1", exerciseId: "ex-1",
                sets: [PerformedSet(id: "s1", reps: 10, weight: Double(60 + i*20), type: .normal, isComplete: true)],
                restTime: RestTimes()
            )
            return WorkoutSession(
                id: "ws-\(i)", routineId: "rt-1", routineName: "T",
                startTime: 0, endTime: 3_600_000, exercises: [ex]
            )
        }
        let avg = calculateAverageDensity(sessions)
        // densities: 600/60, 800/60, 1000/60 = 10, 13.33, 16.67 -> avg = 13.33
        #expect(abs(avg - 13.33) < 0.1)
    }

    @Test("averageDensity returns 0 for empty history")
    func avgDensity_empty() async throws {
        #expect(calculateAverageDensity([]) == 0)
    }

    // MARK: - detectPreferredIncrement

    @Test("detectPreferredIncrement: 2.5 for <= 20kg")
    func increment_lowWeight() async throws {
        #expect(detectPreferredIncrement(legWeight: 20) == 2.5)
        #expect(detectPreferredIncrement(legWeight: 10) == 2.5)
    }

    @Test("detectPreferredIncrement: 5 for > 20kg")
    func increment_highWeight() async throws {
        #expect(detectPreferredIncrement(legWeight: 22.5) == 5.0)
        #expect(detectPreferredIncrement(legWeight: 100) == 5.0)
    }

    // MARK: - calculateMedianWorkoutDuration

    @Test("medianWorkoutDuration: short (< 35 min)")
    func medianDuration_short() async throws {
        let durationMs = 25 * 60_000
        var sessions: [WorkoutSession] = []
        for i in 0..<5 {
            sessions.append(WorkoutSession(
                id: "ws-\(i)", routineId: "rt-1", routineName: "T",
                startTime: Double(i * 86_400_000),
                endTime: Double(i * 86_400_000 + durationMs),
                exercises: []))
        }
        #expect(calculateMedianWorkoutDuration(sessions) == .short)
    }

    @Test("medianWorkoutDuration: medium (35-65 min)")
    func medianDuration_medium() async throws {
        let durationMs = 45 * 60_000
        var sessions: [WorkoutSession] = []
        for i in 0..<5 {
            sessions.append(WorkoutSession(
                id: "ws-\(i)", routineId: "rt-1", routineName: "T",
                startTime: Double(i * 86_400_000),
                endTime: Double(i * 86_400_000 + durationMs),
                exercises: []))
        }
        #expect(calculateMedianWorkoutDuration(sessions) == .medium)
    }

    @Test("medianWorkoutDuration: long (> 65 min)")
    func medianDuration_long() async throws {
        let durationMs = 80 * 60_000
        var sessions: [WorkoutSession] = []
        for i in 0..<5 {
            sessions.append(WorkoutSession(
                id: "ws-\(i)", routineId: "rt-1", routineName: "T",
                startTime: Double(i * 86_400_000),
                endTime: Double(i * 86_400_000 + durationMs),
                exercises: []))
        }
        #expect(calculateMedianWorkoutDuration(sessions) == .long)
    }

    @Test("medianWorkoutDuration: returns medium for < 5 sessions")
    func medianDuration_tooFew() async throws {
        #expect(calculateMedianWorkoutDuration([]) == .medium)
        let one = [WorkoutSession(id: "ws-0", routineId: "rt-1", routineName: "T", startTime: 0, endTime: 60_000, exercises: [])]
        #expect(calculateMedianWorkoutDuration(one) == .medium)
    }

    // MARK: - analyzeUserHabits

    @Test("analyzeUserHabits counts exercises and routines")
    func habits_counts() async throws {
        let exercises = [
            WorkoutExercise(id: "we-1", exerciseId: "ex-1", sets: [], restTime: RestTimes()),
            WorkoutExercise(id: "we-2", exerciseId: "ex-1", sets: [], restTime: RestTimes()),
            WorkoutExercise(id: "we-3", exerciseId: "ex-2", sets: [], restTime: RestTimes()),
        ]
        let now = Date.now.timeIntervalSince1970 * 1000
        let session = WorkoutSession(
            id: "ws-1", routineId: "rt-1", routineName: "T",
            startTime: now, endTime: now + 3_600_000, exercises: exercises
        )
        let habits = analyzeUserHabits([session])
        #expect(habits.exerciseFrequency["ex-1"] == 2)
        #expect(habits.exerciseFrequency["ex-2"] == 1)
        #expect(habits.routineFrequency["rt-1"] == 1)
    }

    @Test("analyzeUserHabits filters to 90 days")
    func habits_90dayWindow() async throws {
        let now = Date.now.timeIntervalSince1970 * 1000
        let oldDate = now - 100 * 86_400_000 // 100 days ago
        let recent = WorkoutSession(
            id: "ws-1", routineId: "rt-1", routineName: "T",
            startTime: now, endTime: now + 3_600_000, exercises: []
        )
        let old = WorkoutSession(
            id: "ws-2", routineId: "rt-2", routineName: "T2",
            startTime: oldDate, endTime: oldDate + 3_600_000, exercises: []
        )
        let habits = analyzeUserHabits([recent, old])
        #expect(habits.routineFrequency["rt-1"] == 1)
        #expect(habits.routineFrequency["rt-2"] == nil)
    }
}
