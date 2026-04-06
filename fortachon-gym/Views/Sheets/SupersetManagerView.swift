import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Superset Colors

enum SupersetColors {
    static let defaultColor = "blue"
    static let allColors: [String: Color] = [
        "blue": .blue,
        "purple": .purple,
        "green": .green,
        "orange": .orange,
        "red": .red,
        "pink": .pink,
        "cyan": .cyan,
        "yellow": .yellow
    ]
}

// MARK: - Superset Manager View

struct SupersetManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [ExerciseM]
    @Query private var preferences: [UserPreferencesM]
    
    @Binding var sessionExercises: [WorkoutExerciseM]
    @Binding var sessionSupersets: [SupersetM]
    
    var prefs: UserPreferencesM? { preferences.first }
    var useLocalizedNames: Bool { prefs?.localizedExerciseNames ?? false }
    
    /// Get localized exercise name
    private func exerciseName(for exerciseDef: ExerciseM?) -> String {
        guard let ex = exerciseDef else { return "Unknown" }
        return ex.displayName(useSpanish: useLocalizedNames)
    }
    
    @State private var selectedExerciseIndices: Set<Int> = []
    @State private var showCreateSuperset = false
    @State private var editingSuperset: SupersetM?
    @State private var showRenameSuperset: SupersetM?
    @State private var showColorPicker: SupersetM?
    @State private var supersetToUngroup: SupersetM?
    
    // Create superset state
    @State private var newSupersetName = ""
    @State private var newSupersetColor = SupersetColors.defaultColor
    
    // Rename state
    @State private var renameText = ""
    
    // Color picker state
    @State private var selectedColor: String = SupersetColors.defaultColor
    
    var exercisesBySuperset: [String: [WorkoutExerciseM]] {
        var groups: [String: [WorkoutExerciseM]] = [:]
        for ex in sessionExercises {
            if let ssId = ex.supersetId {
                if groups[ssId] == nil { groups[ssId] = [] }
                groups[ssId]?.append(ex)
            }
        }
        return groups
    }
    
    var ungroupedExercises: [WorkoutExerciseM] {
        sessionExercises.filter { $0.supersetId == nil }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Existing supersets
                if !sessionSupersets.isEmpty {
                    Section("Supersets") {
                        ForEach(sessionSupersets) { superset in
                            supersetRow(superset)
                        }
                    }
                }
                
                // Ungrouped exercises
                if !ungroupedExercises.isEmpty {
                    Section("Exercises") {
                        ForEach(Array(ungroupedExercises.enumerated()), id: \.element.weId) { idx, ex in
                            let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                                Text(exerciseName(for: exerciseDef))
                                    .font(.headline)
                                Spacer()
                                if selectedExerciseIndices.contains(sessionExercises.firstIndex(where: { $0.weId == ex.weId }) ?? -1) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let globalIdx = sessionExercises.firstIndex(where: { $0.weId == ex.weId }) {
                                    if selectedExerciseIndices.contains(globalIdx) {
                                        selectedExerciseIndices.remove(globalIdx)
                                    } else {
                                        selectedExerciseIndices.insert(globalIdx)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Supersets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedExerciseIndices.count >= 2 {
                        Button("Create Superset") { showCreateSuperset = true }
                    }
                }
            }
            .alert("Create Superset", isPresented: $showCreateSuperset) {
                TextField("Superset Name", text: $newSupersetName)
                Button("Cancel", role: .cancel) {}
                Button("Create") { createSuperset() }
            } message: {
                Text("Select \(selectedExerciseIndices.count) exercises to group into a superset.")
            }
            .alert("Rename Superset", isPresented: .constant(showRenameSuperset != nil)) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) { showRenameSuperset = nil }
                Button("Save") {
                    if let superset = showRenameSuperset {
                        superset.name = renameText
                        showRenameSuperset = nil
                    }
                }
            }
            .sheet(item: $showColorPicker) { superset in
                SupersetColorPicker(superset: superset, selectedColor: $selectedColor)
                    .presentationDetents([.medium])
            }
            .alert("Ungroup Superset", isPresented: .constant(supersetToUngroup != nil)) {
                Button("Cancel", role: .cancel) { supersetToUngroup = nil }
                Button("Ungroup", role: .destructive) {
                    if let superset = supersetToUngroup {
                        ungroupSuperset(superset)
                        supersetToUngroup = nil
                    }
                }
            } message: {
                Text("This will remove the superset grouping from all exercises.")
            }
        }
    }
    
    // MARK: - Superset Row
    
    @ViewBuilder
    private func supersetRow(_ superset: SupersetM) -> some View {
        let exercises = exercisesBySuperset[superset.ssId] ?? []
        let color = SupersetColors.allColors[superset.color ?? SupersetColors.defaultColor] ?? .blue
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(superset.name)
                    .font(.headline)
                Spacer()
                Menu {
                    Button {
                        renameText = superset.name
                        showRenameSuperset = superset
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button {
                        selectedColor = superset.color ?? SupersetColors.defaultColor
                        showColorPicker = superset
                    } label: {
                        Label("Change Color", systemImage: "paintpalette")
                    }
                    Button(role: .destructive) {
                        supersetToUngroup = superset
                    } label: {
                        Label("Ungroup", systemImage: "rectangle.split.3x1")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
            
            ForEach(exercises, id: \.weId) { ex in
                let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
                Label(exerciseName(for: exerciseDef), systemImage: "dumbbell")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func createSuperset() {
        let supersetId = "ss-\(UUID().uuidString)"
        let superset = SupersetM(
            id: supersetId,
            name: newSupersetName.isEmpty ? "Superset \(sessionSupersets.count + 1)" : newSupersetName,
            color: newSupersetColor
        )
        
        for idx in selectedExerciseIndices.sorted() {
            sessionExercises[idx].supersetId = supersetId
        }
        
        sessionSupersets.append(superset)
        selectedExerciseIndices.removeAll()
        newSupersetName = ""
        newSupersetColor = SupersetColors.defaultColor
    }
    
    private func ungroupSuperset(_ superset: SupersetM) {
        for idx in sessionExercises.indices {
            if sessionExercises[idx].supersetId == superset.ssId {
                sessionExercises[idx].supersetId = nil
            }
        }
        sessionSupersets.removeAll { $0.ssId == superset.ssId }
    }
}

// MARK: - Superset Color Picker

struct SupersetColorPicker: View {
    @Environment(\.dismiss) private var dismiss
    let superset: SupersetM
    @Binding var selectedColor: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Choose Color")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(Array(SupersetColors.allColors.keys.sorted()), id: \.self) { colorKey in
                        Button {
                            selectedColor = colorKey
                            superset.color = colorKey
                            dismiss()
                        } label: {
                            Circle()
                                .fill(SupersetColors.allColors[colorKey] ?? .blue)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == colorKey ? Color.primary : Color.clear, lineWidth: 3)
                                )
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var exercises: [WorkoutExerciseM] = []
        @State var supersets: [SupersetM] = []
        
        var body: some View {
            SupersetManagerView(
                sessionExercises: $exercises,
                sessionSupersets: $supersets
            )
        }
    }
    return PreviewWrapper()
}