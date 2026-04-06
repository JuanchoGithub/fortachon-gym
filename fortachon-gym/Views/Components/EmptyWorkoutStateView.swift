import SwiftUI
import FortachonCore

/// Empty state view shown when a workout has no exercises.
/// Provides coach suggestions, quick-start buttons, and manual add option.
struct EmptyWorkoutStateView: View {
    let onCoachSuggest: () -> Void
    let onAggressiveSuggest: () -> Void
    let onQuickStart: (String) -> Void
    let onHIITStart: () -> Void
    let onAddExercise: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .padding(.top, 20)
            
            Text("Ready to Train?")
                .font(.title2.bold())
            
            Text("Add exercises or let the coach suggest a workout for you")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Coach Suggest CTA
            Button {
                onCoachSuggest()
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Coach Suggest")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.purple)
            }
            
            // Aggressive CTA
            Button {
                onAggressiveSuggest()
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Aggressive Workout")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.orange)
            }
            
            // Quick start buttons
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(["Upper", "Lower", "Core"], id: \.self) { type in
                        Button {
                            onQuickStart(type)
                        } label: {
                            Text(type)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
                
                Button {
                    onHIITStart()
                } label: {
                    HStack {
                        Image(systemName: "timer")
                        Text("HIIT Quick Start")
                    }
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Plain Add Exercise button
            Button {
                onAddExercise()
            } label: {
                Label("Add Exercise Manually", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                .background(Color(.systemBackground))
        )
    }
}