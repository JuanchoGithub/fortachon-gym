import SwiftUI
import SwiftData
import FortachonCore

struct TabExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [ExerciseM]
    @State private var searchQuery = ""
    @State private var selectedBodyPart: String?
    @State private var selectedExercise: ExerciseM?
    
    var bodyParts: [String] {
        Array(Set(exercises.map { $0.bodyPartStr })).sorted()
    }
    
    var filteredExercises: [ExerciseM] {
        var result = exercises
        
        if let bodyPart = selectedBodyPart {
            result = result.filter { $0.bodyPartStr == bodyPart }
        }
        
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        return result.sorted(by: { $0.name < $1.name })
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search exercises...", text: $searchQuery)
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Body Part Filter
                if !bodyParts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(
                                title: "All",
                                selected: selectedBodyPart == nil
                            ) {
                                selectedBodyPart = nil
                            }
                            ForEach(bodyParts, id: \.self) { bodyPart in
                                FilterPill(
                                    title: bodyPart,
                                    selected: selectedBodyPart == bodyPart
                                ) {
                                    selectedBodyPart = bodyPart
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
                
                // Exercise List
                List(filteredExercises) { exercise in
                    ExerciseRowView(exercise: exercise)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedExercise = exercise
                        }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(selected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Exercise Row

struct ExerciseRowView: View {
    let exercise: ExerciseM
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text(exercise.bodyPartStr)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !exercise.primaryMuscles.isEmpty {
                MuscleTagView(muscle: exercise.primaryMuscles.first ?? "")
            }
        }
        .padding(.vertical, 4)
    }
}

struct MuscleTagView: View {
    let muscle: String
    
    var body: some View {
        Text(muscle)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.15), in: Capsule())
            .foregroundStyle(.blue)
    }
}

// MARK: - Exercise Detail

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: ExerciseM
    
    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    LabeledContent("Name", value: exercise.name)
                    LabeledContent("Body Part", value: exercise.bodyPartStr)
                    LabeledContent("Category", value: exercise.categoryStr)
                    if let notes = exercise.notes, !notes.isEmpty {
                        LabeledContent("Notes", value: notes)
                    }
                    LabeledContent("Timed", value: exercise.isTimed ? "Yes" : "No")
                    LabeledContent("Unilateral", value: exercise.isUnilateral ? "Yes" : "No")
                }
                
                if !exercise.primaryMuscles.isEmpty {
                    Section("Primary Muscles") {
                        ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                            Text(muscle)
                        }
                    }
                }
                
                if !exercise.secondaryMuscles.isEmpty {
                    Section("Secondary Muscles") {
                        ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                            Text(muscle)
                        }
                    }
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TabExercisesView()
}