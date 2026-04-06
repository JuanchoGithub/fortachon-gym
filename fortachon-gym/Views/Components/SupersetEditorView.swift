import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Template Superset Editor View

/// Superset management UI for the TemplateEditorView.
/// This is different from SupersetManagerView which manages supersets during active workouts.
struct SupersetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [ExerciseM]
    @Query private var preferences: [UserPreferencesM]
    
    @Binding var templateExercises: [TemplateExerciseItem]
    @Binding var routineSupersets: [SupersetM]
    
    @State private var selectedIndices: Set<Int> = []
    @State private var editingSuperset: SupersetM?
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showCreateAlert = false
    @State private var newSupersetName = ""
    @State private var showColorPicker = false
    @State private var colorPickerSuperset: SupersetM?
    @State private var ungroupSuperset: SupersetM?
    
    private var prefs: UserPreferencesM? { preferences.first }
    private var useLocalizedNames: Bool { prefs?.localizedExerciseNames ?? false }
    
    // Group exercises by superset
    private var supersetsWithExercises: [(superset: SupersetM, exercises: [(index: Int, item: TemplateExerciseItem)])] {
        routineSupersets.map { ss in
            let exercises = templateExercises.enumerated()
                .filter { _, item in item.supersetId == ss.ssId }
                .map { (index: $0, item: $1) }
            return (superset: ss, exercises: exercises)
        }
    }
    
    private var ungroupedExercises: [(index: Int, item: TemplateExerciseItem)] {
        templateExercises.enumerated()
            .filter { _, item in item.supersetId == nil }
            .map { (index: $0, item: $1) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Existing supersets
                if !routineSupersets.isEmpty {
                    Section("Supersets") {
                        ForEach(supersetsWithExercises, id: \.superset.ssId) { group in
                            supersetGroup(group)
                        }
                    }
                }
                
                // Ungrouped exercises
                if !ungroupedExercises.isEmpty {
                    Section("Exercises (tap to select for superset)") {
                        ForEach(ungroupedExercises, id: \.index) { idx, item in
                            HStack {
                                Image(systemName: selectedIndices.contains(idx) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIndices.contains(idx) ? .blue : .secondary)
                                
                                Text("\(item.exerciseName)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text(item.bodyPart)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedIndices.contains(idx) {
                                    selectedIndices.remove(idx)
                                } else {
                                    selectedIndices.insert(idx)
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
                    if selectedIndices.count >= 2 {
                        Button("Create") { showCreateAlert = true }
                    } else if editingSuperset != nil {
                        Button("Ungroup") { ungroupSuperset = editingSuperset }
                    }
                }
            }
            .alert("Create Superset", isPresented: $showCreateAlert) {
                TextField("Name", text: $newSupersetName)
                Button("Cancel", role: .cancel) {}
                Button("Create") { createSuperset() }
            }
            .alert("Rename Superset", isPresented: $showRenameAlert) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    if let ss = editingSuperset {
                        ss.name = renameText
                        editingSuperset = nil
                    }
                }
            }
            .alert("Ungroup Superset", isPresented: Binding(
                get: { ungroupSuperset != nil },
                set: { if !$0 { ungroupSuperset = nil } }
            )) {
                Button("Cancel", role: .cancel) { ungroupSuperset = nil }
                Button("Ungroup", role: .destructive) {
                    if let ss = ungroupSuperset {
                        ungroupSuperset(ss)
                        ungroupSuperset = nil
                    }
                }
            } message: {
                Text("This will remove the superset grouping.")
            }
            .sheet(item: $colorPickerSuperset) { ss in
                SupersetColorPickerSheet(superset: ss) { selectedColor in
                    ss.color = selectedColor
                    colorPickerSuperset = nil
                    dismiss()
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Superset Group Row
    
    @ViewBuilder
    private func supersetGroup(_ group: (superset: SupersetM, exercises: [(index: Int, item: TemplateExerciseItem)])) -> some View {
        let color = SupersetColors.allColors[group.superset.color ?? SupersetColors.defaultColor] ?? .blue
        
        DisclosureGroup {
            ForEach(group.exercises, id: \.index) { idx, item in
                HStack {
                    Text("\(item.exerciseName)")
                        .font(.subheadline)
                    Spacer()
                    Text("\(item.defaultSets) × \(item.isTimed ? "timed" : "\(item.defaultReps)")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedIndices.contains(idx) {
                        selectedIndices.remove(idx)
                    } else {
                        selectedIndices.insert(idx)
                    }
                }
            }
        } label: {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(group.superset.name)
                    .font(.headline)
                Spacer()
                Menu {
                    Button {
                        renameText = group.superset.name
                        editingSuperset = group.superset
                        showRenameAlert = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button {
                        colorPickerSuperset = group.superset
                        showColorPicker = true
                    } label: {
                        Label("Change Color", systemImage: "paintpalette")
                    }
                    Button(role: .destructive) {
                        ungroupSuperset = group.superset
                    } label: {
                        Label("Ungroup", systemImage: "rectangle.split.3x1")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if editingSuperset?.ssId == group.superset.ssId {
                editingSuperset = nil
            } else {
                editingSuperset = group.superset
            }
        }
        .background(
            editingSuperset?.ssId == group.superset.ssId ? Color.blue.opacity(0.1) : Color.clear
        )
    }
    
    // MARK: - Actions
    
    private func createSuperset() {
        let supersetId = "ss-\(UUID().uuidString)"
        let superset = SupersetM(
            id: supersetId,
            name: newSupersetName.isEmpty ? "Superset \(routineSupersets.count + 1)" : newSupersetName,
            color: SupersetColors.defaultColor
        )
        
        for idx in selectedIndices.sorted() {
            templateExercises[idx].supersetId = supersetId
        }
        
        routineSupersets.append(superset)
        selectedIndices.removeAll()
        newSupersetName = ""
    }
    
    private func ungroupSuperset(_ superset: SupersetM) {
        for idx in templateExercises.indices {
            if templateExercises[idx].supersetId == superset.ssId {
                templateExercises[idx].supersetId = nil
            }
        }
        routineSupersets.removeAll { $0.ssId == superset.ssId }
        editingSuperset = nil
    }
}

// MARK: - Color Picker Sheet

struct SupersetColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let superset: SupersetM
    let onSelect: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Choose Color")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(Array(SupersetColors.allColors.keys.sorted()), id: \.self) { colorKey in
                        let color = SupersetColors.allColors[colorKey] ?? .blue
                        let isSelected = superset.color == colorKey
                        
                        Button {
                            onSelect(colorKey)
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
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
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


// MARK: - Preview

#Preview {
    struct SupersetEditorPreview: View {
        @State var exercises: [TemplateExerciseItem] = []
        @State var supersets: [SupersetM] = []
        
        var body: some View {
            SupersetEditorView(
                templateExercises: $exercises,
                routineSupersets: $supersets
            )
        }
    }
    return SupersetEditorPreview()
}