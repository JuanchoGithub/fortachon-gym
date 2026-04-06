import SwiftUI
import FortachonCore

/// Shows exercise details including instructions, muscles, and history.
/// Matches web's exercise details modal mid-workout.
struct ExerciseDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: ExerciseM
    let historicalData: (avgWeight: Double, avgReps: Int)?
    let useLocalizedNames: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Exercise Name
                    Text(exercise.displayName(useSpanish: useLocalizedNames))
                        .font(.title.bold())
                    
                    // Body Part & Category
                    HStack(spacing: 12) {
                        Label(exercise.bodyPartStr, systemImage: "figure.strengthtraining.traditional")
                            .foregroundStyle(.secondary)
                        if !exercise.categoryStr.isEmpty {
                            Label(exercise.categoryStr, systemImage: "dumbbell.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                    
                    // Primary Muscles
                    if !exercise.primaryMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Muscles").font(.headline)
                            MuscleTagsView(muscles: exercise.primaryMuscles, style: .primary)
                        }
                    }
                    
                    // Secondary Muscles
                    if !exercise.secondaryMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Secondary Muscles").font(.headline)
                            MuscleTagsView(muscles: exercise.secondaryMuscles, style: .secondary)
                        }
                    }
                    
                    // Instructions
                    if let steps = exercise.instructionsAsSteps, !steps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instructions").font(.headline)
                            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(idx + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(.blue))
                                    Text(step)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Historical Performance
                    if let hist = historicalData {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Session Average").font(.headline)
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("\(String(format: "%.1f", hist.avgWeight)) kg")
                                        .font(.title2.bold())
                                        .foregroundStyle(.blue)
                                    Text("Weight").font(.caption).foregroundStyle(.secondary)
                                }
                                VStack(alignment: .leading) {
                                    Text("\(hist.avgReps)")
                                        .font(.title2.bold())
                                        .foregroundStyle(.green)
                                    Text("Reps").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Muscle Tags View

struct MuscleTagsView: View {
    let muscles: [String]
    let style: MuscleStyle
    
    enum MuscleStyle {
        case primary, secondary
    }
    
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(muscles, id: \.self) { muscle in
                Text(muscle)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(
                            style == .primary ? Color.blue.opacity(0.2) : Color.green.opacity(0.2)
                        )
                    )
                    .foregroundStyle(style == .primary ? .blue : .green)
            }
        }
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: position, anchor: .topLeading, proposal: proposal)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}