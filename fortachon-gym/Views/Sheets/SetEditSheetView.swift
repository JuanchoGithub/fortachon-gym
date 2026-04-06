import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Set Edit Sheet View

/// A sheet for editing individual set details during a workout.
struct SetEditSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferencesM]
    
    let exerciseName: String
    let setNumber: Int
    @Binding var reps: Int
    @Binding var weight: Double
    @Binding var rpe: Int
    @Binding var setType: SetType
    @Binding var isComplete: Bool
    
    let historicalReps: Int?
    let historicalWeight: Double?
    
    private var prefs: UserPreferencesM? { preferences.first }
    private var unit: String { prefs?.weightUnitStr.uppercased() ?? "KG" }
    
    // State for editing
    @State private var editedReps: String
    @State private var editedWeight: String
    @State private var editedRpe: Int
    @State private var editedType: SetType
    @State private var editedComplete: Bool
    
    init(
        exerciseName: String,
        setNumber: Int,
        reps: Binding<Int>,
        weight: Binding<Double>,
        rpe: Binding<Int>,
        setType: Binding<SetType>,
        isComplete: Binding<Bool>,
        historicalReps: Int? = nil,
        historicalWeight: Double? = nil
    ) {
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self._reps = reps
        self._weight = weight
        self._rpe = rpe
        self._setType = setType
        self._isComplete = isComplete
        self.historicalReps = historicalReps
        self.historicalWeight = historicalWeight
        self._editedReps = State(initialValue: "\(reps.wrappedValue)")
        self._editedWeight = State(initialValue: String(format: "%.1f", weight.wrappedValue))
        self._editedRpe = State(initialValue: rpe.wrappedValue)
        self._editedType = State(initialValue: setType.wrappedValue)
        self._editedComplete = State(initialValue: isComplete.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Header
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exerciseName)
                                .font(.headline)
                            Text("Set \(setNumber)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Complete toggle
                        Button(action: { editedComplete.toggle() }) {
                            Image(systemName: editedComplete ? "checkmark.circle.fill" : "circle")
                                .font(.title)
                                .foregroundStyle(editedComplete ? .green : .gray)
                        }
                    }
                }
                
                // Weight & Reps
                Section("Performance") {
                    // Weight
                    HStack {
                        Text("Weight (\(unit))")
                        Spacer()
                        TextField("0", text: $editedWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Stepper("", value: Binding(
                            get: { Double(editedWeight) ?? 0 },
                            set: { editedWeight = String(format: "%.1f", $0) }
                        ), step: 2.5)
                    }
                    
                    // Reps
                    HStack {
                        Text("Reps")
                        Spacer()
                        TextField("0", text: $editedReps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Stepper("", value: Binding(
                            get: { Int(editedReps) ?? 0 },
                            set: { editedReps = "\($0)" }
                        ), step: 1)
                    }
                    
                    // Historical comparison
                    if let histWeight = historicalWeight, let histReps = historicalReps, (Double(editedWeight) ?? 0) > 0 {
                        Divider()
                        HStack(spacing: 16) {
                            historicalIndicator(
                                current: Double(editedWeight) ?? 0,
                                historical: histWeight,
                                label: "Weight"
                            )
                            historicalIndicatorReps(
                                current: Int(editedReps) ?? 0,
                                historical: histReps,
                                label: "Reps"
                            )
                        }
                    }
                }
                
                // Set Type
                Section("Set Type") {
                    Picker("Type", selection: $editedType) {
                        ForEach(SetType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                // RPE
                Section("Effort") {
                    RPEPicker(rpe: $editedRpe)
                }
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Historical Indicator
    
    @ViewBuilder
    private func historicalIndicator(current: Double, historical: Double, label: String) -> some View {
        let diff = current - historical
        let pct = historical > 0 ? (diff / historical) * 100 : 0
        
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Image(systemName: diff > 0 ? "arrow.up.circle.fill" : diff < 0 ? "arrow.down.circle.fill" : "equal.circle.fill")
                .foregroundStyle(diff > 0 ? .green : diff < 0 ? .red : .gray)
            
            Text(String(format: "%.0f%%", abs(pct)))
                .font(.caption.bold())
                .foregroundStyle(diff > 0 ? .green : diff < 0 ? .red : .gray)
        }
    }
    
    @ViewBuilder
    private func historicalIndicatorReps(current: Int, historical: Int, label: String) -> some View {
        let diff = current - historical
        let pct = historical > 0 ? Double(diff) / Double(historical) * 100 : 0
        
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Image(systemName: diff > 0 ? "arrow.up.circle.fill" : diff < 0 ? "arrow.down.circle.fill" : "equal.circle.fill")
                .foregroundStyle(diff > 0 ? .green : diff < 0 ? .red : .gray)
            
            Text(diff > 0 ? "+\(diff)" : "\(diff)")
                .font(.caption.bold())
                .foregroundStyle(diff > 0 ? .green : diff < 0 ? .red : .gray)
        }
    }
    
    // MARK: - Save
    
    private func saveChanges() {
        reps = Int(editedReps) ?? 0
        weight = Double(editedWeight) ?? 0
        rpe = editedRpe
        setType = editedType
        isComplete = editedComplete
        dismiss()
    }
}

// MARK: - RPE Picker

struct RPEPicker: View {
    @Binding var rpe: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Visual scale
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { i in
                    Button(action: { rpe = i }) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(rpe >= i ? rpeColor(i) : Color.gray.opacity(0.2))
                            .frame(height: 24)
                    }
                    .buttonStyle(.plain)
                    .opacity(rpe > 0 && rpe < i ? 0.3 : 1)
                }
            }
            
            HStack {
                Text(rpe > 0 ? "RPE: \(rpe)/10 - \(rpeDescription(rpe))" : "No RPE recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
    
    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        case 9...10: return .red
        default: return .gray
        }
    }
    
    private func rpeDescription(_ rpe: Int) -> String {
        switch rpe {
        case 1...2: return "Very Light"
        case 3...4: return "Light"
        case 5...6: return "Moderate"
        case 7: return "Hard"
        case 8: return "Very Hard"
        case 9: return "Almost Max"
        case 10: return "Maximum"
        default: return ""
        }
    }
}

// MARK: - SetType Extension

extension SetType {
    static var allCases: [SetType] {
        [.warmup, .normal, .drop, .failure, .timed]
    }
    
    var displayName: String {
        switch self {
        case .warmup: return "Warm-up"
        case .normal: return "Working"
        case .drop: return "Drop Set"
        case .failure: return "To Failure"
        case .timed: return "Timed"
        }
    }
}

// MARK: - Preview

#Preview {
    SetEditSheetView(
        exerciseName: "Bench Press",
        setNumber: 2,
        reps: .constant(8),
        weight: .constant(80),
        rpe: .constant(7),
        setType: .constant(.normal),
        isComplete: .constant(true),
        historicalReps: 6,
        historicalWeight: 75
    )
}