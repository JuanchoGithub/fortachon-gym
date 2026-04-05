import SwiftUI
import FortachonCore

// MARK: - Exercise Instruction Card

struct ExerciseInstructionCard: View {
    let exercise: ExerciseM
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Label(exercise.bodyPartStr, systemImage: "figure")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !exercise.categoryStr.isEmpty {
                                Label(exercise.categoryStr, systemImage: "dumbbell")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            
            if isExpanded {
                Divider()
                    .padding(.horizontal)
                
                // Instructions
                if let notes = exercise.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.subheadline.bold())
                        
                        ForEach(Array(notes.components(separatedBy: "\n").enumerated()), id: \.offset) { idx, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("\(idx + 1)")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    )
                                Text(instruction)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                
                // Tips
                if let notes = exercise.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Notes")
                                .font(.subheadline.bold())
                        }
                        
                        ForEach(Array(notes.components(separatedBy: "\n").enumerated()), id: \.offset) { _, tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(tip)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                
                // Muscle targets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Muscles")
                        .font(.subheadline.bold())
                    
                    HStack(spacing: 8) {
                        ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.2), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    ExerciseInstructionCard(
        exercise: ExerciseM(
            id: "ex-1",
            name: "Bench Press",
            bodyPart: "Chest",
            category: "Barbell",
            primaryMuscles: ["Pectorals", "Triceps", "Front Delts"]
        )
    )
    .padding()
}
