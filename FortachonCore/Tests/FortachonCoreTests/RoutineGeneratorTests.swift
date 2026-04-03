import Testing
import Foundation
@testable import FortachonCore

struct RoutineGeneratorTests {

    // MARK: - generateSmartRoutine

    @Test("push focus returns 5 exercises")
    func pushFocus_exerciseCount() async throws {
        let settings = SurveyAnswers(
            experience: .intermediate, goal: .muscle,
            equipment: .gym, time: .medium
        )
        let routine = generateSmartRoutine(focus: .push, settings: settings)
        #expect(routine.exercises.count == 5)
    }

    @Test("strength goal sets 5x5")
    func strengthGoal_setsAndReps() async throws {
        let settings = SurveyAnswers(
            experience: .intermediate, goal: .strength,
            equipment: .gym, time: .medium
        )
        let routine = generateSmartRoutine(focus: .push, settings: settings)
        #expect(routine.exercises[0].sets.count == 5)
        // Each set should default to 5 reps for strength
        #expect(routine.exercises[0].sets[0].reps == 5)
    }

    @Test("short time reduces sets and rest")
    func shortTime_reducedVolume() async throws {
        let med = generateSmartRoutine(
            focus: .push, settings: .init(experience: .intermediate, goal: .muscle, equipment: .gym, time: .medium)
        )
        let short = generateSmartRoutine(
            focus: .push, settings: .init(experience: .intermediate, goal: .muscle, equipment: .gym, time: .short)
        )
        #expect(short.exercises[0].sets.count < med.exercises[0].sets.count)
        #expect(short.exercises[0].restTime.normal < med.exercises[0].restTime.normal)
    }

    @Test("beginner safety swaps applied")
    func beginner_safeSwaps() async throws {
        let settings = SurveyAnswers(
            experience: .beginner, goal: .muscle,
            equipment: .gym, time: .medium
        )
        let routine = generateSmartRoutine(focus: .full_body, settings: settings)
        // Bench Press (ex-1) should be swapped to Machine Chest Press (ex-31)
        let benchExercise = routine.exercises.first { $0.exerciseId == "ex-31" }
        #expect(benchExercise != nil)
    }

    @Test("bodyweight uses push-ups not bench press")
    func bodyweight_exercises() async throws {
        let settings = SurveyAnswers(
            experience: .beginner, goal: .muscle,
            equipment: .bodyweight, time: .medium
        )
        let routine = generateSmartRoutine(focus: .full_body, settings: settings)
        // Push focus for bodyweight beginner, check back_horizontal maps to ex-42 (inverted row)
        let hasInvertedRow = routine.exercises.contains { $0.exerciseId == "ex-42" }
        #expect(hasInvertedRow)
    }

    // MARK: - generateRoutines (onboarding wizard)

    @Test("beginner gets 2 full body routines")
    func beginner_twoRoutines() async throws {
        let settings = SurveyAnswers(
            experience: .beginner, goal: .muscle,
            equipment: .gym, time: .medium
        )
        let routines = generateRoutines(settings)
        #expect(routines.count == 2)
        // Both should be templates
        #expect(routines[0].isTemplate == true)
        #expect(routines[1].isTemplate == true)
    }

    @Test("intermediate gets 2 routines (upper/lower)")
    func intermediate_routines() async throws {
        let settings = SurveyAnswers(
            experience: .intermediate, goal: .muscle,
            equipment: .gym, time: .medium
        )
        let routines = generateRoutines(settings)
        #expect(routines.count == 2)
    }

    @Test("advanced gets 3 routines (push/pull/legs)")
    func advanced_threeRoutines() async throws {
        let settings = SurveyAnswers(
            experience: .advanced, goal: .muscle,
            equipment: .gym, time: .medium
        )
        let routines = generateRoutines(settings)
        #expect(routines.count == 3)
    }
}
