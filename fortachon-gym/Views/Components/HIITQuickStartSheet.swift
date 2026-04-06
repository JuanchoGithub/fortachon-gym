import SwiftUI

/// Sheet for configuring and starting a quick HIIT session
struct HIITQuickStartSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var work: Int
    @Binding var rest: Int
    @Binding var prep: Int
    @Binding var rounds: Int
    
    let onStart: () -> Void
    
    private var totalDuration: Int {
        prep + (work + rest) * rounds - rest
    }
    
    private var formattedDuration: String {
        let mins = totalDuration / 60
        let secs = totalDuration % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("HIIT Configuration") {
                    HStack {
                        Text("Work Interval")
                        Spacer()
                        Stepper("\(work)s", value: $work, in: 10...120, step: 5)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Rest Interval")
                        Spacer()
                        Stepper("\(rest)s", value: $rest, in: 5...60, step: 5)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Preparation Time")
                        Spacer()
                        Stepper("\(prep)s", value: $prep, in: 5...30, step: 5)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Rounds")
                        Spacer()
                        Stepper("\(rounds)", value: $rounds, in: 1...30)
                            .labelsHidden()
                    }
                }
                
                Section("Summary") {
                    HStack {
                        Text("Estimated Duration")
                        Spacer()
                        Text(formattedDuration)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                    
                    HStack {
                        Text("Work Time")
                        Spacer()
                        Text("\(work * rounds / 60)m \(work * rounds % 60)s")
                            .font(.subheadline.monospacedDigit())
                    }
                    
                    HStack {
                        Text("Rest Time")
                        Spacer()
                        Text("\(rest * (rounds - 1) / 60)m \(rest * (rounds - 1) % 60)s")
                            .font(.subheadline.monospacedDigit())
                    }
                }
                
                Section {
                    Button(action: {
                        onStart()
                        dismiss()
                    }) {
                        Label("Start HIIT", systemImage: "bolt.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Quick HIIT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    HIITQuickStartSheet(
        work: .constant(30),
        rest: .constant(15),
        prep: .constant(10),
        rounds: .constant(8),
        onStart: {}
    )
}
