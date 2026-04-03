import Foundation

// MARK: - Routine Seed Data (mirrors constants/routines.ts)

public typealias _RoutineSeed = (
    id: String, name: String, description: String, type: String,
    isTemplate: Bool, tags: [String],
    hiitWork: Int?, hiitRest: Int?, hiitPrep: Int?,
    exercises: [(exerciseId: String, sets: Int, reps: Int, rest: Int, note: String?)]
)

public let seedRoutines: [_RoutineSeed] = [
    // StrongLifts 5x5 A
    ("rt-1", "StrongLifts 5x5 - Workout A", "A classic strength program focusing on compound lifts.",
     "strength", true, [], nil, nil, nil,
     [("ex-2", 5, 5, 90, nil), ("ex-1", 5, 5, 90, nil), ("ex-5", 5, 5, 90, nil)]),
    // StrongLifts 5x5 B
    ("rt-2", "StrongLifts 5x5 - Workout B", "The second workout of the 5x5 program.",
     "strength", true, [], nil, nil, nil,
     [("ex-2", 5, 5, 90, nil), ("ex-4", 5, 5, 90, nil), ("ex-3", 1, 5, 180, nil)]),
    // PHUL Upper
    ("rt-3", "PHUL - Upper Power", "Power Hypertrophy Upper Lower training program.",
     "strength", true, [], nil, nil, nil,
     [("ex-1", 4, 5, 90, nil), ("ex-12", 4, 10, 60, nil), ("ex-5", 4, 5, 90, nil),
      ("ex-10", 4, 10, 60, nil), ("ex-4", 3, 8, 75, nil), ("ex-7", 3, 10, 60, nil),
      ("ex-8", 3, 10, 60, nil)]),
    // PHUL Lower
    ("rt-4", "PHUL - Lower Power", "Power Hypertrophy Upper Lower training program.",
     "strength", true, [], nil, nil, nil,
     [("ex-2", 4, 5, 90, nil), ("ex-3", 4, 5, 120, nil), ("ex-9", 4, 12, 60, nil),
      ("ex-16", 4, 10, 60, nil), ("ex-18", 5, 15, 45, nil)]),
    // PPL Push
    ("rt-ppl-push", "PPL - Push Day", "Focuses on chest, shoulders, and triceps.",
     "strength", true, [], nil, nil, nil,
     [("ex-1", 4, 8, 90, nil), ("ex-12", 4, 12, 60, nil), ("ex-4", 3, 10, 75, nil),
      ("ex-56", 4, 15, 45, nil), ("ex-85", 4, 12, 45, nil), ("ex-8", 4, 12, 60, nil)]),
    // PPL Pull
    ("rt-ppl-pull", "PPL - Pull Day", "Focuses on back and biceps.",
     "strength", true, [], nil, nil, nil,
     [("ex-6", 4, 8, 90, nil), ("ex-5", 4, 10, 75, nil), ("ex-10", 4, 12, 60, nil),
      ("ex-38", 4, 12, 60, nil), ("ex-7", 4, 12, 45, nil), ("ex-73", 4, 15, 45, nil)]),
    // PPL Legs
    ("rt-ppl-legs", "PPL - Leg Day", "Focuses on quads, hamstrings, glutes, and calves.",
     "strength", true, [], nil, nil, nil,
     [("ex-2", 4, 8, 120, nil), ("ex-98", 4, 10, 90, nil), ("ex-9", 4, 12, 75, nil),
      ("ex-16", 4, 15, 60, nil), ("ex-18", 5, 20, 45, nil)]),
    // Full Body Blast
    ("rt-full-body", "Full Body Blast", "A comprehensive workout hitting all major muscle groups.",
     "strength", true, [], nil, nil, nil,
     [("ex-2", 3, 10, 90, nil), ("ex-1", 3, 10, 90, nil), ("ex-5", 3, 10, 90, nil),
      ("ex-4", 3, 10, 75, nil), ("ex-15", 3, 1, 60, nil)]),
    // Anatoly Squat
    ("rt-anatoly-squat", "Anatoly - Squat Focus (Day A)",
     "Focus on maximal leg strength and explosive power.",
     "strength", true, ["powerbuilding", "legs"], nil, nil, nil,
     [("ex-2", 4, 5, 180, nil), ("ex-101", 3, 8, 120, nil), ("ex-98", 3, 8, 120, nil),
      ("ex-9", 3, 10, 90, nil), ("ex-18", 3, 12, 60, nil), ("ex-15", 3, 1, 60, nil)]),
    // Anatoly Bench
    ("rt-anatoly-bench", "Anatoly - Bench Focus (Day B)",
     "Upper body pushing strength and hypertrophy.",
     "strength", true, ["powerbuilding", "push"], nil, nil, nil,
     [("ex-1", 4, 5, 180, nil), ("ex-87", 3, 8, 120, nil), ("ex-11", 3, 10, 90, nil),
      ("ex-4", 3, 8, 120, nil), ("ex-24", 3, 10, 90, nil), ("ex-5", 3, 8, 90, nil)]),
    // Anatoly Deadlift
    ("rt-anatoly-deadlift", "Anatoly - Deadlift Focus (Day C)",
     "Posterior chain power and back thickness.",
     "strength", true, ["powerbuilding", "pull"], nil, nil, nil,
     [("ex-3", 4, 5, 180, nil), ("ex-3", 3, 6, 150, nil), ("ex-104", 3, 10, 90, nil),
      ("ex-6", 3, 8, 120, nil), ("ex-41", 3, 12, 60, nil), ("ex-156", 3, 12, 60, nil)]),
    // Anatoly Accessory
    ("rt-anatoly-accessory", "Anatoly - Accessory (Day D)",
     "Explosive power and weak point training.",
     "strength", true, ["powerbuilding", "accessory"], nil, nil, nil,
     [("ex-1", 4, 5, 150, nil), ("ex-2", 3, 5, 150, nil), ("ex-40", 3, 8, 90, nil),
      ("ex-7", 3, 12, 60, nil), ("ex-85", 3, 12, 60, nil)]),
    // 7-Minute Workout (HIIT)
    ("rt-hiit-7min", "Classic 7-Minute Workout",
     "12 bodyweight exercises for 30s with 10s rest.",
     "hiit", true, [], 30, 10, 10,
     [("ex-129", 1, 0, 0, nil), ("ex-111", 1, 0, 0, nil), ("ex-23", 1, 0, 0, nil),
      ("ex-20", 1, 0, 0, nil), ("ex-161", 1, 0, 0, nil), ("ex-160", 1, 0, 0, nil),
      ("ex-89", 1, 0, 0, nil), ("ex-15", 1, 0, 0, nil), ("ex-158", 1, 0, 0, nil),
      ("ex-162", 1, 0, 0, nil), ("ex-159", 1, 0, 0, nil), ("ex-157", 1, 0, 0, nil)]),
    // Beginner HIIT Circuit
    ("rt-hiit-beginner", "Beginner HIIT Circuit",
     "A 15-minute workout with 30s work and 30s rest. Complete 3 rounds.",
     "hiit", true, [], 30, 30, 10,
     [("ex-129", 1, 0, 0, nil), ("ex-160", 1, 0, 0, nil), ("ex-131", 1, 0, 0, nil),
      ("ex-23", 1, 0, 0, nil), ("ex-104", 1, 0, 0, nil),
      ("ex-129", 1, 0, 0, nil), ("ex-160", 1, 0, 0, nil), ("ex-131", 1, 0, 0, nil),
      ("ex-23", 1, 0, 0, nil), ("ex-104", 1, 0, 0, nil),
      ("ex-129", 1, 0, 0, nil), ("ex-160", 1, 0, 0, nil), ("ex-131", 1, 0, 0, nil),
      ("ex-23", 1, 0, 0, nil), ("ex-104", 1, 0, 0, nil)]),
]

/// Converts all seed routine tuples into RoutineM models.
public func makeRoutineModels() -> [RoutineM] {
    seedRoutines.map { r in
        let routine = RoutineM(id: r.id, name: r.name, desc: r.description,
                               isTemplate: r.isTemplate, type: r.type)
        routine.tags = r.tags
        routine.hiitWork = r.hiitWork
        routine.hiitRest = r.hiitRest
        routine.hiitPrep = r.hiitPrep

        for (idx, exData) in r.exercises.enumerated() {
            let weId = "we-\(r.id)-\(idx)"
            let we = WorkoutExerciseM(id: weId, exerciseId: exData.exerciseId)
            if let note = exData.note { we.note = note }

            if r.hiitWork != nil {
                // HIIT: no traditional sets needed
                we.sets = []
            } else {
                // Strength: create workout sets
                var sets: [PerformedSetM] = []
                for si in 0..<exData.sets {
                    let type: String = (si == 0 && exData.sets > 1) ? "warmup" : "normal"
                    sets.append(PerformedSetM(id: "\(weId)-s\(si)", reps: exData.reps,
                                              weight: 0, type: type))
                }
                we.sets = sets
                we.restNormal = exData.rest
            }
            routine.exercises.append(we)
        }
        return routine
    }
}
