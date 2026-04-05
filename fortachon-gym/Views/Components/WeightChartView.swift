import SwiftUI
import SwiftData
import FortachonCore

struct WeightChartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferencesM]
    
    let weightHistory: [WeightEntry]
    @Binding var currentWeight: Double
    @State private var newWeight: String = ""
    
    var prefs: UserPreferencesM? { preferences.first }
    var unit: String { prefs?.weightUnitStr.uppercased() ?? "KG" }
    
    var weightChange: Double? {
        guard weightHistory.count >= 2 else { return nil }
        let sorted = weightHistory.sorted(by: { $0.date < $1.date })
        guard let first = sorted.first?.weight, let last = sorted.last?.weight else { return nil }
        return last - first
    }
    
    var averageWeight: Double? {
        guard !weightHistory.isEmpty else { return nil }
        return weightHistory.reduce(0) { $0 + $1.weight } / Double(weightHistory.count)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Current Weight") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f", currentWeight))
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundStyle(.blue)
                            if let change = weightChange {
                                Text("\(change >= 0 ? "+" : "")\(String(format: "%.1f", change)) \(unit)")
                                    .font(.caption)
                                    .foregroundStyle(change >= 0 ? .red : .green)
                            }
                        }
                        Spacer()
                        Image(systemName: "scalemass.fill").font(.system(size: 40)).foregroundStyle(.blue)
                    }
                }
                
                Section("Log Weight") {
                    HStack {
                        Text("Weight"); Spacer()
                        TextField("0", text: $newWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    Button { logWeight() } label: {
                        Label("Log Weight", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
                    }
                    .disabled(newWeight.isEmpty || Double(newWeight) == nil)
                    .buttonStyle(.borderedProminent)
                }
                
                Section("Statistics") {
                    if let avg = averageWeight { LabeledContent("Average", value: "\(String(format: "%.1f", avg)) \(unit)") }
                    if let min = weightHistory.min(by: { $0.weight < $1.weight }) { LabeledContent("Lowest", value: "\(String(format: "%.1f", min.weight)) \(unit)") }
                    if let max = weightHistory.max(by: { $0.weight < $1.weight }) { LabeledContent("Highest", value: "\(String(format: "%.1f", max.weight)) \(unit)") }
                    LabeledContent("Entries", value: "\(weightHistory.count)")
                }
                
                if !weightHistory.isEmpty {
                    Section("Weight History") {
                        WeightHistoryGraph(entries: weightHistory.sorted(by: { $0.date < $1.date }))
                            .frame(height: 200)
                    }
                }
                
                Section("Log") {
                    let sortedArray = weightHistory.sorted(by: { $0.date > $1.date }).prefix(30)
                    ForEach(Array(sortedArray.enumerated()), id: \.element.id) { i, entry in
                        HistoryRow(entry: entry, unit: unit, index: i, all: Array(sortedArray))
                    }
                }
            }
            .navigationTitle("Weight Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
    
    private func logWeight() {
        guard let w = Double(newWeight), w > 0 else { return }
        currentWeight = w
        _ = WeightEntryM(weight: w, date: Date())
        // Note: To persist, add to modelContext when WeightEntryM is integrated
        newWeight = ""
    }
}

struct WeightHistoryGraph: View {
    let entries: [WeightEntry]
    
    var body: some View {
        GeometryReader { geo in
            if entries.count < 2 {
                Text("Need at least 2 entries")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                GraphPath(entries: entries, width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

struct GraphPath: View {
    let entries: [WeightEntry]
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        let weights = entries.map { $0.weight }
        let minW = weights.min() ?? 0
        let maxW = weights.max() ?? 0
        let range = maxW - minW
        let pad: CGFloat = 20
        
        Path { p in
            for (i, e) in entries.enumerated() {
                let x = width * CGFloat(i) / CGFloat(max(1, entries.count - 1))
                let norm = range > 0 ? (e.weight - minW) / range : 0.5
                let y = height - pad - (norm * (height - 2 * pad))
                if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                else { p.addLine(to: CGPoint(x: x, y: y)) }
            }
        }
        .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        
        ForEach(entries.indices, id: \.self) { i in
            let x = width * CGFloat(i) / CGFloat(max(1, entries.count - 1))
            let norm = range > 0 ? (entries[i].weight - minW) / range : 0.5
            let y = height - pad - (norm * (height - 2 * pad))
            Circle().fill(.blue).frame(width: 8, height: 8).position(x: x, y: y)
        }
    }
}

struct HistoryRow: View {
    let entry: WeightEntry
    let unit: String
    let index: Int
    let all: [WeightEntry]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(String(format: "%.1f", entry.weight)) \(unit)").font(.subheadline)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if index < all.count - 1 {
                let diff = entry.weight - all[index + 1].weight
                if abs(diff) > 0.1 {
                    Text("\(diff >= 0 ? "+" : "")\(String(format: "%.1f", diff))")
                        .font(.caption)
                        .foregroundStyle(diff >= 0 ? .red : .green)
                }
            }
        }
    }
}

struct WeightEntry: Identifiable {
    let id: UUID
    let weight: Double
    let date: Date
}

#Preview { WeightChartView(weightHistory: [], currentWeight: .constant(75.0)) }