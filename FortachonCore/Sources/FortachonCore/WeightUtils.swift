// MARK: - Constants

public let KG_TO_LBS: Double = 2.20462
public let CM_TO_INCHES: Double = 0.393701

// MARK: - Unit conversion

public func convertKgToLbs(_ kg: Double) -> Double {
    return round(kg * KG_TO_LBS * 100) / 100
}

public func convertLbsToKg(_ lbs: Double) -> Double {
    return round((lbs / KG_TO_LBS) * 10000) / 10000
}

// MARK: - 1RM (Lombardi: weight * reps^0.10)

public func calculate1RM(weight: Double, reps: Int, bodyWeight: Double = 0) -> Int {
    if reps == 0 { return 0 }
    let load = weight + bodyWeight
    if load == 0 { return 0 }
    if reps == 1 { return Int(load) }
    let effReps = min(reps, 20)
    return Int(round(load * pow(Double(effReps), 0.10)))
}

public func estimateRepsFromPercentage(_ pct: Int) -> Int {
    if pct >= 100 { return 1 }
    if pct >= 95  { return 2 }
    if pct >= 90  { return 4 }
    if pct >= 85  { return 6 }
    if pct >= 80  { return 8 }
    if pct >= 75  { return 10 }
    if pct >= 70  { return 12 }
    if pct >= 65  { return 15 }
    if pct >= 60  { return 20 }
    return 25
}

// MARK: - Formatting

public func formatWeightDisplay(kg: Double, unit: WeightUnit) -> String {
    if kg == 0 { return "0" }
    let val: Double = unit == .lbs ? convertKgToLbs(kg) : kg
    if val == Double(Int(val)) {
        return String(Int(val))
    }
    return String(format: "%.1f", val)
}

public func getStoredWeight(displayValue: Double, unit: WeightUnit) -> Double {
    if displayValue.isNaN { return 0 }
    return unit == .lbs ? convertLbsToKg(displayValue) : displayValue
}

// MARK: - Height

public func convertCmToFtIn(_ cm: Double) -> (feet: Int, inches: Int) {
    if cm.isNaN || cm <= 0 { return (0, 0) }
    let totalInches = cm * CM_TO_INCHES
    let feet = Int(totalInches / 12)
    var inches = Int(round(totalInches.truncatingRemainder(dividingBy: 12)))
    if inches == 12 { return (feet + 1, 0) }
    return (feet, inches)
}

public func convertFtInToCm(feet: Double, inches: Double) -> Double {
    if feet.isNaN && inches.isNaN { return 0 }
    let f = feet.isNaN ? 0 : feet
    let i = inches.isNaN ? 0 : inches
    return (f * 12 + i) / CM_TO_INCHES
}