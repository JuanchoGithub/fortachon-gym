import SwiftUI
import FortachonCore

// MARK: - Delete Supplement Options Modal
// Matches web version's DeleteSupplementModal behavior

struct DeleteSupplementOptionsModal: View {
    @Environment(\.dismiss) private var dismiss
    
    let item: SupplementLogM
    
    let onSetTrainingOnly: () -> Void
    let onSetRestOnly: () -> Void
    let onRemoveCompletely: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("What would you like to do with \(item.name)?") {
                    // Option 1: Training days only
                    Button {
                        onSetTrainingOnly()
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bolt.circle.fill")
                                    .foregroundStyle(.cyan)
                                Text("Training Days Only")
                                    .foregroundStyle(.primary)
                            }
                            Text("Remove this supplement from training days but keep it for rest days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Option 2: Rest days only
                    Button {
                        onSetRestOnly()
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "figure.rest.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Rest Days Only")
                                    .foregroundStyle(.primary)
                            }
                            Text("Remove this supplement from rest days but keep it for training days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Option 3: Remove completely
                    Button(role: .destructive) {
                        onRemoveCompletely()
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "trash.circle.fill")
                                    .foregroundStyle(.red)
                                Text("Remove Completely")
                                    .foregroundStyle(.red)
                            }
                            Text("Delete this supplement from your plan entirely")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Remove Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DeleteSupplementOptionsModal(
        item: SupplementLogM(
            name: "Creatine Monohydrate",
            dosage: "5g",
            timing: "Post-workout"
        ),
        onSetTrainingOnly: { print("Set training only") },
        onSetRestOnly: { print("Set rest only") },
        onRemoveCompletely: { print("Remove completely") }
    )
}