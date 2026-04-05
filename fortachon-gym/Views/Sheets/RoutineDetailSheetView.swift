import SwiftUI
import SwiftData
import FortachonCore

struct RoutineDetailSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [ExerciseM]
    let routine: RoutineM
    
    @State private var isStartingWorkout = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Routine Info") {
                    LabeledContent("Name", value: routine.name)
                    LabeledContent("Type", value: formattedRoutineType)
                    LabeledContent("Exercises", value: "\(routine.exercises.count)")
                    if routine.routineTypeStr == "hiit" {
                        if let work = routine.hiitWork, let rest = routine.hiitRest {
                            LabeledContent("HIIT Work/Rest", value: "\(work)s / \(rest)s")
                        }
                    }
                }
                
                Section("Exercises") {
                    ForEach(Array(routine.exercises.enumerated()), id: \.element.weId) { index, ex in
                        ExerciseDetailRow(
                            index: index,
                            exerciseId: ex.exerciseId,
                            exercises: exercises
                        )
                    }
                }
                
                Section {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            startWorkout()
                        }
                    } label: {
                        Label("Start Workout", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle(routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    var formattedRoutineType: String {
        switch routine.routineTypeStr {
        case "strength": return "Strength"
        case "hiit": return "HIIT"
        case "cardio": return "Cardio"
        default: return routine.routineTypeStr.capitalized
        }
    }
    
    private func startWorkout() {
        // The workout will be started from TabTrainView via a callback
    }
}

// MARK: - Exercise Detail Row

struct ExerciseDetailRow: View {
    let index: Int
    let exerciseId: String
    let exercises: [ExerciseM]
    
    var exerciseName: String {
        exercises.first { $0.id == exerciseId }?.name ?? exerciseId
    }
    
    var body: some View {
        HStack {
            Text("\(index + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(exerciseName)
                .font(.subheadline)
        }
    }
}

#Preview {
    RoutineDetailSheetView(routine: RoutineM(
        id: "preview",
        name: "Push Day A",
        desc: "Sample routine",
        isTemplate: true,
        type: "strength"
    ))
}