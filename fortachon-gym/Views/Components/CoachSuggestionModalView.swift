import SwiftUI
import FortachonCore

// MARK: - Coach Suggestion Result

struct CoachSuggestionResult: Identifiable {
    let id = UUID()
    let routine: Routine
    let focusLabel: String
    let description: String
    let isFallback: Bool
}

// MARK: - Validation Issue

struct ValidationIssue: Identifiable {
    let id = UUID()
    let exerciseName: String
    let issue: String
}

// MARK: - Coach Suggestion Modal

struct CoachSuggestionModalView: View {
    @Environment(\.dismiss) private var dismiss
    let suggestion: CoachSuggestionResult
    let onAccept: () -> Void
    let onAggressive: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Icon
                Image(systemName: suggestion.isFallback ? "brain" : "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 20)
                
                // Focus label
                Text(suggestion.focusLabel)
                    .font(.title2.bold())
                
                // Description
                Text(suggestion.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Routine preview
                if !suggestion.routine.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercises (\(suggestion.routine.exercises.count))")
                            .font(.headline)
                        
                        ForEach(suggestion.routine.exercises.prefix(8), id: \.exerciseId) { ex in
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text(ex.exerciseId)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text("\(ex.sets.count) sets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if suggestion.routine.exercises.count > 8 {
                            Text("... and \(suggestion.routine.exercises.count - 8) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        onAccept()
                        dismiss()
                    } label: {
                        Label("Accept Suggestion", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    
                    if onAggressive != nil {
                        Button {
                            onAggressive?()
                            dismiss()
                        } label: {
                            Label("Aggressive (Ignore Fatigue)", systemImage: "bolt.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Coach Suggestion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Validation Errors Modal

struct ValidationErrorsModalView: View {
    @Environment(\.dismiss) private var dismiss
    let issues: [ValidationIssue]
    let onContinueAnyway: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.yellow)
                    .padding(.top, 20)
                
                Text("Incomplete Sets")
                    .font(.title2.bold())
                
                Text("The following exercises have no completed sets. Are you sure you want to finish?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                List(issues) { issue in
                    HStack {
                        Image(systemName: "circle.dashed")
                            .foregroundStyle(.red)
                        Text(issue.exerciseName)
                            .font(.subheadline)
                        Spacer()
                        Text(issue.issue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .listStyle(.plain)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        onContinueAnyway()
                        dismiss()
                    } label: {
                        Text("Finish Anyway")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue Workout")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Validation")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Exercise Upgrade Badge

struct ExerciseUpgradeBadge: View {
    let upgradeName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(upgradeName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.orange.opacity(0.4), lineWidth: 1))
        }
    }
}