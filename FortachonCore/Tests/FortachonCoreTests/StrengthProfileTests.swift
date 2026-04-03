import Testing
import Foundation
@testable import FortachonCore

struct StrengthProfileTests {

    @Test("STRENGTH_SYMMETRY_RATIOS has 6 entries")
    func symmetryRatio_count() {
        #expect(STRENGTH_SYMMETRY_RATIOS.count == 6)
        #expect(STRENGTH_SYMMETRY_RATIOS["SQUAT"] == 4)
        #expect(STRENGTH_SYMMETRY_RATIOS["BENCH"] == 3)
        #expect(STRENGTH_SYMMETRY_RATIOS["DEADLIFT"] == 5)
        #expect(STRENGTH_SYMMETRY_RATIOS["OHT"] == 2)
        #expect(STRENGTH_SYMMETRY_RATIOS["ROW"] == 3)
        #expect(STRENGTH_SYMMETRY_RATIOS["VERTICAL_PULL"] == 3)
    }

    @Test("MOVEMENT_PATTERNS has 6 patterns")
    func movementPatterns_count() {
        #expect(MOVEMENT_PATTERNS.count == 6)
        #expect(MOVEMENT_PATTERNS["SQUAT"]?.contains("ex-2") == true)
        #expect(MOVEMENT_PATTERNS["BENCH"]?.contains("ex-1") == true)
        #expect(MOVEMENT_PATTERNS["DEADLIFT"]?.contains("ex-3") == true)
    }

    @Test("ANCHOR_EXERCISES maps correctly")
    func anchorExercises() {
        #expect(ANCHOR_EXERCISES.SQUAT == "ex-2")
        #expect(ANCHOR_EXERCISES.BENCH == "ex-1")
        #expect(ANCHOR_EXERCISES.DEADLIFT == "ex-3")
        #expect(ANCHOR_EXERCISES.OHT == "ex-4")
    }

    @Test("PatternMax Codable round-trip")
    func patternMax_codable() async throws {
        let pm = PatternMax(exerciseId: "ex-1", weight: 100.0, reps: 5)
        let data = try JSONEncoder().encode(pm)
        let decoded = try JSONDecoder().decode(PatternMax.self, from: data)
        #expect(decoded.exerciseId == "ex-1")
        #expect(decoded.weight == 100.0)
        #expect(decoded.reps == 5)
    }

    @Test("calculateMaxStrengthProfile from sample history")
    func maxStrengthProfile_basic() async throws {
        let sets = [
            PerformedSet(id: "s1", reps: 5, weight: 80, type: .normal, isComplete: true),
            PerformedSet(id: "s2", reps: 3, weight: 90, type: .normal, isComplete: true),
            PerformedSet(id: "s3", reps: 10, weight: 60, type: .warmup, isComplete: true),
        ]
        let session = WorkoutSession(
            id: "ws-1", routineId: "rt-1", routineName: "Push",
            startTime: 0, endTime: 3_600_000,
            exercises: [WorkoutExercise(
                id: "we-1", exerciseId: "ex-1",
                sets: sets, restTime: RestTimes()
            )]
        )
        let allExercises: [Exercise] = [
            Exercise(id: "ex-1", name: "Bench Press", bodyPart: .chest, category: .barbell)
        ]
        let profile = calculateMaxStrengthProfile([session], allExercises: allExercises)
        // 90 * 3^0.10 = 101 (Lombardi 1RM)
        #expect(profile.BENCH.weight == 100)
        #expect(profile.BENCH.exerciseId == "ex-1")
        #expect(profile.BENCH.reps == 3)
        // SQUAT is 0 since no squat exercises
        #expect(profile.SQUAT.weight == 0)
    }

    @Test("calculateMaxStrengthProfile empty history returns zeros")
    func maxStrengthProfile_empty() async throws {
        let profile = calculateMaxStrengthProfile([], allExercises: [])
        #expect(profile.SQUAT.weight == 0)
        #expect(profile.BENCH.weight == 0)
        #expect(profile.DEADLIFT.weight == 0)
    }

    @Test("calculateNormalizedStrengthScores from full profile")
    func normalizedScores() async throws {
        let profile = StrengthProfile(
            SQUAT: PatternMax(exerciseId: "ex-2", weight: 160, reps: 5),
            BENCH: PatternMax(exerciseId: "ex-1", weight: 100, reps: 5),
            DEADLIFT: PatternMax(exerciseId: "ex-3", weight: 200, reps: 5),
            OVERHEAD: PatternMax(exerciseId: "ex-4", weight: 60, reps: 5),
            ROW: PatternMax(exerciseId: "ex-5", weight: 90, reps: 5),
            VERTICAL_PULL: PatternMax(exerciseId: "ex-6", weight: 90, reps: 5)
        )
        let scores = calculateNormalizedStrengthScores(profile)
        #expect(scores.squat > 0)
        #expect(scores.bench > 0)
        #expect(scores.deadlift > 0)
        #expect(scores.max() == 100)
    }

    @Test("normalizedScores for all zeros returns zeros")
    func normalizedScores_empty() async throws {
        let profile = StrengthProfile()
        let scores = calculateNormalizedStrengthScores(profile)
        #expect(scores.squat == 0)
        #expect(scores.bench == 0)
        #expect(scores.deadlift == 0)
        #expect(scores.overhead == 0)
        #expect(scores.row == 0)
        #expect(scores.verticalPull == 0)
    }

    @Test("getInferredMax via direct ratio")
    func inferredMax_directRatio() async throws {
        // Bench 1RM = 100, Front Squat (ex-101) has 0.85 ratio to SQUAT
        let profile = StrengthProfile(
            SQUAT: PatternMax(exerciseId: "ex-2", weight: 140, reps: 5)
        )
        let ex = Exercise(id: "ex-101", name: "Front Squat", bodyPart: .legs, category: .barbell)
        let inferred = getInferredMax(ex, profile: profile)
        #expect(inferred == 140 * 0.85) // 119
    }

    @Test("getInferredMax via bodypart anchor + category")
    func inferredMax_bodypartFallback() async throws {
        // BENCH = 100, so Triceps (bodypart anchor = BENCH) with .cable = 1.3
        let profile = StrengthProfile(
            BENCH: PatternMax(exerciseId: "ex-1", weight: 100, reps: 5)
        )
        let ex = Exercise(id: "ex-999", name: "Cable Pushdown", bodyPart: .triceps, category: .cable)
        let inferred = getInferredMax(ex, profile: profile)
        // 100 * 1.3 = 130
        #expect(inferred == 130)
    }

    @Test("getInferredMax returns nil for cardio with no anchor")
    func inferredMax_nil() async throws {
        let profile = StrengthProfile()
        let ex = Exercise(id: "ex-cardio", name: "Running", bodyPart: .cardio, category: .cardio)
        #expect(getInferredMax(ex, profile: profile) == nil)
    }

    @Test("StrengthProfile subscript access")
    func strengthProfile_subscript() async throws {
        let p = StrengthProfile(SQUAT: PatternMax(exerciseId: "ex-2", weight: 150, reps: 5))
        #expect(p["SQUAT"].weight == 150)
        #expect(p["BENCH"].weight == 0)
    }

    @Test("StrengthProfile max() returns highest")
    func strengthProfile_max() async throws {
        let p = StrengthProfile(
            SQUAT: PatternMax(exerciseId: "", weight: 100, reps: 5),
            DEADLIFT: PatternMax(exerciseId: "", weight: 150, reps: 5)
        )
        #expect(p.patternMax().weight == 150)
    }
}
