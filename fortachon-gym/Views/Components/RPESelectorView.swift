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
        case 9: "Max Effort"
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

// MARK: - Inline RPE Display (for set row)

struct InlineRPEDisplay: View {
    let rpe: Int?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Group {
                if let rpe = rpe {
                    Text("\(rpe)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.white)
                        .background(rpeColor(for: rpe), in: Circle())
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background(.secondary.opacity(0.1), in: Circle())
                }
            }
        }
    }
    
    private func rpeColor(for rpe: Int) -> Color {
        switch rpe {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        case 9: return .red
        case 10: return Color(red: 0.8, green: 0, blue: 0)
        default: return .secondary
        }
    }
}

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
                        InlineRPEDisplay(rpe: nil, onTap: {})
                        InlineRPEDisplay(rpe: 5, onTap: {})
                        InlineRPEDisplay(rpe: 8, onTap: {})
                        InlineRPEDisplay(rpe: 10, onTap: {})
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