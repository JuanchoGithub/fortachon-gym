import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Template Editor View

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [ExerciseM]
    
    let routine: RoutineM?
    @State private var viewModel: TemplateEditorViewModel
    @State private var showExercisePicker = false
    @State private var showSaveConfirmation = false
    @State private var showSupersetEditor = false
    
    init(routine: RoutineM? = nil) {
        self.routine = routine
        _viewModel = State(initialValue: TemplateEditorViewModel(
            modelContext: ModelContext(try! ModelContainer(for: ExerciseM.self)),
            allExercises: [],
            routine: routine
        ))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Template Info Section
                Section("Template Info") {
                    TextField("Template Name", text: $viewModel.templateName)
                        .font(.headline)
                    TextField("Description (optional)", text: $viewModel.templateDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Template type picker
                    Picker("Type", selection: $viewModel.templateType) {
                        Text("Strength").tag("strength")
                        Text("HIIT").tag("hiit")
                        Text("Mixed").tag("mixed")
                    }
                }
                
                // HIIT Configuration Section
                if viewModel.templateType == "hiit" {
                    Section("HIIT Configuration") {
                        Stepper("Work: \(viewModel.hiitWork)s", value: $viewModel.hiitWork, in: 10...120, step: 5)
                        Stepper("Rest: \(viewModel.hiitRest)s", value: $viewModel.hiitRest, in: 5...60, step: 5)
                        Stepper("Prep: \(viewModel.hiitPrep)s", value: $viewModel.hiitPrep, in: 5...30, step: 5)
                        Stepper("Rounds: \(viewModel.hiitRounds)", value: $viewModel.hiitRounds, in: 1...20)
                    }
                }
                
                // Superset Section
                if viewModel.templateType == "strength" || viewModel.templateType == "mixed" {
                    Section("Supersets") {
                        HStack {
                            Text("\(viewModel.supersets.count) supersets configured")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Manage") {
                                showSupersetEditor = true
                            }
                        }
                    }
                }
                
                // Exercises Section
                Section("Exercises (\(viewModel.exercises.count))") {
                    if viewModel.exercises.isEmpty {
                        ContentUnavailableView(
                            "No Exercises",
                            systemImage: "dumbbell",
                            description: Text("Add exercises to build your template.")
                        )
                    } else {
                        ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { idx, item in
                            exerciseRow(item, at: idx)
                        }
                        .onMove(perform: viewModel.moveExercise)
                        .onDelete(perform: viewModel.removeExercise)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(routine == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let saved: RoutineM?
                        if viewModel.templateType == "hiit" {
                            saved = viewModel.createHIITTemplate()
                            if let s = saved { modelContext.insert(s) }
                        } else {
                            saved = viewModel.saveTemplate()
                            if let s = saved { modelContext.insert(s) }
                        }
                        if saved != nil {
                            try? modelContext.save()
                            showSaveConfirmation = true
                        }
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .alert("Validation Errors", isPresented: $viewModel.showValidationErrors) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.validationErrors.joined(separator: "\n"))
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet { exerciseId in
                    viewModel.addExercise(exerciseId)
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showSupersetEditor) {
                SupersetEditorView(
                    templateExercises: $viewModel.exercises,
                    routineSupersets: $viewModel.supersets
                )
                .presentationDetents([.medium, .large])
            }
            .onChange(of: viewModel.templateName) { _, _ in viewModel.hasChanges = true }
            .onChange(of: viewModel.exercises) { _, _ in viewModel.hasChanges = true }
            .onChange(of: viewModel.templateType) { _, _ in viewModel.hasChanges = true }
        }
        .onAppear {
            // Update viewModel with actual exercises from query
            viewModel = TemplateEditorViewModel(
                modelContext: modelContext,
                allExercises: allExercises,
                routine: routine
            )
        }
    }
    
    // MARK: - Exercise Row
    
    @ViewBuilder
    private func exerciseRow(_ item: TemplateExerciseItem, at idx: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(idx + 1). \(item.exerciseName)")
                        .font(.headline)
                    Text(item.bodyPart)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            // Set configuration
            HStack(spacing: 12) {
                // Sets
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sets")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Stepper("", value: Binding(get: { item.defaultSets }, set: { item.defaultSets = $0 }), in: 1...10)
                        .labelsHidden()
                    Text("\(item.defaultSets)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                
                // Reps
                if !item.isTimed {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Stepper("", value: Binding(get: { item.defaultReps }, set: { item.defaultReps = $0 }), in: 1...50)
                            .labelsHidden()
                        Text("\(item.defaultReps)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
                
                // Rest time
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Stepper("", value: Binding(get: { item.restTime }, set: { item.restTime = $0 }), in: 10...300, step: 5)
                        .labelsHidden()
                    Text("\(item.restTime)s")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Exercise Picker Sheet

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [ExerciseM]
    @State private var search = ""
    let onSelect: (String) -> Void
    
    var filtered: [ExerciseM] {
        if search.isEmpty {
            return exercises.sorted { $0.name < $1.name }
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
            .sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search exercises...", text: $search)
                    if !search.isEmpty {
                        Button {
                            search = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding()
                
                List(filtered) { ex in
                    Button {
                        onSelect(ex.id)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ex.name)
                                .font(.headline)
                            Text(ex.bodyPartStr)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TemplateEditorView(routine: nil)
}