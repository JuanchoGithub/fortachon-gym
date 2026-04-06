import SwiftUI
import SwiftData
import FortachonCore

// MARK: - One Rep Max Hub View

/// Consolidated 1RM dashboard showing all exercises with current max values.
/// Sortable by muscle group or by max weight.
struct OneRepMaxHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [ExerciseM]
    @Query(sort: \WorkoutSessionM.startTime, order: .reverse) private var sessions: [WorkoutSessionM]
    @Query private var preferences: [UserPreferencesM]
    
    @State private var sortBy: SortOption = .exercise
    @State private var selectedExercise: ExerciseM?
    @State private var strengthProfile: [StrengthProfileEntry] = []
    
    enum SortOption: String, CaseIterable {
        case exercise = "Exercise"
        case weight = "Max Weight"
        case muscle = "Muscle Group"
    }
    
    private var prefs: UserPreferencesM? { preferences.first }
    private var unit: String { prefs?.weightUnitStr.uppercased() ?? "KG" }
    
    // Big compound lifts to track
    private var trackedExercises: [ExerciseM] {
        let trackedIds = ["ex-1", "ex-2", "ex-3", "ex-4", "ex-5", "ex-6", "ex-10", "ex-16", "ex-17"]
        return exercises.filter { trackedIds.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sort picker
                Picker("Sort by", selection: $sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 1RM list
                List {
                    ForEach(sortedExercises, id: \.id) { exercise in
                        let best1RM = WorkoutProgressionUtils.getBest1RM(
                            exerciseId: exercise.id,
                            modelContext: modelContext
                        )
                        
                        OneRMHubRow(
                            exercise: exercise,
                            best1RM: best1RM,
                            unit: unit
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedExercise = exercise
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("1RM Hub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                OneRepMaxView(exercise: exercise)
            }
        }
    }
    
    // MARK: - Sorted Exercises
    
    private var sortedExercises: [ExerciseM] {
        switch sortBy {
        case .exercise:
            return trackedExercises.sorted { $0.name < $1.name }
        case .weight:
            return trackedExercises.sorted {
                WorkoutProgressionUtils.getBest1RM(exerciseId: $0.id, modelContext: modelContext) >
                WorkoutProgressionUtils.getBest1RM(exerciseId: $1.id, modelContext: modelContext)
            }
        case .muscle:
            return trackedExercises.sorted {
                $0.bodyPartStr < $1.bodyPartStr
            }
        }
    }
}

// MARK: - 1RM Hub Row

struct OneRMHubRow: View {
    let exercise: ExerciseM
    let best1RM: Double
    let unit: String
    
    var body: some View {
        HStack {
            // Exercise icon
            Image(systemName: exerciseIcon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)
                Text(exercise.bodyPartStr)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 1RM value
            VStack(alignment: .trailing, spacing: 2) {
                if best1RM > 0 {
                    Text(String(format: "%.1f", best1RM))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(.green)
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private var exerciseIcon: String {
        if exercise.bodyPartStr.contains("Chest") || exercise.bodyPartStr.contains("Chest") {
            return "dumbbell.fill"
        } else if exercise.bodyPartStr.contains("Leg") {
            return "figure.run"
        } else if exercise.bodyPartStr.contains("Back") {
            return "figure.walk"
        } else if exercise.bodyPartStr.contains("Shoulder") {
            return "dumbbell.fill"
        } else {
            return "dumbbell.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    OneRepMaxHubView()
}