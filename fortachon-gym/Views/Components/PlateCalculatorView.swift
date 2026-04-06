import SwiftUI

// MARK: - Plate Calculator View

struct PlateCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let barWeight: Double
    let plateSizes: [Double]
    
    @State private var targetWeight: String = ""
    @State private var calculatedPlates: [(plate: Double, count: Int)] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Target weight input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Weight (kg)")
                        .font(.headline)
                    
                    HStack {
                        TextField("Enter weight", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .font(.title2.monospacedDigit())
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Calculate button
                Button {
                    calculatePlates()
                } label: {
                    Text("Calculate Plates")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(targetWeight.isEmpty)
                
                // Results
                if !calculatedPlates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Per Side:")
                            .font(.headline)
                        
                        ForEach(calculatedPlates, id: \.plate) { plate, count in
                            HStack {
                                Text("\(count)x")
                                    .font(.title3.bold())
                                    .foregroundStyle(.blue)
                                    .frame(width: 40, alignment: .leading)
                                
                                Text("\(Int(plate)) kg")
                                    .font(.title3)
                                
                                Spacer()
                                
                                // Visual plate representation
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 30 + CGFloat(plate) * 0.5, height: 30 + CGFloat(plate) * 0.5)
                                    .overlay(
                                        Text("\(Int(plate))")
                                            .font(.caption.bold())
                                    )
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Divider()
                        
                        // Total weight breakdown
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Breakdown:")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            
                            let totalPlatesWeight = calculatedPlates.reduce(0) { $0 + ($1.plate * Double($1.count) * 2) }
                            Text("Bar: \(Int(barWeight)) kg")
                            Text("Plates: \(Int(totalPlatesWeight)) kg")
                            Text("Total: \(Int(barWeight + totalPlatesWeight)) kg")
                                .font(.headline)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private func calculatePlates() {
        guard let target = Double(targetWeight) else { return }
        
        let weightPerSide = (target - barWeight) / 2.0
        guard weightPerSide > 0 else { return }
        
        var remaining = weightPerSide
        var plates: [(plate: Double, count: Int)] = []
        
        for plateSize in plateSizes.sorted(by: >) {
            let count = Int(remaining / plateSize)
            if count > 0 {
                plates.append((plate: plateSize, count: count))
                remaining -= Double(count) * plateSize
            }
        }
        
        // Round remaining to nearest 0.5
        if remaining > 0.1 {
            calculatedPlates = plates
        } else {
            calculatedPlates = plates
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview

#Preview {
    PlateCalculatorView(
        barWeight: 20,
        plateSizes: [25, 20, 15, 10, 5, 2.5, 1.25]
    )
}