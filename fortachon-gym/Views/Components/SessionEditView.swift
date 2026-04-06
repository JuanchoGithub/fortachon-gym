import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Session Edit View

struct SessionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [ExerciseM]
    
    @Bindable var session: WorkoutSessionM
    let onSave: (() -> Void)?
    
    @State private var sessionName: String
    @State private var sessionNotes: String
    @State private var editingSetKey: SetEditKey?
    @State private var showDeleteConfirmation = false
    @State private var setToDelete: (exerciseIndex: Int, setIndex: Int)?
    
    struct SetEditKey: Identifiable {
        let id = UUID()
        let exerciseIndex: Int
        let setIndex: Int
    }
    
    init(session: WorkoutSessionM, onSave: (() -> Void)? = nil) {
        self.session = session
        self.onSave = onSave
        _sessionName = State(initialValue: session.routineName)
        _sessionNotes = State(initialValue: session.notes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Session metadata
                Section("Session Info") {
                    TextField("Session Name", text: $sessionName)
                    TextEditor(text: $sessionNotes)
                        .frame(minHeight: 60)
                    Text("Started: \(session.startTime.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Ended: \(session.endTime.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("PRs: \(session.prCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Exercises
                Section("Exercises (\(session.exercises.count))") {
                    ForEach(Array(session.exercises.enumerated()), id: \.element.weId) { exIdx, exercise in
                        exerciseEditSection(exercise, at: exIdx)
                    }
                }
                
                // Danger zone
                Section {
                    Button("Delete Session", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } footer: {
                    Text("This action cannot be undone")
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        session.routineName = sessionName
                        session.notes = sessionNotes
                        try? modelContext.save()
                        onSave?()
                        dismiss()
                    }
                    .bold()
                }
            }
            .sheet(item: $editingSetKey) { key in
                if key.exerciseIndex < session.exercises.count,
                   key.setIndex < session.exercises[key.exerciseIndex].sets.count {
                    let exercise = session.exercises[key.exerciseIndex]
                    let set = exercise.sets[key.setIndex]
                    let exerciseDef = allExercises.first { $0.id == exercise.exerciseId }
                    let exerciseName = exerciseDef?.displayName(useSpanish: false) ?? exercise.exerciseId
                    
                    SetEditSheet(
                        exerciseName: exerciseName,
                        setNumber: key.setIndex + 1,
                        set: set
                    ) { updatedSet in
                        // Set is a reference type, changes are in place
                        try? modelContext.save()
                        editingSetKey = nil
                    } onCancel: {
                        editingSetKey = nil
                    }
                }
            }
            .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    modelContext.delete(session)
                    try? modelContext.save()
                    onSave?()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete this workout session and all its data.")
            }
        }
    }
    
    @ViewBuilder
    private func exerciseEditSection(_ exercise: WorkoutExerciseM, at exIdx: Int) -> some View {
        let exerciseDef = allExercises.first { $0.id == exercise.exerciseId }
        let exerciseName = exerciseDef?.displayName(useSpanish: false) ?? exercise.exerciseId
        
        DisclosureGroup {
            ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIdx, set in
                SetEditRow(
                    exerciseName: exerciseName,
                    setNumber: setIdx + 1,
                    set: set,
                    onTap: {
                        editingSetKey = SetEditKey(exerciseIndex: exIdx, setIndex: setIdx)
                    },
                    onDelete: {
                        exercise.sets.remove(at: setIdx)
                    }
                )
            }
            
            Button {
                let lastSet = exercise.sets.last
                let newSet = PerformedSetM(
                    id: "set-\(UUID())",
                    reps: lastSet?.reps ?? 0,
                    weight: lastSet?.weight ?? 0,
                    type: lastSet?.setTypeStr ?? "normal"
                )
                exercise.sets.append(newSet)
            } label: {
                Label("Add Set", systemImage: "plus.circle")
                    .font(.subheadline)
            }
        } label: {
            HStack {
                Text("\(exIdx + 1). \(exerciseName)")
                    .font(.headline)
                Spacer()
                Text("\(exercise.sets.filter { $0.isComplete }.count)/\(exercise.sets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Set Edit Row (inline in form)

struct SetEditRow: View {
    let exerciseName: String
    let setNumber: Int
    let set: PerformedSetM
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var setTypeIcon: (String, Color) {
        switch set.setTypeStr {
        case "warmup": return ("sunrise", .orange)
        case "drop": return ("arrow.down.circle", .red)
        case "failure": return ("bolt.fill", .yellow)
        case "timed": return ("clock.fill", .purple)
        default: return ("dumbbell", .blue)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: setTypeIcon.0)
                .foregroundStyle(setTypeIcon.1)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text("Set \(setNumber)")
                    .font(.subheadline)
                HStack(spacing: 8) {
                    Text("\(set.weight, specifier: "%.0f") kg")
                    Text("×")
                    Text("\(set.reps) reps")
                    if set.setTypeStr == "timed", let time = set.setTime {
                        Text("• \(formatTime(time))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if set.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            
            // Swipe to delete
            Button {
                onDelete()
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Set Edit Sheet

struct SetEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let exerciseName: String
    let setNumber: Int
    @Bindable var set: PerformedSetM
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Set Details") {
                    Stepper("Weight: \(set.weight, specifier: "%.1f") kg", value: $set.weight, in: 0...500, step: 1.25)
                    Stepper("Reps: \(set.reps)", value: $set.reps, in: 0...100, step: 1)
                    
                    if set.setTypeStr == "timed" {
                        Stepper("Time: \(formatTime(set.setTime ?? 0))", value: Binding(
                            get: { set.setTime ?? 0 },
                            set: { set.setTime = $0 }
                        ), in: 0...3600, step: 5)
                    }
                    
                    Toggle("Completed", isOn: $set.isComplete)
                    
                    Picker("Set Type", selection: $set.setTypeStr) {
                        Text("Normal").tag("normal")
                        Text("Warmup").tag("warmup")
                        Text("Drop").tag("drop")
                        Text("Failure").tag("failure")
                        Text("Timed").tag("timed")
                    }
                    
                    if let rpe = set.rpe {
                        Stepper("RPE: \(rpe)", value: Binding(
                            get: { rpe },
                            set: { set.rpe = $0 }
                        ), in: 1...10, step: 1)
                    } else {
                        Button("Add RPE") {
                            set.rpe = 7
                        }
                    }
                }
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if set.isComplete && set.completedAt == nil {
                            set.completedAt = Date()
                        }
                        onSave()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var isPresented = false
        
        var body: some View {
            Button("Show Session Edit") {
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                let session = WorkoutSessionM(
                    id: "ws-preview",
                    routineId: "rt-1",
                    routineName: "Upper Body",
                    startTime: Date().addingTimeInterval(-3600),
                    endTime: Date()
                )
                let ex1 = WorkoutExerciseM(id: "we-1", exerciseId: "ex-1")
                ex1.sets.append(PerformedSetM(id: "s1", reps: 10, weight: 60, type: "normal", isComplete: true))
                ex1.sets.append(PerformedSetM(id: "s2", reps: 10, weight: 60, type: "normal", isComplete: true))
                session.exercises.append(ex1)
                
                let ex2 = WorkoutExerciseM(id: "we-2", exerciseId: "ex-5")
                ex2.sets.append(PerformedSetM(id: "s3", reps: 8, weight: 50, type: "normal", isComplete: true))
                session.exercises.append(ex2)
                
                return SessionEditView(session: session) {
                    print("Session saved")
                }
            }
        }
    }
    return PreviewWrapper()
}