import SwiftUI

// MARK: - Bodyweight Input Sheet (P2: Connect bodyweight to exercises)
/// A sheet for entering bodyweight for bodyweight exercises.
/// Used to calculate offset: bodyweight + extra weight or bodyweight - assist weight.

struct BodyweightInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exerciseName: String
    let isAssisted: Bool
    let onSave: (Double) -> Void
    
    @State private var bodyweightText: String = ""
    @FocusState private var isFocused: Bool
    
    var bodyweight: Double? {
        Double(bodyweightText.replacingOccurrences(of: ",", with: "."))
    }
    
    init(
        exerciseName: String,
        isAssisted: Bool = false,
        onSave: @escaping (Double) -> Void
    ) {
        self.exerciseName = exerciseName
        self.isAssisted = isAssisted
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter bodyweight (kg)", text: $bodyweightText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .font(.title2.monospacedDigit())
                } header: {
                    Text("Bodyweight")
                } footer: {
                    if isAssisted {
                        Text("Assisted: Total = Bodyweight - Assist Weight")
                    } else {
                        Text("Extra: Total = Bodyweight + Extra Weight")
                    }
                }
                
                if let weight = bodyweight, weight > 0 {
                    Section("Preview") {
                        HStack {
                            Text("Your Bodyweight")
                            Spacer()
                            Text("\(formatWeight(weight)) kg")
                                .monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("Bodyweight — \(exerciseName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let weight = bodyweight, weight > 0 {
                            onSave(weight)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(bodyweight == nil || bodyweight! <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func formatWeight(_ w: Double) -> String {
        w == floor(w) ? "\(Int(w))" : String(format: "%.1f", w)
    }
}

#Preview {
    BodyweightInputSheet(exerciseName: "Pull-ups", isAssisted: true, onSave: { _ in })
}