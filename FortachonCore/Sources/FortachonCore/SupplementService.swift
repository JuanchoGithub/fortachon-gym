import Foundation

// MARK: - Supplement Plan Generation

/// Generates a personalized supplement plan based on user info.
/// Ported from web version's supplementService.ts
public func generateSupplementPlan(info: SupplementInfo, customSupplements: [SupplementPlanItem] = []) -> SupplementPlan {
    var plan: [SupplementPlanItem] = []
    var warnings: [String] = []
    var generalTips: [String] = []

    // --- Helper variables ---
    let birthDate = parseDate(info.dob)
    let today = Date()
    let age = calculateAge(from: birthDate, to: today)
    
    let bmi = info.weight / pow(info.height / 100, 2)
    let nivel = activityLevelValue(info.activityLevel)
    let objetivo = objectiveValue(info.objective)
    let dietaProt: Double = {
        if info.proteinUnknown { return info.weight * 1.2 }
        return info.proteinConsumption ?? info.weight * 1.2
    }()
    let numTrainingDays = info.trainingDays.count

    // --- Health Conditions & Allergies ---
    let hasKidneyIssues = info.medicalConditions.range(of: "kidney|renal", options: .regularExpression) != nil
    let hasHypertension = info.medicalConditions.range(of: "pressure|hypertension", options: .regularExpression) != nil
    let isLactoseIntolerant = info.allergies.contains { $0.range(of: "lactose|dairy", options: .regularExpression) != nil }
    let isVegan = info.allergies.contains { $0.range(of: "vegan", options: .regularExpression) != nil }

    if hasKidneyIssues {
        warnings.append("You mentioned kidney/renal issues. It is CRITICAL to consult your doctor before taking supplements like protein and creatine.")
    }
    if hasHypertension {
        warnings.append("You mentioned high blood pressure. Be cautious with stimulants like caffeine. Consult your doctor.")
    }

    // --- Check for combined Protein + EAA ---
    let hasCombinedProteinEaa = customSupplements.contains { item in
        let name = item.supplement.lowercased()
        return name.contains("protein") && (name.contains("eaa") || name.contains("bcaa"))
    }

    // --- 1. Protein ---
    var protTotalNeededFactor: Double = 1.6
    if objetivo == 1 { protTotalNeededFactor = 2.0 } // Gain
    if objetivo == 2 { protTotalNeededFactor = 2.2 } // Lose
    if numTrainingDays >= 4 { protTotalNeededFactor += 0.2 }
    if info.gender == "female" { protTotalNeededFactor -= 0.2 }

    let protTotalNeeded = max(1.6, min(2.2, protTotalNeededFactor)) * info.weight
    var wheyNeeded = protTotalNeeded - dietaProt

    let wantsProtein = info.desiredSupplements.contains { $0.range(of: "protein|whey", options: .regularExpression) != nil }
    
    if (isVegan && wheyNeeded > 15) || wheyNeeded > 15 || wantsProtein {
        var proteinType = "Whey Protein"
        if isLactoseIntolerant { proteinType = "Whey Isolate" }
        if isVegan { proteinType = "Plant-Based Protein Blend" }
        
        // Cap at 3 servings from shakes
        wheyNeeded = min(120, wheyNeeded)
        var doses = Int(ceil(wheyNeeded / 40))
        doses = max(1, min(3, doses))

        let dosagePerServing = Int(round(wheyNeeded / Double(doses)))
        
        if doses > 0 && dosagePerServing > 10 {
            // Dose 1A: Training Days (Post-Workout)
            plan.append(SupplementPlanItem(
                id: "gen-protein-1-train-\(Date().timeIntervalSince1970)",
                supplement: proteinType,
                dosage: "~\(dosagePerServing)g",
                time: "Post-workout",
                notes: "Take after your workout to kickstart muscle repair. Dose 1 of \(doses) to help reach your daily protein goal of ~\(Int(protTotalNeeded))g.",
                trainingDayOnly: true
            ))

            // Dose 1B: Rest Days (Morning/Breakfast)
            plan.append(SupplementPlanItem(
                id: "gen-protein-1-rest-\(Date().timeIntervalSince1970)",
                supplement: proteinType,
                dosage: "~\(dosagePerServing)g",
                time: "With Breakfast",
                notes: "Take with your first meal to ensure a steady supply of protein throughout the day. Dose 1 of \(doses) to help reach your daily protein goal of ~\(Int(protTotalNeeded))g.",
                restDayOnly: true
            ))

            // Dose 2: With Lunch (Daily)
            if doses >= 2 {
                plan.append(SupplementPlanItem(
                    id: "gen-protein-2-\(Date().timeIntervalSince1970)",
                    supplement: proteinType,
                    dosage: "~\(dosagePerServing)g",
                    time: "With Lunch",
                    notes: "Take with your midday meal to maintain amino acid levels. Dose 2 of \(doses) to help reach your daily protein goal of ~\(Int(protTotalNeeded))g."
                ))
            }

            // Dose 3: Before Bed
            if doses >= 3 {
                plan.append(SupplementPlanItem(
                    id: "gen-protein-3-\(Date().timeIntervalSince1970)",
                    supplement: proteinType,
                    dosage: "~\(dosagePerServing)g",
                    time: "Before Bed",
                    notes: "Take before bed to aid muscle recovery overnight. Dose 3 of \(doses) to help reach your daily protein goal of ~\(Int(protTotalNeeded))g."
                ))
            }
        }
    }

    // --- 2. Creatine ---
    let wantsCreatine = info.desiredSupplements.contains { $0.range(of: "creatine", options: .regularExpression) != nil }
    if (info.routineType == "strength" || info.routineType == "mixed" || wantsCreatine) && !hasKidneyIssues {
        var dosisCreatina = 0.03 * info.weight + Double(nivel - 1) * 1
        dosisCreatina = max(3, min(5, dosisCreatina))
        if objetivo == 2 { dosisCreatina = max(3, dosisCreatina - 1) }
        if age > 40 { dosisCreatina += 1 }
        dosisCreatina = Double(Int(round(min(5, dosisCreatina))))

        // Training Days (Post-Workout)
        plan.append(SupplementPlanItem(
            id: "gen-creatine-train-\(Date().timeIntervalSince1970)",
            supplement: "Creatine Monohydrate",
            dosage: "\(Int(dosisCreatina))g",
            time: "Post-workout",
            notes: "Improves strength, power output, and muscle mass. Mix with water or your post-workout shake.",
            trainingDayOnly: true
        ))

        // Rest Days (Morning/Breakfast)
        plan.append(SupplementPlanItem(
            id: "gen-creatine-rest-\(Date().timeIntervalSince1970)",
            supplement: "Creatine Monohydrate",
            dosage: "\(Int(dosisCreatina))g",
            time: "With Breakfast",
            notes: "Improves strength, power output, and muscle mass. Mix with water or your post-workout shake.",
            restDayOnly: true
        ))
    }
    
    // --- 3. Omega-3 ---
    let wantsOmega = info.desiredSupplements.contains { $0.range(of: "omega", options: .regularExpression) != nil }
    if age > 35 || objetivo == 2 || wantsOmega {
        var dosisOmega = 1.0 + (age > 40 ? 0.5 : 0) + (objetivo == 2 ? 0.5 : 0)
        dosisOmega = min(3, dosisOmega)
        plan.append(SupplementPlanItem(
            id: "gen-omega3-\(Date().timeIntervalSince1970)",
            supplement: isVegan ? "Algae Oil (Omega-3)" : "Fish Oil (Omega-3)",
            dosage: String(format: "%.1fg EPA+DHA", dosisOmega),
            time: "Daily with a meal",
            notes: "Supports joint health, reduces inflammation, and aids in overall recovery."
        ))
    }
    
    // --- 4. Vitamin D3 ---
    let hasVitDDeficiency = info.deficiencies.contains { $0.range(of: "vitamin d|vit d", options: .regularExpression) != nil }
    let wantsVitD = info.desiredSupplements.contains { $0.range(of: "vitamin d|vit d", options: .regularExpression) != nil }
    if age > 35 || hasVitDDeficiency || wantsVitD {
        var dosisVitD = 1000.0
        if hasVitDDeficiency { dosisVitD = 2000 }
        if age > 40 { dosisVitD += 500 }
        if bmi > 25 { dosisVitD += 500 }
        dosisVitD = min(4000, round(dosisVitD / 500) * 500)

        plan.append(SupplementPlanItem(
            id: "gen-vitd3-\(Date().timeIntervalSince1970)",
            supplement: "Vitamin D3",
            dosage: "\(Int(dosisVitD)) IU",
            time: "Morning with a meal",
            notes: "Essential for bone health, immune function, and hormone regulation."
        ))
    }
    
    // --- 5. Magnesium ---
    let hasMgDeficiency = info.deficiencies.contains { $0.range(of: "magnesium|mg", options: .regularExpression) != nil }
    let wantsMg = info.desiredSupplements.contains { $0.range(of: "magnesium|mg", options: .regularExpression) != nil }
    if nivel > 1 || age > 35 || hasMgDeficiency || wantsMg {
        var dosisMg = info.gender == "male" ? 350.0 : 300.0
        if nivel > 2 { dosisMg += 50 }
        let maxMg = info.gender == "male" ? 420.0 : 320.0
        dosisMg = min(maxMg, dosisMg)
        dosisMg = round(dosisMg / 50) * 50

        plan.append(SupplementPlanItem(
            id: "gen-magnesium-\(Date().timeIntervalSince1970)",
            supplement: "Magnesium (Glycinate/Citrate)",
            dosage: "\(Int(dosisMg))mg",
            time: "Before Bed",
            notes: "Aids in muscle relaxation, improves sleep quality, and supports energy production."
        ))
    }

    // --- 6. Beta-Alanine ---
    let wantsBeta = info.desiredSupplements.contains { $0.range(of: "beta alanine|beta-alanine", options: .regularExpression) != nil }
    if (info.routineType == "strength" || info.routineType == "mixed") && (nivel > 1 || wantsBeta) {
        var dosisBeta = 0.04 * info.weight
        dosisBeta = max(2, min(5, dosisBeta))
        let roundedDosisBeta = Int(round(dosisBeta))

        var notes = "Increases muscular endurance on training days. May cause a harmless tingling sensation (paresthesia)."
        if roundedDosisBeta > 3 {
            notes += " Split into two doses of \(roundedDosisBeta / 2)g to reduce tingling."
        }
        plan.append(SupplementPlanItem(
            id: "gen-betaalanine-\(Date().timeIntervalSince1970)",
            supplement: "Beta-Alanine",
            dosage: "\(roundedDosisBeta)g",
            time: "Pre-workout",
            notes: notes,
            trainingDayOnly: true
        ))
    }

    // --- 7. Caffeine ---
    let wantsCaffeine = info.desiredSupplements.contains { $0.range(of: "caffeine|pre-workout", options: .regularExpression) != nil }
    if (info.routineType != "cardio" && nivel > 1 && !hasHypertension) || wantsCaffeine {
        var dosisCaffeine = (3.0 * info.weight) / 20.0 + Double(nivel > 2 ? 50 : 0)
        dosisCaffeine = max(100, min(300, dosisCaffeine))
        dosisCaffeine = round(dosisCaffeine / 50) * 50
        plan.append(SupplementPlanItem(
            id: "gen-caffeine-\(Date().timeIntervalSince1970)",
            supplement: "Caffeine",
            dosage: "\(Int(dosisCaffeine))mg",
            time: "Pre-workout",
            notes: "Improves focus, energy, and performance on training days. Can be taken as a pill or in pre-workout drinks.",
            trainingDayOnly: true
        ))
    }

    // --- General Tips ---
    if info.hydration < 2.5 {
        generalTips.append("Increase daily water intake to at least 2.5-3 liters, especially if taking creatine. Proper hydration is key for performance and health.")
    }
    generalTips.append("Consistency is key. Take your supplements daily as recommended to see the best results.")
    generalTips.append("Supplements complement a balanced diet and consistent training; they do not replace them.")
    if wheyNeeded > 10 {
        generalTips.append("Prioritize whole food protein sources (chicken, fish, eggs, legumes). Use powder to fill the gaps.")
    }

    // Filter out generated items that are already in custom list
    let customNames = Set(customSupplements.map { $0.supplement.lowercased() })
    let filteredPlan = plan.filter { !customNames.contains($0.supplement.lowercased()) }

    // Merge with custom supplements
    var finalPlan = filteredPlan + customSupplements

    // Sort plan by time of day
    finalPlan.sort { a, b in
        let orderA = timeOrderValue(a.time)
        let orderB = timeOrderValue(b.time)
        return orderA < orderB
    }

    return SupplementPlan(info: info, plan: finalPlan, warnings: warnings, generalTips: generalTips)
}

// MARK: - Helper Functions

private func parseDate(_ dateString: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: dateString) ?? Date().addingTimeInterval(-30 * 365 * 24 * 3600)
}

private func calculateAge(from birthDate: Date, to today: Date) -> Int {
    let calendar = Calendar.current
    let ageComponents = calendar.dateComponents([.year], from: birthDate, to: today)
    return ageComponents.year ?? 18
}

private func activityLevelValue(_ level: String) -> Int {
    switch level {
    case "beginner": return 1
    case "intermediate": return 2
    case "advanced": return 3
    default: return 2
    }
}

private func objectiveValue(_ objective: String) -> Int {
    switch objective {
    case "gain": return 1
    case "lose": return 2
    case "maintain": return 3
    default: return 3
    }
}

private func timeOrderValue(_ time: String) -> Double {
    let lower = time.lowercased()
    if lower.contains("pre-workout") || lower.contains("pre-entreno") { return 0.5 }
    if lower.contains("breakfast") || lower.contains("morning") { return 1.0 }
    if lower.contains("intra") { return 2.5 }
    if lower.contains("post-workout") || lower.contains("post-entreno") { return 3.0 }
    if lower.contains("lunch") { return 3.5 }
    if lower.contains("meal") { return 4.0 }
    if lower.contains("bed") || lower.contains("evening") || lower.contains("night") { return 5.0 }
    return 6.0
}

// MARK: - Supplement Library

/// Returns the predefined supplement library.
public func getSupplementLibrary() -> [SupplementLibraryItem] {
    return [
        SupplementLibraryItem(id: "lib-creatine", key: "creatine", category: "Performance", descriptionKey: "Improves strength, power output, and muscle mass.", defaultDose: "5g", defaultTime: "Post-workout"),
        SupplementLibraryItem(id: "lib-whey", key: "whey", category: "Protein", descriptionKey: "Fast-digesting protein for muscle repair and growth.", defaultDose: "30g", defaultTime: "Post-workout"),
        SupplementLibraryItem(id: "lib-caffeine", key: "caffeine", category: "Performance", descriptionKey: "Boosts energy, focus, and endurance performance.", defaultDose: "200mg", defaultTime: "Pre-workout"),
        SupplementLibraryItem(id: "lib-multivitamin", key: "multivitamin", category: "Health", descriptionKey: "Fills nutritional gaps for overall health.", defaultDose: "1 tablet", defaultTime: "Morning"),
        SupplementLibraryItem(id: "lib-omega", key: "omega", category: "Health", descriptionKey: "Supports heart, brain, and joint health.", defaultDose: "2g", defaultTime: "Daily with a meal"),
        SupplementLibraryItem(id: "lib-vitd3", key: "vitd3", category: "Health", descriptionKey: "Essential for bone health and immune function.", defaultDose: "2000 IU", defaultTime: "Morning"),
        SupplementLibraryItem(id: "lib-magnesium", key: "magnesium", category: "Recovery", descriptionKey: "Aids muscle relaxation and sleep quality.", defaultDose: "400mg", defaultTime: "Before Bed"),
        SupplementLibraryItem(id: "lib-zma", key: "zma", category: "Recovery", descriptionKey: "Supports sleep and recovery.", defaultDose: "1 capsule", defaultTime: "Before Bed"),
        SupplementLibraryItem(id: "lib-bcaa", key: "bcaa", category: "Recovery", descriptionKey: "Reduces muscle breakdown and fatigue.", defaultDose: "10g", defaultTime: "Intra-workout"),
        SupplementLibraryItem(id: "lib-beta", key: "beta", category: "Performance", descriptionKey: "Improves muscular endurance and delays fatigue.", defaultDose: "3g", defaultTime: "Pre-workout"),
        SupplementLibraryItem(id: "lib-citrulline", key: "citrulline", category: "Performance", descriptionKey: "Enhances blood flow and muscle pumps.", defaultDose: "6g", defaultTime: "Pre-workout"),
        SupplementLibraryItem(id: "lib-glutamine", key: "glutamine", category: "Recovery", descriptionKey: "Supports gut health and immune system.", defaultDose: "5g", defaultTime: "Post-workout"),
        SupplementLibraryItem(id: "lib-casein", key: "casein", category: "Protein", descriptionKey: "Slow-digesting protein, ideal before bed.", defaultDose: "30g", defaultTime: "Before Bed"),
        SupplementLibraryItem(id: "lib-electrolytes", key: "electrolytes", category: "Hydration", descriptionKey: "Maintains hydration during intense exercise.", defaultDose: "1 serving", defaultTime: "Intra-workout"),
        SupplementLibraryItem(id: "lib-ashwagandha", key: "ashwagandha", category: "Health", descriptionKey: "Adaptogen that helps manage stress and cortisol.", defaultDose: "600mg", defaultTime: "Evening"),
        SupplementLibraryItem(id: "lib-melatonin", key: "melatonin", category: "Recovery", descriptionKey: "Regulates sleep cycle.", defaultDose: "3mg", defaultTime: "Before Bed"),
        SupplementLibraryItem(id: "lib-carnitine", key: "carnitine", category: "Fat Loss", descriptionKey: "Aids in fat metabolism and energy production.", defaultDose: "2g", defaultTime: "Morning"),
        SupplementLibraryItem(id: "lib-collagen", key: "collagen", category: "Health", descriptionKey: "Supports joint, skin, and hair health.", defaultDose: "10g", defaultTime: "Daily"),
        SupplementLibraryItem(id: "lib-iron", key: "iron", category: "Health", descriptionKey: "Essential for oxygen transport in the blood.", defaultDose: "1 tablet", defaultTime: "Morning"),
        SupplementLibraryItem(id: "lib-preworkout", key: "preworkout", category: "Performance", descriptionKey: "Blend of ingredients to boost workout performance.", defaultDose: "1 scoop", defaultTime: "Pre-workout"),
    ]
}

// MARK: - Supplement Explanations

/// Returns explanations for supplements in the plan.
public func generateSupplementExplanations(for plan: SupplementPlan) -> [SupplementExplanation] {
    var explanations: [SupplementExplanation] = []
    
    let supplementMap: [String: SupplementExplanation] = [
        "creatine": SupplementExplanation(
            id: "creatine", name: "Creatine Monohydrate", category: "Performance",
            description: "One of the most researched supplements. Improves strength, power output, and muscle mass.",
            benefits: ["Increased strength", "Improved power output", "Enhanced muscle mass", "Better recovery"],
            sideEffects: ["Water retention", "Digestive discomfort if taken without water"],
            dosage: "3-5g daily", timing: "Post-workout on training days, morning on rest days",
            stackWith: ["Protein", "Beta-Alanine"]
        ),
        "protein": SupplementExplanation(
            id: "protein", name: "Whey Protein", category: "Protein",
            description: "Fast-digesting protein source for muscle repair and growth.",
            benefits: ["Muscle repair", "Convenient protein source", "Fast absorption"],
            sideEffects: ["Bloating (if lactose intolerant)"],
            dosage: "20-40g per serving", timing: "Post-workout or between meals",
            stackWith: ["Creatine", "EAAs"]
        ),
        "caffeine": SupplementExplanation(
            id: "caffeine", name: "Caffeine", category: "Performance",
            description: "Natural stimulant that boosts energy, focus, and endurance.",
            benefits: ["Increased energy", "Better focus", "Enhanced endurance"],
            sideEffects: ["Jitters", "Sleep disruption if taken late", "Tolerance buildup"],
            dosage: "100-300mg", timing: "30-60 minutes before workout",
            stackWith: ["Beta-Alanine", "Citrulline"]
        ),
        "omega": SupplementExplanation(
            id: "omega", name: "Omega-3 Fish Oil", category: "Health",
            description: "Essential fatty acids for heart, brain, and joint health.",
            benefits: ["Reduced inflammation", "Heart health", "Joint support"],
            sideEffects: ["Fishy aftertaste"],
            dosage: "1-3g EPA+DHA", timing: "With meals",
            stackWith: ["Vitamin D3", "Multivitamin"]
        ),
        "vitd3": SupplementExplanation(
            id: "vitd3", name: "Vitamin D3", category: "Health",
            description: "Essential vitamin for bone health and immune function.",
            benefits: ["Bone health", "Immune support", "Mood improvement"],
            sideEffects: ["None at recommended doses"],
            dosage: "1000-4000 IU", timing: "Morning with food",
            stackWith: ["Omega-3", "Magnesium"]
        ),
        "magnesium": SupplementExplanation(
            id: "magnesium", name: "Magnesium", category: "Recovery",
            description: "Essential mineral for muscle relaxation and sleep.",
            benefits: ["Better sleep", "Muscle relaxation", "Energy production"],
            sideEffects: ["Digestive upset at high doses"],
            dosage: "300-400mg", timing: "Before bed",
            stackWith: ["ZMA", "Zinc"]
        ),
        "beta": SupplementExplanation(
            id: "beta", name: "Beta-Alanine", category: "Performance",
            description: "Amino acid that improves muscular endurance.",
            benefits: ["Increased endurance", "Delayed fatigue"],
            sideEffects: ["Harmless tingling (paresthesia)"],
            dosage: "2-5g daily", timing: "Pre-workout",
            stackWith: ["Creatine", "Caffeine"]
        ),
        "citrulline": SupplementExplanation(
            id: "citrulline", name: "Citrulline Malate", category: "Performance",
            description: "Amino acid that enhances blood flow and muscle pumps.",
            benefits: ["Better pumps", "Improved endurance", "Faster recovery"],
            sideEffects: ["Mild stomach discomfort"],
            dosage: "6-8g", timing: "30-45 min before workout",
            stackWith: ["Caffeine", "Beta-Alanine"]
        ),
        "eaa": SupplementExplanation(
            id: "eaa", name: "EAAs / BCAAs", category: "Recovery",
            description: "Essential amino acids that prevent muscle breakdown.",
            benefits: ["Reduced muscle breakdown", "Faster recovery", "Fasted training support"],
            sideEffects: ["None at recommended doses"],
            dosage: "5-10g", timing: "Intra-workout or pre-workout",
            stackWith: ["Electrolytes", "Carbs"]
        ),
        "electrolytes": SupplementExplanation(
            id: "electrolytes", name: "Electrolytes", category: "Hydration",
            description: "Essential minerals for hydration during intense exercise.",
            benefits: ["Better hydration", "Cramp prevention", "Sustained energy"],
            sideEffects: ["None at recommended doses"],
            dosage: "1 serving", timing: "During workout",
            stackWith: ["EAAs", "Carbs"]
        ),
        "zma": SupplementExplanation(
            id: "zma", name: "ZMA", category: "Recovery",
            description: "Zinc, Magnesium, and B6 blend for sleep and recovery.",
            benefits: ["Better sleep quality", "Improved recovery", "Hormone support"],
            sideEffects: ["Vivid dreams"],
            dosage: "1 capsule", timing: "Before bed on empty stomach",
            stackWith: ["Magnesium", "Melatonin"]
        ),
        "joint": SupplementExplanation(
            id: "joint", name: "Joint Support", category: "Health",
            description: "Supplements to support connective tissue health.",
            benefits: ["Joint health", "Reduced joint pain", "Improved mobility"],
            sideEffects: ["None at recommended doses"],
            dosage: "As directed", timing: "With meals",
            stackWith: ["Collagen", "Omega-3"]
        ),
    ]
    
    // Find matching explanations for items in the plan
    for item in plan.plan {
        let nameLower = item.supplement.lowercased()
        for (key, explanation) in supplementMap {
            if nameLower.contains(key) {
                explanations.append(explanation)
                break
            }
        }
    }
    
    return explanations
}

// MARK: - Plan Review / Suggestions Engine

/// Reviews the supplement plan and generates suggestions based on activity.
public func reviewSupplementPlan(
    plan: SupplementPlan,
    history: [WorkoutSession],
    takenSupplements: [String: [String]] = [:],
    supplementLogs: [String: [TimeInterval]] = [:]
) -> [SupplementSuggestion] {
    var suggestions: [SupplementSuggestion] = []
    let now = Date()
    let fourWeeksAgo = now.addingTimeInterval(-28 * 24 * 3600)
    let twoWeeksAgo = now.addingTimeInterval(-14 * 24 * 3600)

    let recentHistory = history.filter { $0.startTime > fourWeeksAgo.timeIntervalSince1970 * 1000 }
    
    // --- STOCK CHECK ---
    for item in plan.plan {
        if let stock = item.stock, stock <= 5 && stock > 0 {
            suggestions.append(SupplementSuggestion(
                id: "restock-\(item.id)",
                title: "Low Stock Alert: \(item.supplement)",
                reason: "You have \(stock) servings left. Time to buy more!",
                action: .update(itemId: item.id, updates: SupplementPlanUpdates(stock: stock + 30)),
                identifier: "UPDATE:\(item.supplement):restock"
            ))
        }
    }

    if recentHistory.count < 3 {
        return suggestions
    }

    // --- METRICS CALCULATION ---
    
    // 1. Volume Calculation
    let totalVolumeLast4Weeks = recentHistory.reduce(0) { total, session in
        total + session.exercises.reduce(0) { sessionTotal, ex in
            sessionTotal + ex.sets.reduce(0) { exTotal, set in
                exTotal + (set.isComplete ? set.weight * Double(set.reps) : 0)
            }
        }
    }
    let avgWeeklyVolume = totalVolumeLast4Weeks / 4.0

    // 2. Duration Analysis
    let longSessions = recentHistory.filter { session in
        let duration = session.endTime - session.startTime
        return duration > 80 * 60 * 1000 // 80 minutes
    }
    let isLongDurationUser = Double(longSessions.count) > Double(recentHistory.count) * 0.4

    // 3. Time of Day Analysis
    var lateNightWorkouts = 0
    var earlyMorningWorkouts = 0
    
    for session in recentHistory {
        let hour = Calendar.current.component(.hour, from: Date(timeIntervalSince1970: session.startTime / 1000))
        if hour >= 20 { lateNightWorkouts += 1 }
        if hour < 9 { earlyMorningWorkouts += 1 }
    }
    
    let isLateNightUser = Double(lateNightWorkouts) > Double(recentHistory.count) * 0.3
    let isEarlyMorningUser = Double(earlyMorningWorkouts) > Double(recentHistory.count) * 0.5

    // 4. High Impact
    var highImpactCount = 0
    var totalExercises = 0
    
    for session in recentHistory {
        for ex in session.exercises {
            totalExercises += 1
            // Simplified: check exercise ID patterns
            if ex.exerciseId.contains("leg") || ex.exerciseId.contains("back") || ex.exerciseId.contains("squat") || ex.exerciseId.contains("deadlift") {
                highImpactCount += 1
            }
        }
    }
    let isHighImpactUser = totalExercises > 0 && Double(highImpactCount) / Double(totalExercises) > 0.3

    // 5. Volume Trend
    let last2WeeksHistory = recentHistory.filter { $0.startTime > twoWeeksAgo.timeIntervalSince1970 * 1000 }
    let prev2WeeksHistory = recentHistory.filter { $0.startTime <= twoWeeksAgo.timeIntervalSince1970 * 1000 }
    
    let volLast2 = last2WeeksHistory.reduce(0) { acc, s in
        acc + s.exercises.reduce(0) { t, e in
            t + e.sets.reduce(0) { st, set in st + (set.isComplete ? set.weight * Double(set.reps) : 0) }
        }
    }
    let volPrev2 = prev2WeeksHistory.reduce(0) { acc, s in
        acc + s.exercises.reduce(0) { t, e in
            t + e.sets.reduce(0) { st, set in st + (set.isComplete ? set.weight * Double(set.reps) : 0) }
        }
    }
    
    let isStagnating = last2WeeksHistory.count >= 2 && prev2WeeksHistory.count >= 2 &&
                       volLast2 <= volPrev2 * 1.05 && volLast2 >= volPrev2 * 0.95
    let volumeDropRatio = volPrev2 > 0 ? volLast2 / volPrev2 : 1.0
    let isSignificantVolumeDrop = volumeDropRatio < 0.5 && prev2WeeksHistory.count > 0

    // 6. Workout Density
    var totalDensity: Double = 0
    var densityCount = 0
    for session in recentHistory {
        let durationMinutes = (session.endTime - session.startTime) / 60000
        if durationMinutes > 10 {
            let volume = session.exercises.reduce(0) { t, ex in
                t + ex.sets.reduce(0) { st, set in st + (set.isComplete ? set.weight * Double(set.reps) : 0) }
            }
            totalDensity += volume / durationMinutes
            densityCount += 1
        }
    }
    let avgDensity = densityCount > 0 ? totalDensity / Double(densityCount) : 0
    let isHighDensity = avgDensity > 250

    // 7. Training Frequency
    let sortedSessions = recentHistory.sorted { $0.startTime < $1.startTime }
    var maxStreak = 0
    var currentStreak = 1
    var streak3PlusCount = 0

    for i in 1..<sortedSessions.count {
        let prevDate = Date(timeIntervalSince1970: sortedSessions[i-1].startTime / 1000)
        let currDate = Date(timeIntervalSince1970: sortedSessions[i].startTime / 1000)
        let daysDiff = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: prevDate), to: Calendar.current.startOfDay(for: currDate)).day ?? 0
        
        if daysDiff == 1 {
            currentStreak += 1
        } else if daysDiff > 1 {
            if currentStreak >= 3 { streak3PlusCount += 1 }
            maxStreak = max(maxStreak, currentStreak)
            currentStreak = 1
        }
    }
    if currentStreak >= 3 { streak3PlusCount += 1 }
    let isHighFrequency = streak3PlusCount >= 2

    // --- GENERATING SUGGESTIONS ---
    let isStrengthTraining = plan.info.routineType == "strength" || plan.info.routineType == "mixed"
    
    // Suggestion 1: Add Creatine
    let hasCreatine = plan.plan.contains { $0.supplement.lowercased().contains("creatine") }
    if isStrengthTraining && !hasCreatine && avgWeeklyVolume > 15000 {
        let dose = Int(round(min(5, max(3, 0.03 * plan.info.weight))))
        suggestions.append(SupplementSuggestion(
            id: "add-creatine-volume",
            title: "Consider Adding Creatine",
            reason: "Your training volume is high. Creatine can help improve strength and performance.",
            action: .add(item: SupplementPlanItem(
                id: "gen-creatine-\(Date().timeIntervalSince1970)",
                supplement: "Creatine Monohydrate",
                dosage: "\(dose)g",
                time: "Post-workout",
                notes: "Improves strength, power output, and muscle mass.",
                trainingDayOnly: true
            )),
            identifier: "ADD:Creatine Monohydrate"
        ))
    }

    // Suggestion 2: Increase Protein
    let proteinItems = plan.plan.filter { $0.supplement.lowercased().contains("protein") }
    if plan.info.objective == "gain" && avgWeeklyVolume > 20000 && proteinItems.count > 0 {
        let firstProtein = proteinItems[0]
        let currentDosage = Int(firstProtein.dosage.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) ?? 0
        if currentDosage > 0 && currentDosage < 40 {
            let newDosage = Int(round(Double(currentDosage) * 1.25 / 5) * 5)
            let increaseAmount = newDosage - currentDosage
            if increaseAmount > 0 {
                suggestions.append(SupplementSuggestion(
                    id: "increase-protein-gain",
                    title: "Consider Increasing Protein",
                    reason: "Your volume is high and your goal is to gain muscle. A bit more protein could support recovery.",
                    action: .update(itemId: firstProtein.id, updates: SupplementPlanUpdates(dosage: "~\(newDosage)g")),
                    identifier: "UPDATE:\(firstProtein.supplement):dosage:increase:\(increaseAmount)g"
                ))
            }
        }
    }

    // Suggestion 3: Remove Late Caffeine
    let caffeineItem = plan.plan.first { $0.supplement.lowercased().contains("caffeine") }
    if let caffeineItem = caffeineItem, isLateNightUser {
        suggestions.append(SupplementSuggestion(
            id: "remove-caffeine-late",
            title: "Reconsider Caffeine Timing",
            reason: "You frequently train late at night. Taking stimulants like caffeine can negatively impact your sleep, which is crucial for recovery.",
            action: .remove(itemId: caffeineItem.id),
            identifier: "REMOVE:Caffeine"
        ))
    }

    // Suggestion 4: Electrolytes
    let hasElectrolytes = plan.plan.contains { $0.supplement.lowercased().contains("electrolyte") || $0.supplement.lowercased().contains("intra") }
    if isLongDurationUser && !hasElectrolytes {
        suggestions.append(SupplementSuggestion(
            id: "add-electrolytes-long",
            title: "Consider Electrolytes",
            reason: "Your workouts are consistently longer than 80 minutes. Replenishing electrolytes during training can help maintain performance and prevent cramping.",
            action: .add(item: SupplementPlanItem(
                id: "gen-electrolytes-\(Date().timeIntervalSince1970)",
                supplement: "Electrolytes",
                dosage: "1 serving",
                time: "Intra-workout",
                notes: "Sip during your workout to maintain hydration and energy levels.",
                trainingDayOnly: true
            )),
            identifier: "ADD:Electrolytes"
        ))
    }

    // Suggestion 5: Joint Support
    let hasJointSupport = plan.plan.contains { $0.supplement.lowercased().contains("joint") || $0.supplement.lowercased().contains("collagen") }
    if (isHighImpactUser && !hasJointSupport) {
        suggestions.append(SupplementSuggestion(
            id: "add-joint-support",
            title: "Consider Joint Support",
            reason: "You are doing a high frequency of high-impact or heavy leg exercises. Supplements like Collagen or Glucosamine might help protect your joints.",
            action: .add(item: SupplementPlanItem(
                id: "gen-joint-\(Date().timeIntervalSince1970)",
                supplement: "Joint Support",
                dosage: "1 serving",
                time: "Daily with a meal",
                notes: "Take daily to support connective tissue health."
            )),
            identifier: "ADD:Joint Support"
        ))
    }

    // Suggestion 6: Citrulline for Stagnation
    let hasCitrulline = plan.plan.contains { $0.supplement.lowercased().contains("citrulline") }
    if isStagnating && !hasCitrulline && isStrengthTraining {
        suggestions.append(SupplementSuggestion(
            id: "add-citrulline-plateau",
            title: "Plateau Breaker",
            reason: "Your training volume has plateaued recently. Citrulline Malate may help improve blood flow and endurance to push past this sticking point.",
            action: .add(item: SupplementPlanItem(
                id: "gen-citrulline-\(Date().timeIntervalSince1970)",
                supplement: "Citrulline Malate",
                dosage: "6g",
                time: "Pre-workout",
                notes: "Take 30-45 minutes before training to improve blood flow and pumps.",
                trainingDayOnly: true
            )),
            identifier: "ADD:Citrulline Malate"
        ))
    }

    // Suggestion 7: EAAs for High Density
    let hasEAA = plan.plan.contains { $0.supplement.lowercased().contains("eaa") || $0.supplement.lowercased().contains("bcaa") }
    if isHighDensity && !hasEAA && !hasCombinedProteinEaa(plan.plan) {
        suggestions.append(SupplementSuggestion(
            id: "add-eaa-density",
            title: "High Intensity Detected",
            reason: "Your workout density (volume per minute) is high. EAAs or Carbs during your workout can help sustain energy and prevent catabolism.",
            action: .add(item: SupplementPlanItem(
                id: "gen-eaa-\(Date().timeIntervalSince1970)",
                supplement: "EAAs / BCAAs",
                dosage: "1 serving",
                time: "Intra-workout",
                notes: "Prevents muscle breakdown during fasted or intense training.",
                trainingDayOnly: true
            )),
            identifier: "ADD:EAAs / BCAAs"
        ))
    }

    // Suggestion 8: ZMA for High Frequency
    let hasZMA = plan.plan.contains { $0.supplement.lowercased().contains("zma") }
    if isHighFrequency && !hasZMA {
        suggestions.append(SupplementSuggestion(
            id: "add-zma-frequency",
            title: "Optimize Recovery",
            reason: "You frequently train multiple days in a row. ZMA (Zinc & Magnesium) before bed can improve sleep quality and recovery.",
            action: .add(item: SupplementPlanItem(
                id: "gen-zma-\(Date().timeIntervalSince1970)",
                supplement: "ZMA",
                dosage: "1 serving",
                time: "Before Bed",
                notes: "Take on an empty stomach before bed for better sleep and hormone support."
            )),
            identifier: "ADD:ZMA"
        ))
    }

    // Suggestion 9: BCAAs for Early Morning
    if isEarlyMorningUser && !hasEAA && !hasCombinedProteinEaa(plan.plan) {
        suggestions.append(SupplementSuggestion(
            id: "add-bcaa-morning",
            title: "Early Morning Training",
            reason: "Since you train early, likely fasted, taking BCAAs or EAAs can help prevent muscle breakdown during your session.",
            action: .add(item: SupplementPlanItem(
                id: "gen-bcaa-morning-\(Date().timeIntervalSince1970)",
                supplement: "EAAs / BCAAs",
                dosage: "1 serving",
                time: "Pre-workout",
                notes: "Prevents muscle breakdown during fasted or intense training.",
                trainingDayOnly: true
            )),
            identifier: "ADD:EAAs / BCAAs:morning"
        ))
    }

    // Suggestion 10: Reduce Protein
    if avgWeeklyVolume < 5000 || volumeDropRatio < 0.6 {
        if let firstProtein = proteinItems.first {
            let currentDosage = Int(firstProtein.dosage.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) ?? 0
            if currentDosage > 20 {
                let newDosage = max(20, Int(round(Double(currentDosage) * 0.75 / 5) * 5))
                if newDosage < currentDosage {
                    suggestions.append(SupplementSuggestion(
                        id: "reduce-protein-volume-drop",
                        title: "Reduce Protein Intake",
                        reason: "Your recent training volume has decreased significantly. You may not need as much supplemental protein to maintain muscle mass.",
                        action: .update(itemId: firstProtein.id, updates: SupplementPlanUpdates(dosage: "~\(newDosage)g")),
                        identifier: "UPDATE:\(firstProtein.supplement):dosage:reduce"
                    ))
                }
            }
        }
    }

    // Suggestion 11: Remove Pre-workout on Break/Injury
    if isSignificantVolumeDrop && volumeDropRatio < 0.5 {
        let preWorkoutItems = plan.plan.filter { item in
            let name = item.supplement.lowercased()
            return name.contains("caffeine") || name.contains("citrulline") || name.contains("pre-workout")
        }
        for item in preWorkoutItems {
            suggestions.append(SupplementSuggestion(
                id: "remove-preworkout-\(item.id)",
                title: "Remove Pre-Workout",
                reason: "We detected a large drop in your training volume or frequency. You might want to save your pre-workout/stimulants for when you return to high-intensity sessions.",
                action: .remove(itemId: item.id),
                identifier: "REMOVE:\(item.supplement):break"
            ))
        }
    }

    // Suggestion 12: Remove Beta-Alanine (Low Frequency)
    let betaAlanineItem = plan.plan.first { $0.supplement.lowercased().contains("beta") }
    let avgWeeklySessions = Double(recentHistory.count) / 4.0
    if let betaAlanineItem = betaAlanineItem, avgWeeklySessions < 2 {
        suggestions.append(SupplementSuggestion(
            id: "remove-beta-alanine-freq",
            title: "Remove Beta-Alanine",
            reason: "You are training less than twice a week recently. Beta-Alanine requires daily saturation to be effective, so it may not be worth taking right now.",
            action: .remove(itemId: betaAlanineItem.id),
            identifier: "REMOVE:Beta-Alanine:frequency"
        ))
    }

    // Suggestion 13: Stimulant Tolerance Break
    if !takenSupplements.isEmpty {
        if let toleranceSuggestion = checkStimulantTolerance(takenSupplements: takenSupplements, allSupplements: plan.plan) {
            suggestions.append(toleranceSuggestion)
        }
    }

    return suggestions
}

private func hasCombinedProteinEaa(_ plan: [SupplementPlanItem]) -> Bool {
    return plan.contains { item in
        let name = item.supplement.lowercased()
        return name.contains("protein") && (name.contains("eaa") || name.contains("bcaa"))
    }
}

private func checkStimulantTolerance(takenSupplements: [String: [String]], allSupplements: [SupplementPlanItem]) -> SupplementSuggestion? {
    let now = Date()
    let oneDayMS: TimeInterval = 24 * 3600 * 1000
    
    // Identify stimulant supplements
    let stimulantIds = Set(allSupplements.filter { item in
        let name = item.supplement.lowercased()
        return name.contains("caffeine") || name.contains("pre-workout") || name.contains("pre-entreno")
    }.map { $0.id })
    
    if stimulantIds.isEmpty { return nil }
    
    // Check usage history for the last 8 weeks
    var consistentWeeks = 0
    
    for i in 0..<8 {
        var takenThisWeek = false
        for j in 0..<7 {
            let dateToCheck = now.addingTimeInterval(-Double((i * 7 + j)) * oneDayMS)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateStr = formatter.string(from: dateToCheck)
            let takenOnDay = takenSupplements[dateStr] ?? []
            
            if takenOnDay.contains(where: { stimulantIds.contains($0) }) {
                takenThisWeek = true
                break
            }
        }
        if takenThisWeek { consistentWeeks += 1 }
    }
    
    if consistentWeeks >= 8 {
        if let itemToRemove = allSupplements.first(where: { stimulantIds.contains($0.id) }) {
            return SupplementSuggestion(
                id: "stimulant-tolerance-break",
                title: "Time for a Stimulant Break?",
                reason: "You've been using high-stimulant supplements for 8+ weeks. A 1-week break can help reset your tolerance and keep them effective.",
                action: .remove(itemId: itemToRemove.id),
                identifier: "REMOVE:\(itemToRemove.supplement):tolerance"
            )
        }
    }
    
    return nil
}