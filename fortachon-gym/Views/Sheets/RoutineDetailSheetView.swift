import SwiftUI
import SwiftData
import FortachonCore

struct RoutineDetailSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let routine: RoutineM
    
    var body: some View {
        NavigationStack {
            List {
                Section("Routine Info") {
                    LabeledContent("Name", value: routine.name)
                    LabeledContent("Type", value: routine.routineTypeStr)
                    LabeledContent("Exercises", value: "\(routine.exercises.count)")
                }
                
                Section("Exercises") {
                    ForEach(routine.exercises) { ex in
                        HStack {
                            Text(ex.exerciseId)
                            Spacer()
                            Text("\(ex.sets.count) sets")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Button {
                        startWorkout()
                        dismiss()
                    } label: {
                        Label("Start Workout", systemImage: "play.fill")
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
    
    private func startWorkout() {
        let session = WorkoutSessionM(
            id: "ws-\(UUID().uuidString)",
            routineId: routine.rtId,
            routineName: routine.name,
            startTime: Date(),
            endTime: Date()
        )
        
        for ex in routine.exercises {
            let exM = WorkoutExerciseM(id: "ex-\(UUID().uuidString)", exerciseId: ex.exerciseId)
            session.exercises.append(exM)
        }
        
        modelContext.insert(session)
        try? modelContext.save()
    }
}