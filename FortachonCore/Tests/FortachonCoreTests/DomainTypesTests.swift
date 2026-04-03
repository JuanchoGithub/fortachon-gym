import Testing
import Foundation
@testable import FortachonCore

struct DomainTypesTests {

    // MARK: - ExerciseCategory

    @Test("ExerciseCategory has 12 cases")
    func exerciseCategory_caseCount() {
        #expect(ExerciseCategory.allCases.count == 12)
    }

    @Test("ExerciseCategory raw values match TypeScript")
    func exerciseCategory_rawValues() {
        #expect(ExerciseCategory.barbell.rawValue == "Barbell")
        #expect(ExerciseCategory.dumbbell.rawValue == "Dumbbell")
        #expect(ExerciseCategory.machine.rawValue == "Machine")
        #expect(ExerciseCategory.cable.rawValue == "Cable")
        #expect(ExerciseCategory.bodyweight.rawValue == "Bodyweight")
        #expect(ExerciseCategory.assistedBodyweight.rawValue == "Assisted Bodyweight")
        #expect(ExerciseCategory.kettlebell.rawValue == "Kettlebell")
        #expect(ExerciseCategory.plyometrics.rawValue == "Plyometrics")
        #expect(ExerciseCategory.repsOnly.rawValue == "Reps Only")
        #expect(ExerciseCategory.cardio.rawValue == "Cardio")
        #expect(ExerciseCategory.duration.rawValue == "Duration")
        #expect(ExerciseCategory.smithMachine.rawValue == "Smith Machine")
    }

    @Test("ExerciseCategory Codable round-trip")
    func exerciseCategory_codable() async throws {
        for cat in ExerciseCategory.allCases {
            let data = try JSONEncoder().encode(cat)
            let decoded = try JSONDecoder().decode(ExerciseCategory.self, from: data)
            #expect(decoded == cat)
        }
    }

    // MARK: - BodyPart

    @Test("BodyPart has 13 cases")
    func bodyPart_caseCount() {
        #expect(BodyPart.allCases.count == 13)
    }

    @Test("BodyPart raw values match TypeScript")
    func bodyPart_rawValues() {
        #expect(BodyPart.chest.rawValue == "Chest")
        #expect(BodyPart.back.rawValue == "Back")
        #expect(BodyPart.legs.rawValue == "Legs")
        #expect(BodyPart.glutes.rawValue == "Glutes")
        #expect(BodyPart.shoulders.rawValue == "Shoulders")
        #expect(BodyPart.biceps.rawValue == "Biceps")
        #expect(BodyPart.triceps.rawValue == "Triceps")
        #expect(BodyPart.core.rawValue == "Core")
        #expect(BodyPart.fullBody.rawValue == "Full Body")
        #expect(BodyPart.calves.rawValue == "Calves")
        #expect(BodyPart.forearms.rawValue == "Forearms")
        #expect(BodyPart.mobility.rawValue == "Mobility")
        #expect(BodyPart.cardio.rawValue == "Cardio")
    }

    @Test("BodyPart Codable round-trip")
    func bodyPart_codable() async throws {
        for part in BodyPart.allCases {
            let data = try JSONEncoder().encode(part)
            let decoded = try JSONDecoder().decode(BodyPart.self, from: data)
            #expect(decoded == part)
        }
    }

    // MARK: - SetType

    @Test("SetType has 5 cases")
    func setType_caseCount() {
        #expect(SetType.allCases.count == 5)
    }

    @Test("SetType raw values match TypeScript")
    func setType_rawValues() {
        #expect(SetType.normal.rawValue == "normal")
        #expect(SetType.warmup.rawValue == "warmup")
        #expect(SetType.drop.rawValue == "drop")
        #expect(SetType.failure.rawValue == "failure")
        #expect(SetType.timed.rawValue == "timed")
    }

    @Test("SetType Codable round-trip")
    func setType_codable() async throws {
        for st in SetType.allCases {
            let data = try JSONEncoder().encode(st)
            let decoded = try JSONDecoder().decode(SetType.self, from: data)
            #expect(decoded == st)
        }
    }

    // MARK: - UserGoal

    @Test("UserGoal has 3 cases")
    func userGoal_caseCount() {
        #expect(UserGoal.allCases.count == 3)
    }

    @Test("UserGoal raw values match")
    func userGoal_rawValues() {
        #expect(UserGoal.strength.rawValue == "strength")
        #expect(UserGoal.muscle.rawValue == "muscle")
        #expect(UserGoal.endurance.rawValue == "endurance")
    }
}
