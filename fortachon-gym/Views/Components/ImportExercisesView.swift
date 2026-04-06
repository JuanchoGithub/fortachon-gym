import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Import Exercises View

struct ImportExercisesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingExercises: [ExerciseM]
    
    @State private var importText = ""
    @State private var previewExercises: [ExerciseM] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var importCount = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Import JSON") {
                    Text("Paste JSON array of exercises in the format below:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $importText)
                        .frame(minHeight: 200)
                        .font(.system(.body, design: .monospaced))
                    
                    Button("Preview Import") {
                        previewImport()
                    }
                    .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                if !previewExercises.isEmpty {
                    Section("Preview (\(previewExercises.count) exercises)") {
                        ForEach(previewExercises) { exercise in
                            exercisePreviewRow(exercise)
                        }
                    }
                    
                    Section {
                        Button("Import \(previewExercises.count) Exercises") {
                            performImport()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }
                
                Section("Expected JSON Format") {
                    Text("""
                    [
                      {
                        "id": "ex-999",
                        "name": "Exercise Name",
                        "bodyPartStr": "Chest",
                        "categoryStr": "Barbell",
                        "primaryMuscles": ["Pectorals"],
                        "secondaryMuscles": ["Triceps"],
                        "difficulty": "intermediate",
                        "instructions": "Step 1. Step 2. Step 3."
                      }
                    ]
                    """)
                    .font(.system(.caption, design: .monospaced))
                }
            }
            .navigationTitle("Import Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Import Successful", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Successfully imported \(importCount) new exercises.")
            }
        }
    }
    
    @ViewBuilder
    private func exercisePreviewRow(_ exercise: ExerciseM) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.subheadline)
                Text("\(exercise.bodyPartStr) • \(exercise.categoryStr)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let difficulty = exercise.difficultyStr {
                Text(difficultyEmoji(for: difficulty))
            }
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
    
    private func previewImport() {
        guard let data = importText.data(using: .utf8) else {
            errorMessage = "Invalid text encoding"
            showError = true
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([ImportExerciseData].self, from: data)
            let existingIds = Set(existingExercises.map { $0.id })
            
            var imported: [ExerciseM] = []
            for item in decoded {
                if !existingIds.contains(item.id) {
                    let muscleGroup = item.muscleGroup ?? item.bodyPartStr
                    let exercise = ExerciseM(
                        id: item.id,
                        name: item.name,
                        bodyPart: muscleGroup,
                        category: item.categoryStr,
                        notes: item.notes,
                        primaryMuscles: item.primaryMuscles ?? [],
                        secondaryMuscles: item.secondaryMuscles ?? [],
                        instructions: item.instructions ?? "",
                        exerciseNamesEN: item.exerciseNamesEN,
                        exerciseNamesES: item.exerciseNamesES,
                        difficulty: item.difficulty,
                        updatedAt: Date()
                    )
                    imported.append(exercise)
                }
            }
            
            previewExercises = imported
        } catch {
            errorMessage = "Failed to parse JSON: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func performImport() {
        for exercise in previewExercises {
            modelContext.insert(exercise)
        }
        
        do {
            try modelContext.save()
            importCount = previewExercises.count
            previewExercises = []
            importText = ""
            showSuccess = true
        } catch {
            errorMessage = "Failed to save exercises: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func difficultyEmoji(for difficulty: String) -> String {
        switch difficulty.lowercased() {
        case "beginner": return "🟢"
        case "intermediate": return "🟡"
        case "advanced": return "🔴"
        default: return "⚪"
        }
    }
}

// MARK: - Import Data Model

struct ImportExerciseData: Codable {
    let id: String
    let name: String
    let bodyPartStr: String
    let categoryStr: String
    let muscleGroup: String?
    let notes: String?
    let primaryMuscles: [String]?
    let secondaryMuscles: [String]?
    let difficulty: String?
    let instructions: String?
    let exerciseNamesEN: String?
    let exerciseNamesES: String?
}

// MARK: - Preview

#Preview {
    ImportExercisesView()
}