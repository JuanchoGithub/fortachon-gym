import SwiftUI
import FortachonCore

// MARK: - Exercise Image View
// Shows a placeholder icon based on body part, with proper structure
// for future real image integration (downloadable GLBs/PNGs from CDN).

struct ExerciseImageView: View {
    let exerciseId: String
    let bodyPart: String
    let size: CGSize

    init(exerciseId: String, bodyPart: String, size: CGSize = CGSize(width: 120, height: 120)) {
        self.exerciseId = exerciseId
        self.bodyPart = bodyPart
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background gradient based on body part
            bodyPartGradient

            // SF Symbol icon based on body part
            Image(systemName: bodyPartSymbol)
                .font(.system(size: size.width * 0.4))
                .foregroundStyle(.white.opacity(0.9))

            // Exercise number badge
            if let number = exerciseNumber {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(number)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.6), in: Capsule())
                    }
                    .padding(4)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    // MARK: - Body Part Symbol Mapping
    private var bodyPartSymbol: String {
        switch bodyPart.lowercased() {
        case "chest":
            return "figure.arm.wave.circle"
        case "back":
            return "figure.core.training"
        case "shoulders":
            return "figure.arms.open"
        case "biceps", "forearms":
            return "hand.raised.fingers.spread"
        case "triceps":
            return "figure.mixed.cardio"
        case "legs", "glutes":
            return "figure.run"
        case "calves":
            return "figure.walk"
        case "core":
            return "figure.core.training"
        case "cardio", "full body":
            return "figure.highintensity.intervaltraining"
        case "mobility":
            return "figure.mind.and.body"
        default:
            return "dumbbell.fill"
        }
    }

    // MARK: - Body Part Color Mapping
    private var bodyPartColor: Color {
        switch bodyPart.lowercased() {
        case "chest":
            return .blue
        case "back":
            return .green
        case "shoulders":
            return .orange
        case "biceps":
            return .purple
        case "triceps":
            return .red
        case "forearms":
            return .indigo
        case "legs":
            return .cyan
        case "glutes":
            return .pink
        case "calves":
            return .teal
        case "core":
            return .yellow
        case "cardio":
            return .mint
        case "full body":
            return .blue
        case "mobility":
            return .green
        default:
            return .gray
        }
    }

    // MARK: - Gradient
    @ViewBuilder
    private var bodyPartGradient: some View {
        LinearGradient(
            colors: [
                bodyPartColor.opacity(0.8),
                bodyPartColor.opacity(0.6),
                bodyPartColor.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Exercise Number
    private var exerciseNumber: String? {
        // Extract number from exercise ID (e.g., "ex-1" -> "1")
        let components = exerciseId.components(separatedBy: "-")
        return components.count > 1 ? components[1] : nil
    }
}

// MARK: - Exercise Thumbnail (for exercise list)

struct ExerciseThumbnailView: View {
    let exercise: ExerciseM
    let showName: Bool
    let useLocalizedNames: Bool

    init(exercise: ExerciseM, showName: Bool = true, useLocalizedNames: Bool = false) {
        self.exercise = exercise
        self.showName = showName
        self.useLocalizedNames = useLocalizedNames
    }

    var body: some View {
        HStack(spacing: 12) {
            // Image placeholder
            ExerciseImageView(
                exerciseId: exercise.id,
                bodyPart: exercise.bodyPartStr,
                size: CGSize(width: 56, height: 56)
            )

            // Exercise info
            if showName {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.displayName(useSpanish: useLocalizedNames))
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(exercise.bodyPartStr)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(exercise.categoryStr)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }

            Spacer()

            // Difficulty badge
            if let difficulty = exercise.difficultyStr {
                DifficultyBadge(difficulty: difficulty)
            }
        }
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: String

    var body: some View {
        if let diff = ExerciseDifficulty(rawValue: difficulty) {
            Text(diff.emoji)
                .font(.caption)
        }
    }
}

// MARK: - Exercise Image Preview (for exercise detail)

struct ExerciseImageDetailView: View {
    let exercise: ExerciseM
    let useLocalizedNames: Bool

    init(exercise: ExerciseM, useLocalizedNames: Bool = false) {
        self.exercise = exercise
        self.useLocalizedNames = useLocalizedNames
    }

    var body: some View {
        VStack(spacing: 0) {
            // Large image
            ExerciseImageView(
                exerciseId: exercise.id,
                bodyPart: exercise.bodyPartStr,
                size: CGSize(width: UIScreen.main.bounds.width - 32, height: 200)
            )
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 12) {
                // Name
                Text(exercise.displayName(useSpanish: useLocalizedNames))
                    .font(.title2.bold())

                // Body part + category
                HStack(spacing: 12) {
                    Label(exercise.bodyPartStr, systemImage: "circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Label(exercise.categoryStr, systemImage: "circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let difficulty = exercise.difficultyStr,
                       let diff = ExerciseDifficulty(rawValue: difficulty) {
                        Label(diff.label, systemImage: diff.emoji)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Instructions
                if let instructions = exercise.instructionsAsSteps,
                   !instructions.isEmpty {
                    Divider().padding(.vertical, 8)

                    Text("How to Perform")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(instructions.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                // Step number
                                Circle()
                                    .fill(.blue.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        Text("\(index + 1)")
                                            .font(.caption.bold())
                                            .foregroundStyle(.blue)
                                    }

                                // Step text
                                Text(step)
                                    .font(.subheadline)
                                    .lineSpacing(2)
                            }
                        }
                    }
                }

                // Primary muscles
                if let primary = exercise.primaryMuscles, !primary.isEmpty {
                    Divider().padding(.vertical, 8)

                    Text("Primary Muscles")
                        .font(.headline)

                    FlowLayout(spacing: 8) {
                        ForEach(primary, id: \.self) { muscle in
                            MuscleTag(muscle: muscle)
                        }
                    }
                }

                // Secondary muscles
                if let secondary = exercise.secondaryMuscles, !secondary.isEmpty {
                    Divider().padding(.vertical, 8)

                    Text("Secondary Muscles")
                        .font(.headline)

                    FlowLayout(spacing: 8) {
                        ForEach(secondary, id: \.self) { muscle in
                            MuscleTag(muscle: muscle, isSecondary: true)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Muscle Tag

struct MuscleTag: View {
    let muscle: String
    var isSecondary: Bool = false

    var body: some View {
        Text(muscle.humanizedName)
            .font(.caption)
            .foregroundStyle(isSecondary ? .secondary : .blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (isSecondary ? Color(.systemFill) : Color.blue.opacity(0.15)),
                in: Capsule()
            )
    }
}

// MARK: - Muscle Name Humanization

extension String {
    var humanizedName: String {
        let names: [String: String] = [
            "pectorals": "Chest",
            "lats": "Lats",
            "triceps": "Triceps",
            "biceps": "Biceps",
            "quads": "Quadriceps",
            "hamstrings": "Hamstrings",
            "glutes": "Glutes",
            "frontDelts": "Front Delts",
            "sideDelts": "Side Delts",
            "rearDelts": "Rear Delts",
            "traps": "Traps",
            "abs": "Abs",
            "obliques": "Obliques",
            "forearms": "Forearms",
            "calves": "Calves",
            "lowerBack": "Lower Back",
            "transverseAbdominis": "Transverse Abdominis",
            "rotatorCuff": "Rotator Cuff",
            "hipFlexors": "Hip Flexors",
            "adductors": "Adductors",
            "abductors": "Abductors",
            "brachialis": "Brachialis",
            "wristFlexors": "Wrist Flexors",
            "wristExtensors": "Wrist Extensors",
            "serratusAnterior": "Serratus Anterior",
            "spinalErectors": "Spinal Erectors",
            "teresMajor": "Teres Major",
            "rhomboids": "Rhomboids",
            "cardiovascularSystem": "Cardiovascular System",
            "upperChest": "Upper Chest",
            "lowerChest": "Lower Chest",
            "gastrocnemius": "Gastrocnemius",
            "soleus": "Soleus"
        ]
        return names[self] ?? self
    }
}

// MARK: - Flow Layout (simple horizontal wrap)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: position, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private struct LayoutResult {
        let size: CGSize
        let positions: [CGPoint]
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity

        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let fitSize = subview.sizeThatFits(.unspecified)

            if currentX + fitSize.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += fitSize.width + spacing
            lineHeight = max(lineHeight, fitSize.height)
        }

        let totalHeight = currentY + lineHeight
        let size = CGSize(width: maxWidth, height: totalHeight)
        return LayoutResult(size: size, positions: positions)
    }
}

// MARK: - Helpers

extension ExerciseM {
    /// Parse instructions JSON string array into native Swift array
    var instructionsAsSteps: [String]? {
        guard !instructions.isEmpty else { return nil }
        if let data = instructions.data(using: .utf8),
           let steps = try? JSONDecoder().decode([String].self, from: data) {
            return steps
        }
        // Fallback: treat as single plain text
        return [instructions]
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(["Chest", "Back", "Shoulders", "Biceps", "Legs", "Core", "Cardio"], id: \.self) { bodyPart in
                ExerciseImageView(
                    exerciseId: "ex-1",
                    bodyPart: bodyPart,
                    size: CGSize(width: 100, height: 100)
                )
            }
        }
        .padding()
    }
}