import Testing
import Foundation
@testable import FortachonCore

struct WeightUtilsTests {

    // MARK: - calculate1RM

    @Test("1RM reps=1 returns exact load")
    func oneRM_singleRep() async throws {
        #expect(calculate1RM(weight: 100, reps: 1) == 100)
    }

    @Test("1RM reps=1 with bodyweight adds load")
    func oneRM_singleRepWithBodyweight() async throws {
        #expect(calculate1RM(weight: 50, reps: 1, bodyWeight: 70) == 120)
    }

    @Test("1RM reps=0 returns 0")
    func oneRM_zeroReps() async throws {
        #expect(calculate1RM(weight: 100, reps: 0) == 0)
        #expect(calculate1RM(weight: 0, reps: 0) == 0)
    }

    @Test("1RM loads=0 with no bodyweight returns 0")
    func oneRM_zeroLoad() async throws {
        #expect(calculate1RM(weight: 0, reps: 5) == 0)
    }

    @Test("1RM caps reps at 20")
    func oneRM_capsAtTwenty() async throws {
        let r20 = calculate1RM(weight: 100, reps: 20)
        #expect(calculate1RM(weight: 100, reps: 30) == r20)
        #expect(calculate1RM(weight: 100, reps: 50) == r20)
    }

    @Test("1RM known values match Lombardi")
    func oneRM_knownValues() async throws {
        #expect(calculate1RM(weight: 100, reps: 5) == 117)
        #expect(calculate1RM(weight: 100, reps: 10) == 126)
        #expect(calculate1RM(weight: 0, reps: 10, bodyWeight: 70) == 88)
    }

    // MARK: - estimateRepsFromPercentage

    @Test("estimateRepsFromPercentage maps correctly")
    func estimateReps_mapping() async throws {
        #expect(estimateRepsFromPercentage(100) == 1)
        #expect(estimateRepsFromPercentage(95) == 2)
        #expect(estimateRepsFromPercentage(90) == 4)
        #expect(estimateRepsFromPercentage(75) == 10)
        #expect(estimateRepsFromPercentage(50) == 25)
    }

    // MARK: - Unit conversion

    @Test("kg to lbs")
    func kgToLbs() async throws {
        #expect(convertKgToLbs(100) == 220.46)
    }

    @Test("lbs to kg")
    func lbsToKg() async throws {
        #expect(convertLbsToKg(220.46) == 99.9991)
    }

    @Test("kg/lbs round-trip within 0.01")
    func unitRoundTrip() async throws {
        let lbs = convertKgToLbs(100.0)
        #expect(abs(convertLbsToKg(lbs) - 100.0) < 0.01)
    }

    // MARK: - formatWeightDisplay

    @Test("formatWeightDisplay: 0kg → \"0\"")
    func format_zero() async throws {
        #expect(formatWeightDisplay(kg: 0, unit: .kg) == "0")
        #expect(formatWeightDisplay(kg: 0, unit: .lbs) == "0")
    }

    @Test("formatWeightDisplay: integer no decimals")
    func format_integer() async throws {
        #expect(formatWeightDisplay(kg: 100, unit: .kg) == "100")
    }

    @Test("formatWeightDisplay: .5 one decimal")
    func format_oneDecimal() async throws {
        #expect(formatWeightDisplay(kg: 100.5, unit: .kg) == "100.5")
    }

    // MARK: - getStoredWeight

    @Test("getStoredWeight: kg stays, lbs converts")
    func storedWeight() async throws {
        #expect(getStoredWeight(displayValue: 100, unit: .kg) == 100)
        #expect(abs(getStoredWeight(displayValue: 220.46, unit: .lbs) - 100.0) < 0.01)
        #expect(getStoredWeight(displayValue: .nan, unit: .kg) == 0)
    }

    // MARK: - cm / ft-in

    @Test("convertCmToFtIn: 170cm ≈ 5'7\"")
    func cmToFtIn() async throws {
        let r = convertCmToFtIn(170)
        #expect(r.feet == 5)
        #expect(r.inches == 7)
    }

    @Test("convertCmToFtIn: invalid returns 0,0")
    func cmToFtIn_invalid() async throws {
        #expect(convertCmToFtIn(0) == (0, 0))
        #expect(convertCmToFtIn(-5) == (0, 0))
    }

    @Test("convertFtInToCm: 5'7\" ≈ 170cm")
    func ftInToCm() async throws {
        #expect(abs(convertFtInToCm(feet: 5, inches: 7) - 170) < 1)
    }

    @Test("convertFtInToCm: both NaN returns 0")
    func ftInToCm_invalid() async throws {
        #expect(convertFtInToCm(feet: .nan, inches: .nan) == 0)
    }
}