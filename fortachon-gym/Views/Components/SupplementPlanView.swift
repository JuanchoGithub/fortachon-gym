import SwiftUI
import FortachonCore

struct SupplementPlanView: View {
    let items: [SupplementPlanItem]
    @State private var selectedIds: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Supplement Stack", systemImage: "pill.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            
            ForEach(items) { item in
                Button {
                    if selectedIds.contains(item.id) {
                        selectedIds.remove(item.id)
                    } else {
                        selectedIds.insert(item.id)
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedIds.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(.cyan)
                        Text(item.supplement)
                            .fontWeight(.medium)
                        Spacer()
                        Text(item.dosage)
                            .font(.caption.monospaced())
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                Button {
                    // Snooze all
                } label: {
                    Text("Snooze")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color(white: 0.2), in: RoundedRectangle(cornerRadius: 10))
                }
                .foregroundStyle(.white.opacity(0.7))
                
                Button {
                    // Log selected
                } label: {
                    Label("Log \(selectedIds.count)", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10))
                }
                .foregroundStyle(.cyan)
                .disabled(selectedIds.isEmpty)
            }
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.16, blue: 0.31),
                    Color(red: 0.01, green: 0.13, blue: 0.27)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            selectedIds = Set(items.map { $0.id })
        }
        .onChange(of: items) { _, _ in
            selectedIds = Set(items.map { $0.id })
        }
    }
}