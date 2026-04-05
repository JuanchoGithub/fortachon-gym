import SwiftUI
import SwiftData
import FortachonCore

struct TabSupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [SupplementLogM]
    @State private var showAddSupplement = false
    @State private var editingSupplement: SupplementLogM?
    
    var activeSupplements: [SupplementLogM] {
        let today = Calendar.current.startOfDay(for: Date())
        return supplements.filter {
            !$0.isSnoozed || ($0.snoozedUntil ?? today) < today
        }
    }
    
    var snoozedSupplements: [SupplementLogM] {
        let today = Calendar.current.startOfDay(for: Date())
        return supplements.filter {
            $0.isSnoozed && ($0.snoozedUntil ?? today) >= today
        }
    }
    
    var takenToday: [SupplementLogM] {
        let today = Calendar.current.startOfDay(for: Date())
        return supplements.filter {
            $0.takenDate != nil && $0.takenDate! >= today
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Taken Today Section
                if !takenToday.isEmpty {
                    Section("Taken Today ✅") {
                        ForEach(takenToday) { sup in
                            SupplementRowView(supplement: sup, isTaken: true)
                        }
                    }
                }
                
                // Active Supplements
                if !activeSupplements.isEmpty {
                    Section("Active Supplements") {
                        ForEach(activeSupplements) { sup in
                            SupplementRowView(supplement: sup, isTaken: takenToday.contains { $0.id == sup.id })
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let sup = activeSupplements[index]
                                modelContext.delete(sup)
                            }
                            try? modelContext.save()
                        }
                    }
                }
                
                // Snoozed Supplements
                if !snoozedSupplements.isEmpty {
                    Section("Snoozed") {
                        ForEach(snoozedSupplements) { sup in
                            SupplementRowView(supplement: sup, isSnoozed: true)
                        }
                    }
                }
                
                // Empty State
                if supplements.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Supplements",
                            systemImage: "pill",
                            description: Text("Tap + to add your first supplement.")
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Supplements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSupplement = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSupplement) {
                AddSupplementView()
            }
            .sheet(item: $editingSupplement) { sup in
                EditSupplementView(supplement: sup)
            }
        }
    }
}

// MARK: - Supplement Row

struct SupplementRowView: View {
    @Environment(\.modelContext) private var modelContext
    let supplement: SupplementLogM
    let isTaken: Bool
    let isSnoozed: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(supplement.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(supplement.dosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(supplement.timingStr)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isTaken {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if isSnoozed {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(.orange)
            } else {
                Menu {
                    Button {
                        supplement.takenDate = Date()
                        try? modelContext.save()
                    } label: {
                        Label("Mark as taken", systemImage: "checkmark")
                    }
                    Button {
                        supplement.isSnoozed = true
                        supplement.snoozedUntil = Date().addingTimeInterval(24 * 3600)
                        try? modelContext.save()
                    } label: {
                        Label("Snooze for 24h", systemImage: "bell.slash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Add Supplement View

struct AddSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var timing = "Daily"
    
    var timings = ["Daily", "Pre-workout", "Post-workout", "Morning", "Evening", "With meals"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Supplement Info") {
                    TextField("Name (e.g., Creatine)", text: $name)
                    TextField("Dosage (e.g., 5g)", text: $dosage)
                    Picker("Timing", selection: $timing) {
                        ForEach(timings, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                }
            }
            .navigationTitle("Add Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let sup = SupplementLogM(
                            name: name,
                            dosage: dosage,
                            timing: timing
                        )
                        modelContext.insert(sup)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Supplement View

struct EditSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var supplement: SupplementLogM
    
    @State private var name: String
    @State private var dosage: String
    @State private var timing: String
    
    init(supplement: SupplementLogM) {
        self.supplement = supplement
        _name = State(initialValue: supplement.name)
        _dosage = State(initialValue: supplement.dosage)
        _timing = State(initialValue: supplement.timingStr)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Supplement Info") {
                    TextField("Name", text: $name)
                    TextField("Dosage", text: $dosage)
                    TextField("Timing", text: $timing)
                }
            }
            .navigationTitle("Edit Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        // Reset changes
                        name = supplement.name
                        dosage = supplement.dosage
                        timing = supplement.timingStr
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        supplement.name = name
                        supplement.dosage = dosage
                        supplement.timingStr = timing
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TabSupplementsView()
}