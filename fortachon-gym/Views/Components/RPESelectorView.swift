import SwiftUI
import FortachonCore

// MARK: - RPE Selector View

/// A color-coded RPE (Rate of Perceived Exertion) selector supporting 1-10 scale
struct RPESelectorView: View {
    @Binding var selectedRPE: Int?
    let onDismiss: (() -> Void)?
    
    private let rpeScale = Array(1...10)
    
    private func rpeColor(for rpe: Int) -> Color {
        switch rpe {
        case 1...3: return .green           // Light
        case 4...6: return .yellow          // Moderate
        case 7...8: return .orange          // Heavy
        case 9: return .red                 // Very Heavy
        case 10: return Color(red: 0.8, green: 0, blue: 0)  // Max Effort
        default: return .secondary
        }
    }
    
    private func rpeLabel(for rpe: Int) -> String {
        switch rpe {
        case 1: return "Very Light"
        case 2: return "Light"
        case 3: return "Moderate"
        case 4: return "Somewhat Hard"
        case 5: return "Hard"
        case 6: return "Heavy"
        case 7: return "Very Heavy"
        case 8: return "Very Very Heavy"
        case 9: return "Max Effort"
        case 10: return "Absolute Max"
        default: return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Title
            HStack {
                Text("RPE")
                    .font(.headline)
                Text("(Rate of Perceived Exertion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let onDismiss = onDismiss {
                    Button("Done") { onDismiss() }
                        .font(.caption)
                }
            }
            
            // Selected RPE display
            if let selected = selectedRPE {
                VStack(spacing: 4) {
                    Text("\(selected)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(rpeColor(for: selected))
                    Text(rpeLabel(for: selected))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                Text("Select RPE")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            
            // RPE buttons grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(rpeScale, id: \.self) { rpe in
                    RPEButton(
                        rpe: rpe,
                        isSelected: selectedRPE == rpe,
                        color: rpeColor(for: rpe),
                        label: rpeLabel(for: rpe)
                    ) {
                        if selectedRPE == rpe {
                            selectedRPE = nil  // Deselect if already selected
                        } else {
                            selectedRPE = rpe
                        }
                    }
                }
            }
            
            // Scale reference
            HStack {
                Text("Light")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Spacer()
                Text("Heavy")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Spacer()
                Text("Max")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - RPE Button

struct RPEButton: View {
    let rpe: Int
    let isSelected: Bool
    let color: Color
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(rpe)")
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 40, height: 40)
                    .background(
                        isSelected ? color : color.opacity(0.15),
                        in: Circle()
                    )
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(isSelected ? color : .secondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Inline RPE Editor (for set row) — P1 #4: Replace sheet with inline stepper

/// Inline RPE editor: tap to cycle RPE 0→1→2→...→10→0, long press to reset.
/// This replaces the full sheet (was 3+ taps) with a single-tap interaction.
struct InlineRPEEditor: View {
    let rpe: Int?
    let onChange: (Int?) -> Void
    
    @State private var showingQuickPicker = false
    
    private var displayRPE: Int { rpe ?? 0 }
    
    private func rpeColor(for rpe: Int) -> Color {
        switch rpe {
        case 0: return .secondary
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        case 9: return .red
        case 10: return Color(red: 0.8, green: 0, blue: 0)
        default: return .secondary
        }
    }
    
    private var rpeLabel: String {
        guard displayRPE > 0 else { return "–" }
        return "\(displayRPE)"
    }
    
    private var tooltip: String {
        guard displayRPE > 0 else { return "Tap to set RPE" }
        return "Tap to change (\(displayRPE))"
    }
    
    var body: some View {
        Button {
            showingQuickPicker = true
        } label: {
            Text(rpeLabel)
                .font(.caption.bold())
                .frame(width: 28, height: 28)
                .foregroundStyle(displayRPE > 0 ? .white : .secondary)
                .background(
                    displayRPE > 0 ? rpeColor(for: displayRPE) : Color.secondary.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .contentTransition(.numericText())
                .accessibilityLabel("RPE: \(displayRPE). \(tooltip)")
        }
        .buttonStyle(.plain)
        .confirmationDialog("Select RPE", isPresented: $showingQuickPicker, titleVisibility: .hidden) {
            Button("Clear", role: .cancel) { onChange(nil) }
            ForEach(1...10, id: \.self) { rpe in
                Button("\(rpe) — \(rpeDescription(rpe))") { onChange(rpe) }
            }
        }
    }
    
    private func rpeDescription(_ rpe: Int) -> String {
        switch rpe {
        case 1...3: return "Light"
        case 4...6: return "Moderate"
        case 7...8: return "Heavy"
        case 9: return "Max"
        case 10: return "Absolute Max"
        default: return ""
        }
    }
}

// Backward compat alias
typealias InlineRPEDisplay = InlineRPEEditor

// MARK: - RPE Entry Sheet

/// Full sheet for selecting RPE during a workout
struct RPEEntrySheet: View {
    @Binding var rpe: Int?
    let setInfo: String  // e.g., "Bench Press - Set 3"
    let onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(setInfo)
                    .font(.title3.bold())
                    .padding(.top)
                
                RPESelectorView(selectedRPE: $rpe, onDismiss: nil)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Set RPE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDone() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var rpe: Int? = 7
        
        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    // Full selector
                    RPESelectorView(selectedRPE: $rpe, onDismiss: nil)
                    
                    // Inline displays
                    HStack(spacing: 12) {
                        Text("Inline:")
                        InlineRPEEditor(rpe: nil, onChange: { _ in })
                        InlineRPEEditor(rpe: 5, onChange: { _ in })
                        InlineRPEEditor(rpe: 8, onChange: { _ in })
                        InlineRPEEditor(rpe: 10, onChange: { _ in })
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
    }
    return PreviewWrapper()
}