import SwiftUI
import FortachonCore

// MARK: - Exercise Editor View

struct ExerciseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let existingExercise: ExerciseM?
    let onSave: (ExerciseM) -> Void
    
    @State private var name: String
    @State private var bodyPart: String
    @State private var category: String
    @State private var notes: String
    @State private var isTimed: Bool
    @State private var isUnilateral: Bool
    @State private var primaryMuscles: String
    @State private var secondaryMuscles: String
    @State private var showDeleteConfirmation = false
    
    // Available options
    let bodyParts = ["Chest", "Back", "Legs", "Glutes", "Shoulders", "Biceps", "Triceps", "Core", "Full Body", "Calves", "Forearms", "Mobility", "Cardio"]
    let categories = ["Barbell", "Dumbbell", "Machine", "Cable", "Bodyweight", "Assisted Bodyweight", "Kettlebell", "Plyometrics", "Reps Only", "Cardio", "Duration", "Smith Machine"]
    
    init(exercise: ExerciseM?, onSave: @escaping (ExerciseM) -> Void) {
        self.existingExercise = exercise
        self.onSave = onSave
        _name = State(initialValue: exercise?.name ?? "")
        _bodyPart = State(initialValue: exercise?.bodyPartStr ?? "Chest")
        _category = State(initialValue: exercise?.categoryStr ?? "Barbell")
        _notes = State(initialValue: exercise?.notes ?? "")
        _isTimed = State(initialValue: exercise?.isTimed ?? false)
        _isUnilateral = State(initialValue: exercise?.isUnilateral ?? false)
        _primaryMuscles = State(initialValue: exercise?.primaryMuscles.joined(separator: ", ") ?? "")
        _secondaryMuscles = State(initialValue: exercise?.secondaryMuscles.joined(separator: ", ") ?? "")
    }
    
    var isEditing: Bool {
        existingExercise != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Exercise name", text: $name)
                        .autocorrectionDisabled()
                    
                    Picker("Body Part", selection: $bodyPart) {
                        ForEach(bodyParts, id: \.self) { Text($0) }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                }
                
                Section("Options") {
                    Toggle("Timed Exercise", isOn: $isTimed)
                    Toggle("Unilateral (one side at a time)", isOn: $isUnilateral)
                }
                
                Section("Muscles") {
                    TextField("Primary muscles (comma separated)", text: $primaryMuscles)
                        .autocorrectionDisabled()
                    
                    TextField("Secondary muscles (comma separated)", text: $secondaryMuscles)
                        .autocorrectionDisabled()
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Exercise", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Exercise?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteExercise()
                }
            } message: {
                Text("This will permanently delete '\(name)'. This action cannot be undone.")
            }
        }
    }
    
    private func saveExercise() {
        let musclesList = { (text: String) -> [String] in
            text.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        
        let exercise = ExerciseM(
            id: existingExercise?.id ?? "custom-\(UUID().uuidString)",
            name: name.trimmingCharacters(in: .whitespaces),
            bodyPart: bodyPart,
            category: category,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            isTimed: isTimed,
            isUnilateral: isUnilateral,
            primaryMuscles: musclesList(primaryMuscles),
            secondaryMuscles: musclesList(secondaryMuscles)
        )
        
        onSave(exercise)
        dismiss()
    }
    
    private func deleteExercise() {
        guard let exercise = existingExercise else { return }
        modelContext.delete(exercise)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ExerciseEditorView(exercise: nil) { _ in }
}