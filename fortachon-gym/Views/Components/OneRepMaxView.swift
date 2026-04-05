import SwiftUI
import SwiftData
import FortachonCore

// MARK: - One Rep Max View (matching web's OneRepMaxDetailView)

struct OneRepMaxView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSessionM.startTime, order: .reverse) private var sessions: [WorkoutSessionM]
    @Query private var preferences: [UserPreferencesM]
    
    let exercise: ExerciseM
    
    @State private var oneRepMaxes: [String: OneRepMaxEntry] = [:]
    
    var prefs: UserPreferencesM? { preferences.first }
    
    var current1RM: Double {
        oneRepMaxes[exercise.id]?.weight ?? 0
    }
    
    var maxHistory: [OneRepMaxHistoryEntry] {
        let entry = oneRepMaxes[exercise.id]
        return entry?.history?.sorted(by: { $0.date > $1.date }) ?? []
    }
    
    // One rep max percentages table
    var percentageTable: [(percentage: Int, weight: Double)] {
        [100, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50].compactMap { pct in
            guard current1RM > 0 else { return nil }
            return (pct, current1RM * Double(pct) / 100.0)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Current 1RM Display
                Section("Current 1 Rep Max") {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.name)
                                .font(.headline)
                            if current1RM > 0 {
                                Text("\(Int(current1RM)) \(prefs?.weightUnitStr.uppercased() ?? "KG")")
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.blue)
                            } else {
                                Text("No data yet")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.yellow)
                            .opacity(current1RM > 0 ? 1 : 0)
                    }
                    .padding(.vertical, 8)
                }
                
                // Percentage Table
                if current1RM > 0 {
                    Section("Training Percentages") {
                        ForEach(percentageTable, id: \.percentage) { item in
                            HStack {
                                Text("\(item.percentage)%")
                                    .font(.subheadline)
                                    .frame(width: 50, alignment: .leading)
                                Text("\(Int(item.weight))")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                // Visual bar
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.3), .blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * Double(item.percentage) / 100.0)
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                    
                    Section {
                        Text("Use these percentages to plan your training loads.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // History
                if !maxHistory.isEmpty {
                    Section("History") {
                        ForEach(maxHistory.prefix(10), id: \.id) { entry in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(Int(entry.weight)) \(prefs?.weightUnitStr.uppercased() ?? "KG")")
                                        .font(.headline)
                                        .foregroundStyle(entry.type == "calculated" ? .secondary : .primary)
                                    Text(entry.type == "calculated" ? "Calculated" : "Tested")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Estimated 1RM from recent sessions
                Section("Recent Performances") {
                    ForEach(getRecentPerformances(), id: \.id) { perf in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(perf.reps) reps @ \(Int(perf.weight)) \(prefs?.weightUnitStr.uppercased() ?? "KG")")
                                    .font(.subheadline)
                                Text(perf.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Est. 1RM: \(Int(perf.estimated1RM))")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.blue)
                        }
                    }
                    if getRecentPerformances().isEmpty {
                        Text("Complete sets in your workouts to see estimated 1RM.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("1 Rep Max")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadOneRepMaxes()
            }
        }
    }
    
    // MARK: - Load Data
    
    private func loadOneRepMaxes() {
        // Build 1RM map from history
        // In a full implementation, this would come from a dedicated 1RM model
        // For now, we estimate from recent session data
        let history = sessions
        oneRepMaxes = calculate1RMFromHistory(history: history)
    }
    
    private func calculate1RMFromHistory(history: [WorkoutSessionM]) -> [String: OneRepMaxEntry] {
        var results: [String: [OneRepMaxHistoryEntry]] = [:]
        var maxMap: [String: OneRepMaxEntry] = [:]
        
        for session in history {
            for exercise in session.exercises {
                for set in exercise.sets where set.isComplete && set.reps > 0 && set.weight > 0 {
                    let estimated1RM = estimateOneRM(weight: set.weight, reps: set.reps)
                    let entry = OneRepMaxHistoryEntry(
                        id: set.setId,
                        date: set.completedAt ?? session.startTime,
                        weight: estimated1RM,
                        type: "calculated"
                    )
                    
                    if results[exercise.exerciseId] == nil {
                        results[exercise.exerciseId] = []
                    }
                    results[exercise.exerciseId]?.append(entry)
                    
                    // Update max
                    if maxMap[exercise.exerciseId] == nil || estimated1RM > maxMap[exercise.exerciseId]!.weight {
                        maxMap[exercise.exerciseId] = OneRepMaxEntry(
                            exerciseId: exercise.exerciseId,
                            weight: estimated1RM,
                            type: "calculated",
                            history: results[exercise.exerciseId]
                        )
                    }
                }
            }
        }
        
        return maxMap
    }
    
    private func getRecentPerformances() -> [SetPerformance] {
        var performances: [SetPerformance] = []
        
        for session in sessions.prefix(10) {
            for exercise in session.exercises where exercise.exerciseId == self.exercise.id {
                for set in exercise.sets where set.isComplete && set.reps > 0 && set.weight > 0 {
                    performances.append(SetPerformance(
                        id: set.setId,
                        date: set.completedAt ?? session.startTime,
                        reps: set.reps,
                        weight: set.weight,
                        estimated1RM: estimateOneRM(weight: set.weight, reps: set.reps)
                    ))
                }
            }
        }
        
        return Array(performances.sorted(by: { $0.date > $1.date }).prefix(20))
    }
    
    // Epley formula: 1RM = weight * (1 + reps/30)
    private func estimateOneRM(weight: Double, reps: Int) -> Double {
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }
}

// MARK: - Supporting Types

struct OneRepMaxEntry: Codable {
    let exerciseId: String
    var weight: Double
    var type: String // "calculated" or "tested"
    var history: [OneRepMaxHistoryEntry]?
    var updatedAt: Date
    var snoozedUntil: Date?
    
    init(exerciseId: String, weight: Double, type: String = "calculated", history: [OneRepMaxHistoryEntry]? = nil, updatedAt: Date = Date(), snoozedUntil: Date? = nil) {
        self.exerciseId = exerciseId
        self.weight = weight
        self.type = type
        self.history = history
        self.updatedAt = updatedAt
        self.snoozedUntil = snoozedUntil
    }
}

struct OneRepMaxHistoryEntry: Codable, Identifiable {
    let id: String
    let date: Date
    var weight: Double
    var type: String // "calculated" or "tested"
    var oldWeight: Double? // For undo support
}

struct SetPerformance: Identifiable {
    let id: String
    let date: Date
    let reps: Int
    let weight: Double
    let estimated1RM: Double
}

// MARK: - Preview

#Preview {
    OneRepMaxView(exercise: ExerciseM(
        id: "ex-2",
        name: "Squat",
        bodyPart: "Legs",
        category: "Barbell",
        primaryMuscles: ["Quads"]
    ))
}