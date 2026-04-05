import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Day Mode Enum

enum DayMode: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case rest = "Rest Day"
    case light = "Recovery"
    case heavy = "Workout Day"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .auto: return "gear"
        case .rest: return "figure.rest"
        case .light: return "heart.fill"
        case .heavy: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .auto: return .secondary
        case .rest: return .blue
        case .light: return .green
        case .heavy: return .cyan
        }
    }
}

// MARK: - Supplement Tab View

struct TabSupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [SupplementLogM]
    @Query private var preferences: [UserPreferencesM]
    @Query private var sessions: [WorkoutSessionM]
    
    @State private var showWizard = false
    @State private var showAddSupplement = false
    @State private var editingSupplement: SupplementLogM?
    @State private var showReview = false
    @State private var showExplanation = false
    @State private var selectedExplanation: SupplementExplanation?
    @State private var selectedTab = SupplementTab.today
    @State private var dayMode: DayMode?
    @State private var smartSortEnabled = true
    @State private var supplementPlan: SupplementPlan?
    @State private var suggestions: [SupplementSuggestion] = []
    @State private var showSuggestionsBadge = false
    
    // New state for delete options modal
    @State private var deleteOptionsItem: SupplementLogM?
    @State private var showDeleteOptions = false
    
    // New state for history modal
    @State private var historyItem: SupplementLogM?
    @State private var showHistory = false
    
    // New state for snooze
    @State private var snoozeItem: SupplementLogM?
    @State private var showSnoozePicker = false
    
    // New state for restock
    @State private var restockItem: SupplementLogM?
    @State private var showRestockSheet = false
    @State private var restockAmount: String = "30"
    
    // New state for library
    @State private var showLibrary = false
    
    enum SupplementTab: String, CaseIterable, Identifiable {
        case today = "Today"
        case plan = "Plan"
        case log = "Log"
        
        var id: String { rawValue }
    }
    
    var effectiveToday: Date {
        // For night owls: if before 4am, treat as previous day
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 4 {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        }
        return Date()
    }
    
    var isTrainingDay: Bool {
        if dayMode == .rest { return false }
        if dayMode == .heavy { return true }
        if dayMode == .light { return true }
        
        let dayOfWeek = dayName(for: effectiveToday)
        let planTrainingDays = supplementPlan?.info.trainingDays ?? []
        return planTrainingDays.contains(dayOfWeek)
    }
    
    var activeSupplements: [SupplementLogM] {
        let today = Calendar.current.startOfDay(for: Date())
        return supplements.filter {
            !$0.isSnoozed || ($0.snoozedUntil ?? today) < today
        }
    }
    
    var takenToday: [SupplementLogM] {
        let today = Calendar.current.startOfDay(for: Date())
        return supplements.filter {
            $0.takenDate != nil && $0.takenDate! >= today
        }
    }
    
    var todayItems: [SupplementPlanItem] {
        guard let plan = supplementPlan else {
            return activeSupplements.map { sup in
                SupplementPlanItem(
                    id: sup.id.uuidString,
                    supplement: sup.name,
                    dosage: sup.dosage,
                    time: sup.timingStr,
                    notes: sup.notes,
                    isCustom: sup.isCustom,
                    trainingDayOnly: sup.trainingDayOnly,
                    restDayOnly: sup.restDayOnly,
                    stock: sup.stock > 0 ? sup.stock : nil
                )
            }
        }
        
        let isTraining = isTrainingDay
        
        return plan.plan.filter { item in
            if item.restDayOnly { return !isTraining }
            if item.trainingDayOnly { return isTraining }
            return true
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Status Card
                Section {
                    VStack(spacing: 8) {
                        HStack {
                            Spacer()
                            Text(isTrainingDay ? "💪 Workout Day" : "🧘 Rest Day")
                                .font(.headline)
                                .foregroundStyle(isTrainingDay ? .cyan : .secondary)
                            Spacer()
                        }
                        
                        // Day Mode Selector
                        HStack(spacing: 12) {
                            ForEach(DayMode.allCases) { mode in
                                Button {
                                    dayMode = mode == .auto ? nil : mode
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: mode.icon)
                                            .font(.caption)
                                        Text(mode.rawValue)
                                            .font(.caption2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(dayMode == mode || (mode == .auto && dayMode == nil) ? mode.color.opacity(0.2) : Color(.systemGray6))
                                    )
                                    .foregroundStyle(dayMode == mode || (mode == .auto && dayMode == nil) ? mode.color : .secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                
                // Smart Schedule Banner
                if smartSortEnabled && isTrainingDay {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.indigo)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smart Schedule Active")
                                    .font(.caption.bold())
                                Text("Supplements adjusted for your training time")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Undo") {
                                smartSortEnabled = false
                            }
                            .font(.caption2)
                            .foregroundStyle(.indigo)
                        }
                    }
                }
                
                // Today's Supplements
                if !todayItems.isEmpty {
                    Section("Today's Schedule") {
                        ForEach(groupedItems(), id: \.key) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.key)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                                
                                ForEach(group.value) { item in
                                    SupplementItemRow(
                                        item: item,
                                        isTaken: takenToday.contains { $0.id.uuidString == item.id },
                                        onToggle: { toggleTaken(item) },
                                        onInfo: { showExplanation(for: item) }
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Plan Management
                if selectedTab == .plan {
                    Section {
                        Button {
                            showLibrary = true
                        } label: {
                            Label("Browse Supplement Library", systemImage: "books.vertical.fill")
                                .foregroundStyle(.cyan)
                        }
                    }
                    
                    Section("Your Plan") {
                        ForEach(activeSupplements) { sup in
                            SupplementPlanRow(
                                supplement: sup,
                                onEdit: { editingSupplement = sup },
                                onDelete: { deleteOptionsItem = sup },
                                onViewHistory: { historyItem = sup },
                                onSnooze: { snoozeSupplement(sup, days: 7) },
                                onUnsnooze: { unsnoozeSupplement(sup) },
                                onRestock: {
                                    restockItem = sup
                                    showRestockSheet = true
                                }
                            )
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                deleteOptionsItem = activeSupplements[index]
                            }
                        }
                        
                        Button {
                            showAddSupplement = true
                        } label: {
                            Label("Add Supplement", systemImage: "plus.circle.fill")
                        }
                    }
                    
                    if let plan = supplementPlan {
                        Section("Plan Info") {
                            if !plan.warnings.isEmpty {
                                ForEach(plan.warnings, id: \.self) { warning in
                                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                }
                            }
                            
                            ForEach(plan.generalTips, id: \.self) { tip in
                                Label(tip, systemImage: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    // Recalculate / Edit
                    Section {
                        Button {
                            showWizard = true
                        } label: {
                            Label("Recalculate Plan", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundStyle(.cyan)
                        }
                        
                        if !suggestions.isEmpty {
                            Button {
                                showReview = true
                            } label: {
                                HStack {
                                    Label("Review Suggestions (\(suggestions.count))", systemImage: "sparkles")
                                        .foregroundStyle(.green)
                                    Spacer()
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
                
                // Log
                if selectedTab == .log {
                    Section {
                        SupplementLogCalendarView()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                    
                    Section("Recently Taken") {
                        ForEach(Array(takenToday.enumerated()), id: \.element.id) { _, sup in
                            HStack {
                                Text(sup.name)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        if takenToday.isEmpty {
                            ContentUnavailableView(
                                "No supplements taken today",
                                systemImage: "pill",
                                description: Text("Mark supplements as taken to track your history")
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Supplements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showWizard = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showWizard) {
                SupplementWizardView(
                    existingPlan: supplementPlan,
                    onComplete: { plan in
                        supplementPlan = plan
                        syncPlanToModel(plan)
                        showWizard = false
                    }
                )
            }
            .sheet(isPresented: $showAddSupplement) {
                AddSupplementView { sup in
                    modelContext.insert(sup)
                    try? modelContext.save()
                }
            }
            .sheet(item: $editingSupplement) { sup in
                EditSupplementView(supplement: sup)
            }
            .sheet(isPresented: $showReview) {
                SupplementReviewView(
                    suggestions: suggestions,
                    onApply: { suggestion in
                        applySuggestion(suggestion)
                    },
                    onApplyAll: {
                        for suggestion in suggestions {
                            applySuggestion(suggestion)
                        }
                        suggestions = []
                        showReview = false
                    },
                    onDismissAll: {
                        suggestions = []
                        showReview = false
                    }
                )
            }
            .sheet(isPresented: $showExplanation) {
                if let explanation = selectedExplanation {
                    SupplementExplanationView(explanation: explanation)
                }
            }
            .sheet(item: $historyItem) { item in
                SupplementHistoryModal(item: item)
            }
            .sheet(item: $deleteOptionsItem) { item in
                DeleteSupplementOptionsModal(
                    item: item,
                    onSetTrainingOnly: { setTrainingOnly(item) },
                    onSetRestOnly: { setRestOnly(item) },
                    onRemoveCompletely: {
                        modelContext.delete(item)
                        try? modelContext.save()
                        deleteOptionsItem = nil
                    }
                )
            }
            .sheet(isPresented: $showLibrary) {
                SupplementLibraryView(
                    onAddToPlan: { key in
                        addLibraryItemToPlan(key: key)
                        showLibrary = false
                    }
                )
            }
            .sheet(isPresented: $showRestockSheet) {
                if let item = restockItem {
                    NavigationStack {
                        Form {
                            Section("Restock \(item.name)") {
                                Text("Current stock: \(item.stock) servings")
                                    .font(.callout)
                                
                                TextField("Amount to add", text: $restockAmount)
                                    .keyboardType(.numberPad)
                            }
                        }
                        .navigationTitle("Restock")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Cancel") { showRestockSheet = false }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Add Stock") {
                                    performRestock()
                                }
                                .bold()
                                .disabled(restockAmount.isEmpty || Int(restockAmount) == nil)
                            }
                        }
                    }
                }
            }
            .onAppear {
                loadPlan()
                generateSuggestions()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).lowercased()
    }
    
    private func groupedItems() -> [(key: String, value: [SupplementPlanItem])] {
        var groups: [String: [SupplementPlanItem]] = [:]
        
        for item in todayItems {
            let group = timeGroup(for: item.time)
            if groups[group] == nil {
                groups[group] = []
            }
            groups[group]?.append(item)
        }
        
        let order = ["Pre-Workout", "Morning", "Intra-Workout", "Post-Workout", "Lunch", "With a Meal", "Evening / Before Bed", "Any Time"]
        return groups.sorted { a, b in
            let indexA = order.firstIndex(of: a.key) ?? 99
            let indexB = order.firstIndex(of: b.key) ?? 99
            return indexA < indexB
        }
    }
    
    private func timeGroup(for time: String) -> String {
        let lower = time.lowercased()
        if lower.contains("pre-workout") || lower.contains("pre-entreno") { return "Pre-Workout" }
        if lower.contains("breakfast") || lower.contains("morning") { return "Morning" }
        if lower.contains("intra") { return "Intra-Workout" }
        if lower.contains("post-workout") || lower.contains("post-entreno") { return "Post-Workout" }
        if lower.contains("lunch") { return "Lunch" }
        if lower.contains("meal") { return "With a Meal" }
        if lower.contains("bed") || lower.contains("evening") || lower.contains("night") { return "Evening / Before Bed" }
        return "Any Time"
    }
    
    private func toggleTaken(_ item: SupplementPlanItem) {
        if let existing = supplements.first(where: { $0.id.uuidString == item.id }) {
            if existing.takenDate != nil && Calendar.current.isDate(existing.takenDate!, inSameDayAs: Date()) {
                existing.takenDate = nil
            } else {
                existing.takenDate = Date()
                existing.takenHistory.append(Date())
            }
        } else {
            let sup = SupplementLogM(
                name: item.supplement,
                dosage: item.dosage,
                timing: item.time,
                notes: item.notes,
                takenDate: Date(),
                stock: item.stock ?? 30,
                isCustom: item.isCustom,
                trainingDayOnly: item.trainingDayOnly,
                restDayOnly: item.restDayOnly,
                planId: item.id
            )
            modelContext.insert(sup)
        }
        try? modelContext.save()
    }
    
    private func showExplanation(for item: SupplementPlanItem) {
        let explanations = generateSupplementExplanations(for: supplementPlan ?? SupplementPlan(
            info: SupplementInfo(
                dob: "2000-01-01", weight: 70, height: 175, gender: "male",
                activityLevel: "intermediate", trainingDays: [], trainingTime: "afternoon",
                routineType: "strength", objective: "maintain"
            ),
            plan: []
        ))
        
        if let explanation = explanations.first(where: { item.supplement.lowercased().contains($0.id) }) {
            selectedExplanation = explanation
            showExplanation = true
        }
    }
    
    private func deleteSupplement(_ sup: SupplementLogM) {
        // This is now handled by deleteOptionsItem - show options modal
        deleteOptionsItem = sup
    }
    
    private func setTrainingOnly(_ sup: SupplementLogM) {
        sup.restDayOnly = true
        sup.trainingDayOnly = false
        try? modelContext.save()
    }
    
    private func setRestOnly(_ sup: SupplementLogM) {
        sup.trainingDayOnly = true
        sup.restDayOnly = false
        try? modelContext.save()
    }
    
    private func snoozeSupplement(_ sup: SupplementLogM, days: Int = 7) {
        sup.isSnoozed = true
        sup.snoozedUntil = Calendar.current.date(byAdding: .day, value: days, to: Date())
        try? modelContext.save()
    }
    
    private func unsnoozeSupplement(_ sup: SupplementLogM) {
        sup.isSnoozed = false
        sup.snoozedUntil = nil
        try? modelContext.save()
    }
    
    private func performRestock() {
        guard let item = restockItem,
              let amount = Int(restockAmount),
              amount > 0 else { return }
        
        item.stock += amount
        try? modelContext.save()
        
        restockItem = nil
        restockAmount = "30"
        showRestockSheet = false
    }
    
    /// Adds a supplement from the library to the user's plan with default values.
    private func addLibraryItemToPlan(key: String) {
        let library = getSupplementLibrary()
        guard let libItem = library.first(where: { $0.key == key }) else { return }
        
        let displayName = self.displayName(for: key)
        
        let sup = SupplementLogM(
            name: displayName,
            dosage: libItem.defaultDose,
            timing: libItem.defaultTime,
            notes: libItem.descriptionKey,
            stock: 30,
            isCustom: true,
            planId: "lib-\(key)"
        )
        modelContext.insert(sup)
        try? modelContext.save()
    }
    
    /// Returns a human-readable name for a supplement library key.
    private func displayName(for key: String) -> String {
        let mapping: [String: String] = [
            "creatine": "Creatine Monohydrate",
            "whey": "Whey Protein",
            "caffeine": "Caffeine",
            "multivitamin": "Multivitamin",
            "omega": "Omega-3 Fish Oil",
            "vitd3": "Vitamin D3",
            "magnesium": "Magnesium Glycinate",
            "zma": "ZMA",
            "bcaa": "BCAAs",
            "beta": "Beta-Alanine",
            "citrulline": "Citrulline Malate",
            "glutamine": "L-Glutamine",
            "casein": "Casein Protein",
            "electrolytes": "Electrolytes",
            "ashwagandha": "Ashwagandha",
            "melatonin": "Melatonin",
            "l_carnitine": "L-Carnitine",
            "collagen": "Collagen",
            "iron": "Iron",
            "preworkout": "Pre-Workout Blend"
        ]
        return mapping[key] ?? key.capitalized
    }
    
    /// Builds a dictionary mapping date strings to supplement IDs for the suggestions engine.
    /// This replaces the empty TODO placeholder that was preventing drift detection.
    private func buildTakenSupplementsDict() -> [String: [String]] {
        var dict: [String: [String]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for sup in supplements {
            // Build from takenHistory
            for date in sup.takenHistory {
                let dateStr = formatter.string(from: date)
                if dict[dateStr] == nil {
                    dict[dateStr] = []
                }
                dict[dateStr]?.append(sup.id.uuidString)
            }
            
            // Also include today's taken if applicable
            if let takenDate = sup.takenDate {
                let dateStr = formatter.string(from: takenDate)
                if dict[dateStr] == nil {
                    dict[dateStr] = []
                }
                if !dict[dateStr]!.contains(sup.id.uuidString) {
                    dict[dateStr]?.append(sup.id.uuidString)
                }
            }
        }
        
        return dict
    }
    
    /// Builds a dictionary mapping supplement IDs to arrays of take timestamps for drift detection.
    private func buildSupplementLogsDict() -> [String: [TimeInterval]] {
        var logs: [String: [TimeInterval]] = [:]
        
        for sup in supplements {
            if !sup.takenHistory.isEmpty {
                logs[sup.id.uuidString] = sup.takenHistory.map { $0.timeIntervalSince1970 }
            }
        }
        
        return logs
    }
    
    private func loadPlan() {
        // Try to load from stored supplements
        if !supplements.isEmpty {
            let items = supplements.map { sup in
                SupplementPlanItem(
                    id: sup.id.uuidString,
                    supplement: sup.name,
                    dosage: sup.dosage,
                    time: sup.timingStr,
                    notes: sup.notes,
                    isCustom: sup.isCustom,
                    trainingDayOnly: sup.trainingDayOnly,
                    restDayOnly: sup.restDayOnly,
                    stock: sup.stock > 0 ? sup.stock : nil
                )
            }
            
            // Create a default plan if none exists
            if supplementPlan == nil {
                let defaultInfo = SupplementInfo(
                    dob: "2000-01-01", weight: 70, height: 175, gender: "male",
                    activityLevel: "intermediate", trainingDays: ["monday", "wednesday", "friday"],
                    trainingTime: "afternoon", routineType: "strength", objective: "maintain"
                )
                supplementPlan = SupplementPlan(info: defaultInfo, plan: items)
            }
        }
    }
    
    private func syncPlanToModel(_ plan: SupplementPlan) {
        // Preserve IDs and Stock from existing items to maintain history continuity
        // This matches the web version's behavior where regenerating a plan keeps the same IDs
        let usedOldIds = Set<String>()
        
        for item in plan.plan {
            if item.isCustom { continue } // Custom items keep their existing IDs via matching
            
            // Find matching existing item by name + timing
            let match = supplements.first { existing in
                !existing.isCustom &&
                existing.name.lowercased() == item.supplement.lowercased() &&
                existing.timingStr.lowercased() == item.time.lowercased() &&
                !usedOldIds.contains(existing.id.uuidString)
            }
            
            if let existing = match {
                // Update existing item with new dosage/notes but preserve ID and stock
                existing.dosage = item.dosage
                existing.notes = item.notes
                existing.timingStr = item.time
                existing.trainingDayOnly = item.trainingDayOnly
                existing.restDayOnly = item.restDayOnly
                existing.planId = item.id
            } else {
                // Check if there's a partially matching item (same name, different timing)
                let partialMatch = supplements.first { existing in
                    !existing.isCustom &&
                    existing.name.lowercased() == item.supplement.lowercased() &&
                    !usedOldIds.contains(existing.id.uuidString)
                }
                
                if let existing = partialMatch {
                    existing.dosage = item.dosage
                    existing.notes = item.notes
                    existing.timingStr = item.time
                    existing.trainingDayOnly = item.trainingDayOnly
                    existing.restDayOnly = item.restDayOnly
                    existing.planId = item.id
                } else {
                    // No match, create new
                    let sup = SupplementLogM(
                        name: item.supplement,
                        dosage: item.dosage,
                        timing: item.time,
                        notes: item.notes,
                        stock: item.stock ?? 30,
                        isCustom: item.isCustom,
                        trainingDayOnly: item.trainingDayOnly,
                        restDayOnly: item.restDayOnly,
                        planId: item.id
                    )
                    modelContext.insert(sup)
                }
            }
        }
        
        // Remove generated items that are no longer in the new plan
        let newPlanIds = Set(plan.plan.map { $0.id })
        let toRemove = supplements.filter { sup in
            !sup.isCustom && 
            (sup.planId == nil || !newPlanIds.contains(sup.planId!)) &&
            !plan.plan.contains { item in
                item.supplement.lowercased() == sup.name.lowercased()
            }
        }
        
        for sup in toRemove {
            modelContext.delete(sup)
        }
        
        try? modelContext.save()
    }
    
    private func generateSuggestions() {
        guard let plan = supplementPlan else { return }
        
        let history = sessions.map { WorkoutSession(from: $0) }
        // Build takenSupplements dictionary from takenHistory for suggestions engine
        let takenDict = buildTakenSupplementsDict()
        
        suggestions = reviewSupplementPlan(
            plan: plan,
            history: history,
            takenSupplements: takenDict,
            supplementLogs: buildSupplementLogsDict()
        )
        
        showSuggestionsBadge = !suggestions.isEmpty
    }
    
    private func applySuggestion(_ suggestion: SupplementSuggestion) {
        switch suggestion.action {
        case .add(let item):
            let sup = SupplementLogM(
                name: item.supplement,
                dosage: item.dosage,
                timing: item.time,
                notes: item.notes,
                stock: item.stock ?? 30,
                isCustom: true,
                trainingDayOnly: item.trainingDayOnly,
                restDayOnly: item.restDayOnly,
                planId: item.id
            )
            modelContext.insert(sup)
            
        case .update(let itemId, let updates):
            if let sup = supplements.first(where: { $0.id.uuidString == itemId }) {
                if let dosage = updates.dosage { sup.dosage = dosage }
                if let time = updates.time { sup.timingStr = time }
                if let notes = updates.notes { sup.notes = notes }
                if let stock = updates.stock { sup.stock = stock }
                sup.trainingDayOnly = updates.trainingDayOnly ?? sup.trainingDayOnly
                sup.restDayOnly = updates.restDayOnly ?? sup.restDayOnly
            }
            
        case .remove(let itemId):
            if let sup = supplements.first(where: { $0.id.uuidString == itemId }) {
                modelContext.delete(sup)
            }
        }
        
        try? modelContext.save()
        suggestions.removeAll { $0.id == suggestion.id }
    }
}

// MARK: - Supplement Item Row

struct SupplementItemRow: View {
    let item: SupplementPlanItem
    let isTaken: Bool
    let onToggle: () -> Void
    let onInfo: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isTaken ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.supplement)
                        .font(.subheadline.bold())
                        .foregroundStyle(isTaken ? .secondary : .primary)
                        .strikethrough(isTaken)
                    
                    if let stock = item.stock, stock <= 5 {
                        Text("Low: \(stock)")
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.red.opacity(0.2), in: Capsule())
                    }
                }
                
                HStack(spacing: 8) {
                    Text(item.dosage)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(item.time)
                        .font(.caption)
                        .foregroundStyle(.cyan)
                }
                
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .opacity(isTaken ? 0.6 : 1)
    }
}

// MARK: - Supplement Plan Row

struct SupplementPlanRow: View {
    let supplement: SupplementLogM
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onViewHistory: () -> Void
    let onSnooze: () -> Void
    let onUnsnooze: () -> Void
    let onRestock: () -> Void
    
    var body: some View {
        Button(action: onViewHistory) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(supplement.name)
                        .font(.subheadline.bold())
                    HStack(spacing: 8) {
                        Text(supplement.dosage)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(supplement.timingStr)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Snooze indicator
                if supplement.isSnoozed {
                    Image(systemName: "bell.slash.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                // Stock indicator
                if supplement.stock > 0 && supplement.stock <= 5 {
                    Text("\(supplement.stock)")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.2), in: Capsule())
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onViewHistory()
            } label: {
                Label("View History", systemImage: "calendar")
            }
            
            if !supplement.isSnoozed {
                Button {
                    withAnimation {
                        onSnooze()
                    }
                } label: {
                    Label("Snooze 7 Days", systemImage: "bell.slash")
                }
            } else {
                Button {
                    withAnimation {
                        onUnsnooze()
                    }
                } label: {
                    Label("Unsnooze", systemImage: "bell")
                }
            }
            
            Divider()
            
            Button {
                onRestock()
            } label: {
                Label("Restock (\(supplement.stock))", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(supplement.isCustom == false && supplement.stock == 0)
        }
    }
}

// MARK: - Supplement Wizard View

struct SupplementWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let existingPlan: SupplementPlan?
    let onComplete: (SupplementPlan) -> Void
    
    @State private var currentStep = 1
    @State private var dob = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var gender = "male"
    @State private var activityLevel = "intermediate"
    @State private var trainingDays: Set<String> = []
    @State private var trainingTime = "afternoon"
    @State private var routineType = "strength"
    @State private var objective = "maintain"
    @State private var proteinConsumption = ""
    @State private var proteinUnknown = false
    @State private var deficiencies = ""
    @State private var desiredSupplements = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""
    @State private var consumptionPreferences = ""
    @State private var hydration = "2.5"
    @State private var error: String?
    @State private var isLoading = false
    
    let daysOfWeek = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Progress Bar
                Section {
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                Rectangle()
                                    .fill(.cyan)
                                    .frame(width: geo.size.width * CGFloat(currentStep) / 4, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                        
                        Text("Step \(currentStep) of 4")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
                
                switch currentStep {
                case 1: step1BasicInfo
                case 2: step2Activity
                case 3: step3Goals
                case 4: step4Health
                default: EmptyView()
                }
                
                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Supplement Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if currentStep < 4 {
                        Button("Next") { nextStep() }
                            .bold()
                    } else {
                        Button("Generate") { generatePlan() }
                            .bold()
                            .disabled(isLoading)
                    }
                }
            }
        }
        .onAppear {
            if let existing = existingPlan?.info {
                dob = existing.dob
                weight = String(format: "%.0f", existing.weight)
                height = String(format: "%.0f", existing.height)
                gender = existing.gender
                activityLevel = existing.activityLevel
                trainingDays = Set(existing.trainingDays)
                trainingTime = existing.trainingTime
                routineType = existing.routineType
                objective = existing.objective
                if let protein = existing.proteinConsumption {
                    proteinConsumption = String(format: "%.0f", protein)
                }
                proteinUnknown = existing.proteinUnknown
                deficiencies = existing.deficiencies.joined(separator: ", ")
                desiredSupplements = existing.desiredSupplements.joined(separator: ", ")
                allergies = existing.allergies.joined(separator: ", ")
                medicalConditions = existing.medicalConditions
                consumptionPreferences = existing.consumptionPreferences
                hydration = String(format: "%.1f", existing.hydration)
            }
        }
    }
    
    // MARK: - Step 1: Basic Info
    private var step1BasicInfo: some View {
        Section("Basic Info") {
            DatePicker("Date of Birth", selection: Binding(
                get: { DateFormatter.shared.date(from: dob) ?? Date().addingTimeInterval(-30 * 365 * 24 * 3600) },
                set: { dob = DateFormatter.shared.string(from: $0) }
            ), displayedComponents: .date)
            
            HStack {
                TextField("Weight (kg)", text: $weight)
                    .keyboardType(.decimalPad)
                Text("kg")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                TextField("Height (cm)", text: $height)
                    .keyboardType(.decimalPad)
                Text("cm")
                    .foregroundStyle(.secondary)
            }
            
            Picker("Gender", selection: $gender) {
                Text("Male").tag("male")
                Text("Female").tag("female")
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Step 2: Activity
    private var step2Activity: some View {
        Section("Activity & Training") {
            Picker("Activity Level", selection: $activityLevel) {
                Text("Beginner").tag("beginner")
                Text("Intermediate").tag("intermediate")
                Text("Advanced").tag("advanced")
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Training Days")
                    .font(.subheadline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                        Button {
                            if trainingDays.contains(day) {
                                trainingDays.remove(day)
                            } else {
                                trainingDays.insert(day)
                            }
                        } label: {
                            Text(dayLabels[index])
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(trainingDays.contains(day) ? .cyan : Color(.systemGray6))
                                )
                                .foregroundStyle(trainingDays.contains(day) ? .white : .secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            
            Picker("Training Time", selection: $trainingTime) {
                Text("Morning").tag("morning")
                Text("Afternoon").tag("afternoon")
                Text("Night").tag("night")
            }
            .pickerStyle(.segmented)
            
            Picker("Routine Type", selection: $routineType) {
                Text("Strength").tag("strength")
                Text("Cardio").tag("cardio")
                Text("Mixed").tag("mixed")
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Step 3: Goals
    private var step3Goals: some View {
        Section("Goals & Diet") {
            Picker("Objective", selection: $objective) {
                Text("Gain Muscle").tag("gain")
                Text("Lose Fat").tag("lose")
                Text("Maintain").tag("maintain")
                Text("Recovery").tag("recover")
            }
            .pickerStyle(.menu)
            
            HStack {
                TextField("Daily Protein (g)", text: $proteinConsumption)
                    .keyboardType(.decimalPad)
                    .disabled(proteinUnknown)
                Button(proteinUnknown ? "Unknown ✓" : "Unknown") {
                    proteinUnknown.toggle()
                }
                .buttonStyle(.bordered)
                .tint(proteinUnknown ? .cyan : .secondary)
            }
            
            TextField("Known Deficiencies (e.g., Vitamin D, Iron)", text: $deficiencies)
            TextField("Desired Supplements (e.g., Creatine, Whey)", text: $desiredSupplements)
        }
    }
    
    // MARK: - Step 4: Health
    private var step4Health: some View {
        Section("Health & Preferences") {
            TextField("Allergies (e.g., Lactose, Vegan)", text: $allergies)
            TextField("Medical Conditions (optional)", text: $medicalConditions)
            TextField("Consumption Preferences (optional)", text: $consumptionPreferences)
            
            HStack {
                TextField("Daily Hydration (Liters)", text: $hydration)
                    .keyboardType(.decimalPad)
                Text("L")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Actions
    private func nextStep() {
        error = nil
        
        if currentStep == 1 {
            if dob.isEmpty {
                error = "Date of Birth is required"
                return
            }
            if weight.isEmpty {
                error = "Weight is required"
                return
            }
        }
        
        currentStep += 1
    }
    
    private func generatePlan() {
        isLoading = true
        
        let info = SupplementInfo(
            dob: dob.isEmpty ? "2000-01-01" : dob,
            weight: Double(weight) ?? 70,
            height: Double(height) ?? 175,
            gender: gender,
            activityLevel: activityLevel,
            trainingDays: Array(trainingDays),
            trainingTime: trainingTime,
            routineType: routineType,
            objective: objective,
            proteinConsumption: proteinUnknown ? nil : (Double(proteinConsumption) ?? nil),
            proteinUnknown: proteinUnknown,
            deficiencies: deficiencies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            desiredSupplements: desiredSupplements.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            allergies: allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            medicalConditions: medicalConditions,
            consumptionPreferences: consumptionPreferences,
            hydration: Double(hydration) ?? 2.5
        )
        
        // Validate age
        let birthDate = DateFormatter.shared.date(from: info.dob) ?? Date().addingTimeInterval(-30 * 365 * 24 * 3600)
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 18
        if age < 18 {
            error = "You must be at least 18 years old. Please consult a doctor."
            isLoading = false
            return
        }
        
        let plan = generateSupplementPlan(info: info)
        onComplete(plan)
        isLoading = false
    }
}

// MARK: - Add Supplement View

struct AddSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let onAdd: (SupplementLogM) -> Void
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var timing = "Daily"
    @State private var notes = ""
    @State private var stock = "30"
    
    let timings = ["Daily", "Pre-workout", "Post-workout", "Morning", "With Breakfast", "With Lunch", "Evening", "Before Bed", "Intra-workout"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Supplement Info") {
                    TextField("Name (e.g., Creatine)", text: $name)
                    TextField("Dosage (e.g., 5g)", text: $dosage)
                    Picker("Timing", selection: $timing) {
                        ForEach(timings, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Notes (optional)", text: $notes)
                    TextField("Stock (servings)", text: $stock)
                        .keyboardType(.numberPad)
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
                            timing: timing,
                            notes: notes,
                            stock: Int(stock) ?? 30
                        )
                        onAdd(sup)
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
    var supplement: SupplementLogM
    
    @State private var name: String
    @State private var dosage: String
    @State private var timing: String
    @State private var notes: String
    @State private var stock: String
    
    init(supplement: SupplementLogM) {
        self.supplement = supplement
        _name = State(initialValue: supplement.name)
        _dosage = State(initialValue: supplement.dosage)
        _timing = State(initialValue: supplement.timingStr)
        _notes = State(initialValue: supplement.notes)
        _stock = State(initialValue: String(supplement.stock))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Supplement Info") {
                    TextField("Name", text: $name)
                    TextField("Dosage", text: $dosage)
                    TextField("Timing", text: $timing)
                    TextField("Notes", text: $notes)
                    TextField("Stock", text: $stock)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        name = supplement.name
                        dosage = supplement.dosage
                        timing = supplement.timingStr
                        notes = supplement.notes
                        stock = String(supplement.stock)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        supplement.name = name
                        supplement.dosage = dosage
                        supplement.timingStr = timing
                        supplement.notes = notes
                        supplement.stock = Int(stock) ?? supplement.stock
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supplement Review View

struct SupplementReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let suggestions: [SupplementSuggestion]
    let onApply: (SupplementSuggestion) -> Void
    let onApplyAll: () -> Void
    let onDismissAll: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section("Suggestions") {
                    ForEach(suggestions) { suggestion in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(suggestion.title)
                                .font(.headline.bold())
                                .foregroundStyle(.cyan)
                            
                            Text(suggestion.reason)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                Button("Apply") {
                                    onApply(suggestion)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                
                                Button("Dismiss") {
                                    // Dismiss handled by parent
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Review Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack(spacing: 16) {
                        Button("Dismiss All") {
                            onDismissAll()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Apply All") {
                            onApplyAll()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Supplement Explanation View

struct SupplementExplanationView: View {
    @Environment(\.dismiss) private var dismiss
    let explanation: SupplementExplanation
    
    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    Text(explanation.description)
                        .font(.subheadline)
                }
                
                if !explanation.benefits.isEmpty {
                    Section("Benefits") {
                        ForEach(explanation.benefits, id: \.self) { benefit in
                            Label(benefit, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                if !explanation.sideEffects.isEmpty {
                    Section("Side Effects") {
                        ForEach(explanation.sideEffects, id: \.self) { effect in
                            Label(effect, systemImage: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Section("Usage") {
                    LabeledContent("Dosage", value: explanation.dosage)
                    LabeledContent("Timing", value: explanation.timing)
                }
                
                if !explanation.stackWith.isEmpty {
                    Section("Stacks Well With") {
                        ForEach(explanation.stackWith, id: \.self) { item in
                            Text(item)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(explanation.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Date Formatter Helper

extension DateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    TabSupplementsView()
}