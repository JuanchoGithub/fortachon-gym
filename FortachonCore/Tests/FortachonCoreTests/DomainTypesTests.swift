import Testing
import Foundation
@testable import FortachonCore

struct DomainTypesTests {

    // MARK: - ExerciseCategory

    @Test("ExerciseCategory has 12 cases matching TypeScript source")
    func exerciseCategory_caseCount() async throws {
        #expect(ExerciseCategory.allCases.count == 12)
    }

    @Test("ExerciseCategory raw values match TypeScript strings")
    func exerciseCategory_rawValues() async throws {
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
        for category in ExerciseCategory.allCases {
            let encoded = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(ExerciseCategory.self, from: encoded)
            #expect(decoded == category)
        }
    }

    // MARK: - BodyPart

    @Test("BodyPart has 13 cases matching TypeScript source")
    func bodyPart_caseCount() async throws {
        #expect(BodyPart.allCases.count == 13)
    }

    @Test("BodyPart raw values match TypeScript strings")
    func bodyPart_rawValues() async throws {
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
            let encoded = try JSONEncoder().encode(part)
            let decoded = try JSONDecoder().decode(BodyPart.self, from: encoded)
            #expect(decoded == part)
        }
    }

    // MARK: - SetType

    @Test("SetType has 5 cases matching TypeScript source")
    func setType_caseCount() async throws {
        #expect(SetType.allCases.count == 5)
    }

    @Test("SetType raw values match TypeScript strings")
    func setType_rawValues() async throws {
        #expect(SetType.normal.rawValue == "normal")
        #expect(SetType.warmup.rawValue == "warmup")
        #expect(SetType.drop.rawValue == "drop")
        #expect(SetType.failure.rawValue == "failure")
        #expect(SetType.timed.rawValue == "timed")
    }

    @Test("SetType Codable round-trip")
    func setType_codable() async throws {
        for setType in SetType.allCases {
            let encoded = try JSONEncoder().encode(setType)
            let decoded = try JSONDecoder().decode(SetType.self, from: encoded)
            #expect(decoded == setType)
        }
    }
}