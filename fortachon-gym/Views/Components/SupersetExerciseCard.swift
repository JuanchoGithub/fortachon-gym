import SwiftUI
import FortachonCore

// MARK: - Superset Exercise Card

struct SupersetExerciseCard: View {
    let superset: SupersetM
    let exercises: [WorkoutExerciseM]
    let allExercises: [ExerciseM]
    @Binding var expandedIds: Set<String>
    let onToggleSet: (PerformedSetM, String, SetType) -> Void
    let onAddSet: (String) -> Void
    
    private var supersetColor: Color {
        SupersetColors.allColors[superset.color ?? SupersetColors.defaultColor] ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Superset header
            HStack {
                Circle()
                    .fill(supersetColor)
                    .frame(width: 10, height: 10)
                Text(superset.name)
                    .font(.headline)
                Spacer()
                Text("\(exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(supersetColor.opacity(0.1))
            
            // Exercise columns
            VStack(spacing: 0) {
                ForEach(Array(exercises.enumerated()), id: \.element.weId) { idx, ex in
                    exerciseColumn(ex, at: idx, isLast: idx == exercises.count - 1)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func exerciseColumn(_ ex: WorkoutExerciseM, at idx: Int, isLast: Bool) -> some View {
        let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
        let isExpanded = expandedIds.contains(ex.weId)
        
        VStack(spacing: 0) {
            // Exercise header
            Button {
                if isExpanded {
                    expandedIds.remove(ex.weId)
                } else {
                    expandedIds.insert(ex.weId)
                }
            } label: {
                HStack {
                    Text("\(idx + 1). \(exerciseDef?.name ?? ex.exerciseId)")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    let done = ex.sets.filter { $0.isComplete }.count
                    Text("\(done)/\(ex.sets.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .padding()
            }
            
            if isExpanded {
                // Sets
                ForEach(Array(ex.sets.enumerated()), id: \.offset) { i, set in
                    SetRow(
                        set: set,
                        i: i,
                        historicalWeight: set.setTypeStr != "warmup" ? nil : nil,
                        onToggle: { onToggleSet(set, ex.weId, SetType(rawValue: set.setTypeStr) ?? .normal) }
                    )
                }
                
                // Add set button
                Button {
                    onAddSet(ex.weId)
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            if !isLast {
                Divider()
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var expandedIds: Set<String> = []
        
        var body: some View {
            let superset = SupersetM(id: "ss-1", name: "Upper Body Superset", color: "blue")
            let ex1 = WorkoutExerciseM(id: "we-1", exerciseId: "ex-1")
            ex1.sets.append(PerformedSetM(id: "s1", reps: 10, weight: 60, type: "normal"))
            ex1.sets.append(PerformedSetM(id: "s2", reps: 10, weight: 60, type: "normal"))
            let ex2 = WorkoutExerciseM(id: "we-2", exerciseId: "ex-5")
            ex2.sets.append(PerformedSetM(id: "s3", reps: 10, weight: 50, type: "normal"))
            ex2.sets.append(PerformedSetM(id: "s4", reps: 10, weight: 50, type: "normal"))
            
            return SupersetExerciseCard(
                superset: superset,
                exercises: [ex1, ex2],
                allExercises: [],
                expandedIds: $expandedIds,
                onToggleSet: { _, _, _ in },
                onAddSet: { _ in }
            )
            .padding()
        }
    }
    return PreviewWrapper()
}