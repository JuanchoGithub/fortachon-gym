import SwiftUI
import SwiftData
import FortachonCore
import Charts

// MARK: - Exercise Detail Data Models

struct ExerciseBestSet: Sendable {
    let weight: Double
    let reps: Int
    let date: Date
    let sessionName: String
}

struct ExerciseHistoryEntry: Sendable {
    let sessionId: String
    let sessionName: String
    let date: Date
    let totalSets: Int
    let totalVolume: Double
    let bestE1RM: Double
    let sets: [(reps: Int, weight: Double, type: String, isComplete: Bool)]
}

struct PersonalRecord: Sendable {
    let title: String
    let value: Double
    let date: Date?
    let detail: String
}

// MARK: - Main Exercises Tab

struct TabExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [ExerciseM]
    @Query(sort: \WorkoutSessionM.startTime, order: .reverse) private var sessions: [WorkoutSessionM]
    @Query private var preferences: [UserPreferencesM]
    @State private var searchQuery = ""
    @State private var selectedBodyPart: String?
    @State private var selectedCategory: String?
    @State private var selectedDifficulty: ExerciseDifficulty?
    @State private var sortOrder: SortOrder = .ascending
    @State private var showFavoritesOnly = false
    @State private var selectedExercise: ExerciseM?
    @State private var showCreateExercise = false
    @State private var favoritesChanged = false // Trigger refresh
    
    var prefs: UserPreferencesM? { preferences.first }
    
    enum SortOrder {
        case ascending, descending, recentlyUsed
    }
    
    var bodyParts: [String] {
        Array(Set(exercises.map { $0.bodyPartStr })).sorted()
    }
    
    var categories: [String] {
        Array(Set(exercises.map { $0.categoryStr })).sorted()
    }
    
    var sortLabel: String {
        switch sortOrder {
        case .ascending: return "A-Z"
        case .descending: return "Z-A"
        case .recentlyUsed: return "Recent"
        }
    }
    
    var useLocalizedNames: Bool {
        prefs?.localizedExerciseNames ?? false
    }
    
    var filteredExercises: [ExerciseM] {
        var result = exercises
        
        if let bodyPart = selectedBodyPart {
            result = result.filter { $0.bodyPartStr == bodyPart }
        }
        
        if let category = selectedCategory {
            result = result.filter { $0.categoryStr == category }
        }
        
        if let difficulty = selectedDifficulty {
            result = result.filter { ExercisePreferences.shared.getDifficulty($0.id) == difficulty }
        }
        
        if showFavoritesOnly {
            let favs = ExercisePreferences.shared.favoriteExerciseIds
            result = result.filter { favs.contains($0.id) }
        }
        
        // Fuzzy/partial matching search (search both localized and original names)
        if !searchQuery.isEmpty {
            let terms = searchQuery.lowercased().split(separator: " ").map(String.init)
            result = result.filter { exercise in
                let displayName = exercise.displayName(useSpanish: useLocalizedNames)
                let searchText = [
                    displayName,
                    exercise.name,  // Always include original name for search
                    exercise.bodyPartStr,
                    exercise.categoryStr,
                    exercise.primaryMuscles.joined(separator: " "),
                    exercise.secondaryMuscles.joined(separator: " ")
                ].joined(separator: " ").lowercased()
                return terms.allSatisfy { term in
                    searchText.contains(term) || fuzzyMatch(term, in: searchText)
                }
            }
        }
        
        switch sortOrder {
        case .ascending:
            return result.sorted { $0.displayName(useSpanish: useLocalizedNames) < $1.displayName(useSpanish: useLocalizedNames) }
        case .descending:
            return result.sorted { $1.displayName(useSpanish: useLocalizedNames) < $0.displayName(useSpanish: useLocalizedNames) }
        case .recentlyUsed:
            return result.sorted { a, b in
                let dateA = ExercisePreferences.shared.lastUsedDate(for: a.id) ?? Date.distantPast
                let dateB = ExercisePreferences.shared.lastUsedDate(for: b.id) ?? Date.distantPast
                return dateA > dateB
            }
        }
    }
    
    // Fuzzy matching for search
    private func fuzzyMatch(_ pattern: String, in text: String) -> Bool {
        var patternIndex = text.startIndex
        for char in pattern where patternIndex < text.endIndex {
            guard let found = text[patternIndex...].firstIndex(of: char) else { return false }
            patternIndex = text.index(after: found)
        }
        return true
    }
    
    // Calculate best set for an exercise across all sessions
    func bestSet(for exerciseId: String) -> ExerciseBestSet? {
        var bestWeight: Double = 0
        var bestReps: Int = 0
        var bestDate: Date?
        var bestSessionName: String = ""
        
        for session in sessions {
            for ex in session.exercises where ex.exerciseId == exerciseId {
                for set in ex.sets where set.isComplete {
                    let e1rm = calculate1RM(weight: set.weight, reps: set.reps)
                    let currentBest = calculate1RM(weight: bestWeight, reps: bestReps)
                    if e1rm > currentBest {
                        bestWeight = set.weight
                        bestReps = set.reps
                        bestDate = session.startTime
                        bestSessionName = session.routineName
                    }
                }
            }
        }
        
        guard bestReps > 0 else { return nil }
        return ExerciseBestSet(
            weight: bestWeight,
            reps: bestReps,
            date: bestDate ?? Date(),
            sessionName: bestSessionName
        )
    }
    
    // Get full exercise history
    func exerciseHistory(for exerciseId: String) -> [ExerciseHistoryEntry] {
        var history: [ExerciseHistoryEntry] = []
        
        for session in sessions {
            guard let ex = session.exercises.first(where: { $0.exerciseId == exerciseId }) else { continue }
            
            var totalVolume: Double = 0
            var bestE1RM: Double = 0
            let sets = ex.sets.map { (reps: $0.reps, weight: $0.weight, type: $0.setTypeStr, isComplete: $0.isComplete) }
            
            for set in ex.sets where set.isComplete {
                totalVolume += set.weight * Double(set.reps)
                let e1rm = calculate1RM(weight: set.weight, reps: set.reps)
                bestE1RM = max(bestE1RM, e1rm)
            }
            
            history.append(ExerciseHistoryEntry(
                sessionId: session.wsId,
                sessionName: session.routineName,
                date: session.startTime,
                totalSets: ex.sets.filter { $0.isComplete }.count,
                totalVolume: totalVolume,
                bestE1RM: bestE1RM,
                sets: sets
            ))
        }
        
        return history
    }
    
    // Calculate personal records
    func personalRecords(for exerciseId: String) -> [PersonalRecord] {
        let history = exerciseHistory(for: exerciseId)
        var maxWeight: (value: Double, date: Date?) = (0, nil)
        var maxReps: (value: Double, date: Date?) = (0, nil)
        var maxVolume: (value: Double, date: Date?) = (0, nil)
        var maxE1RM: (value: Double, date: Date?) = (0, nil)
        
        for entry in history {
            for set in entry.sets where set.isComplete {
                if set.weight > maxWeight.value {
                    maxWeight = (set.weight, entry.date)
                }
                if Double(set.reps) > maxReps.value {
                    maxReps = (Double(set.reps), entry.date)
                }
                let volume = set.weight * Double(set.reps)
                if volume > maxVolume.value {
                    maxVolume = (volume, entry.date)
                }
                let e1rm = calculate1RM(weight: set.weight, reps: set.reps)
                if e1rm > maxE1RM.value {
                    maxE1RM = (e1rm, entry.date)
                }
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var records: [PersonalRecord] = []
        
        if maxE1RM.value > 0 {
            records.append(PersonalRecord(
                title: "Best 1RM",
                value: maxE1RM.value,
                date: maxE1RM.date,
                detail: maxE1RM.date.map { "on \(dateFormatter.string(from: $0))" } ?? ""
            ))
        }
        
        if maxWeight.value > 0 {
            records.append(PersonalRecord(
                title: "Max Weight",
                value: maxWeight.value,
                date: maxWeight.date,
                detail: maxWeight.date.map { "on \(dateFormatter.string(from: $0))" } ?? ""
            ))
        }
        
        if maxReps.value > 0 {
            records.append(PersonalRecord(
                title: "Max Reps",
                value: maxReps.value,
                date: maxReps.date,
                detail: maxReps.date.map { "on \(dateFormatter.string(from: $0))" } ?? ""
            ))
        }
        
        if maxVolume.value > 0 {
            records.append(PersonalRecord(
                title: "Max Volume",
                value: maxVolume.value,
                date: maxVolume.date,
                detail: maxVolume.date.map { "on \(dateFormatter.string(from: $0))" } ?? ""
            ))
        }
        
        return records
    }
    
    // Get chart data for graphs
    func chartData(for exerciseId: String) -> (e1rm: [(Date, Double)], volume: [(Date, Double)], maxWeight: [(Date, Double)], maxReps: [(Date, Double)]) {
        let history = exerciseHistory(for: exerciseId).reversed() // Oldest first
        
        var e1rmData: [(Date, Double)] = []
        var volumeData: [(Date, Double)] = []
        var maxWeightData: [(Date, Double)] = []
        var maxRepsData: [(Date, Double)] = []
        
        for entry in history {
            e1rmData.append((entry.date, entry.bestE1RM))
            volumeData.append((entry.date, entry.totalVolume))
            
            let sessionMaxWeight = entry.sets.filter { $0.isComplete }.map { $0.weight }.max() ?? 0
            let sessionMaxReps = Double(entry.sets.filter { $0.isComplete }.map { $0.reps }.max() ?? 0)
            
            maxWeightData.append((entry.date, sessionMaxWeight))
            maxRepsData.append((entry.date, sessionMaxReps))
        }
        
        return (e1rmData, volumeData, maxWeightData, maxRepsData)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search exercises...", text: $searchQuery)
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Filters Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Body Part Filter
                        FilterPill(
                            title: "All",
                            selected: selectedBodyPart == nil
                        ) {
                            selectedBodyPart = nil
                        }
                        ForEach(bodyParts, id: \.self) { bodyPart in
                            FilterPill(
                                title: bodyPart,
                                selected: selectedBodyPart == bodyPart
                            ) {
                                selectedBodyPart = bodyPart
                            }
                        }
                        
                        Divider().frame(height: 24)
                        
                        // Category Filter
                        FilterPill(
                            title: "All Types",
                            selected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        ForEach(categories, id: \.self) { category in
                            FilterPill(
                                title: category,
                                selected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                        
                        Divider().frame(height: 24)
                        
                        // Sort Toggle (cycles through 3 options)
                        Button {
                            withAnimation {
                                switch sortOrder {
                                case .ascending: sortOrder = .descending
                                case .descending: sortOrder = .recentlyUsed
                                case .recentlyUsed: sortOrder = .ascending
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: sortOrder == .recentlyUsed ? "clock.arrow.circlepath" : "arrow.up.arrow.down")
                                Text(sortLabel)
                                    .font(.subheadline)
                            }
                            .fontWeight(.regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // Exercise Count
                if !filteredExercises.isEmpty {
                    Text("\(filteredExercises.count) exercise\(filteredExercises.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                }
                
                // Exercise List
                List(filteredExercises) { exercise in
                    ExerciseRowView(
                        exercise: exercise,
                        bestSet: bestSet(for: exercise.id),
                        useLocalizedNames: useLocalizedNames
                    )
                    .id("\(exercise.id)-\(useLocalizedNames)") // Force refresh when locale changes
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedExercise = exercise
                    }
                }
                .listStyle(.plain)
                
                if filteredExercises.isEmpty && !searchQuery.isEmpty {
                    ContentUnavailableView(
                        "No exercises found",
                        systemImage: "magnifyingglass",
                        description: Text("Try adjusting your search or filters")
                    )
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            showFavoritesOnly.toggle()
                            if showFavoritesOnly && selectedDifficulty != nil {
                                selectedDifficulty = nil
                            }
                        }
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundStyle(showFavoritesOnly ? .yellow : .primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateExercise = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(
                    exercise: exercise,
                    history: exerciseHistory(for: exercise.id),
                    records: personalRecords(for: exercise.id),
                    chartData: chartData(for: exercise.id),
                    bestSet: bestSet(for: exercise.id)
                )
            }
            .sheet(isPresented: $showCreateExercise) {
                ExerciseEditorView(
                    exercise: nil,
                    onSave: { newExercise in
                        modelContext.insert(newExercise)
                        try? modelContext.save()
                    }
                )
            }
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(selected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Exercise Row with Best Set, Favorites, Difficulty

struct ExerciseRowView: View {
    let exercise: ExerciseM
    let bestSet: ExerciseBestSet?
    let useLocalizedNames: Bool
    @State private var isFavorite: Bool
    @State private var showDifficultyPicker = false
    
    init(exercise: ExerciseM, bestSet: ExerciseBestSet?, useLocalizedNames: Bool = false) {
        self.exercise = exercise
        self.bestSet = bestSet
        self.useLocalizedNames = useLocalizedNames
        _isFavorite = State(initialValue: ExercisePreferences.shared.isFavorite(exercise.id))
    }
    
    var displayName: String {
        exercise.displayName(useSpanish: useLocalizedNames)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Favorite Star Button
                Button {
                    isFavorite.toggle()
                    ExercisePreferences.shared.toggleFavorite(exercise.id)
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .gray)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.headline)
                            .lineLimit(1)
                        
                        // Difficulty Badge
                        if let difficulty = ExercisePreferences.shared.getDifficulty(exercise.id) {
                            DifficultyBadge(difficulty: difficulty.rawValue)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        CategoryBadge(category: exercise.categoryStr)
                        BodyPartBadge(bodyPart: exercise.bodyPartStr)
                        
                        if exercise.isTimed {
                            Text("TIMED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        
                        // Last Used Indicator
                        if let lastUsed = ExercisePreferences.shared.lastUsedFormatted(exercise.id) {
                            Label(lastUsed, systemImage: "clock")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if !exercise.primaryMuscles.isEmpty {
                    MuscleTagView(muscle: exercise.primaryMuscles.first ?? "")
                }
            }
            
            // Best Set Display
            if let best = bestSet {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.0f × %d", best.weight, best.reps))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(best.sessionName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 4, height: 4)
                    Text("No records yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button {
                isFavorite.toggle()
                ExercisePreferences.shared.toggleFavorite(exercise.id)
            } label: {
                Label(isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: isFavorite ? "star.fill" : "star")
            }
            
            Menu("Set Difficulty") {
                ForEach(ExerciseDifficulty.allCases, id: \.self) { diff in
                    Button {
                        ExercisePreferences.shared.setDifficulty(exercise.id, difficulty: diff)
                    } label: {
                        Label(diff.displayName, systemImage: ExercisePreferences.shared.getDifficulty(exercise.id) == diff ? "checkmark" : "")
                    }
                }
            }
        }
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: String
    
    var color: Color {
        switch category.lowercased() {
        case "barbell": return .red
        case "dumbbell": return .orange
        case "machine": return .blue
        case "cable": return .purple
        case "bodyweight": return .green
        case "kettlebell": return .yellow
        case "smith machine": return .mint
        default: return .gray
        }
    }
    
    var body: some View {
        Text(category.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Body Part Badge

struct BodyPartBadge: View {
    let bodyPart: String
    
    var color: Color {
        switch bodyPart.lowercased() {
        case "chest": return .red
        case "back": return .blue
        case "legs": return .green
        case "shoulders": return .orange
        case "biceps": return .purple
        case "triceps": return .yellow
        case "core": return .mint
        case "glutes": return .pink
        case "full body": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        Text(bodyPart.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Muscle Tag View

struct MuscleTagView: View {
    let muscle: String
    
    var body: some View {
        Text(muscle)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.15), in: Capsule())
            .foregroundStyle(.blue)
    }
}

// MARK: - Exercise Detail View with Tabs

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let exercise: ExerciseM
    let history: [ExerciseHistoryEntry]
    let records: [PersonalRecord]
    let chartData: (e1rm: [(Date, Double)], volume: [(Date, Double)], maxWeight: [(Date, Double)], maxReps: [(Date, Double)])
    let bestSet: ExerciseBestSet?
    
    @State private var selectedTab: DetailTab = .description
    @State private var showEditExercise = false
    @State private var exerciseToEdit: ExerciseM?
    
    enum DetailTab: String, CaseIterable {
        case description = "Details"
        case history = "History"
        case graphs = "Graphs"
        case records = "Records"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with exercise info
                VStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 6) {
                        CategoryBadge(category: exercise.categoryStr)
                        BodyPartBadge(bodyPart: exercise.bodyPartStr)
                        
                        if exercise.isTimed {
                            Label("TIMED", systemImage: "stopwatch")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.yellow.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Segmented Control
                Picker("Detail Tab", selection: $selectedTab) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Tab Content
                TabContentView(
                    tab: selectedTab,
                    exercise: exercise,
                    history: history,
                    records: records,
                    chartData: chartData,
                    bestSet: bestSet
                )
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            exerciseToEdit = exercise
                            showEditExercise = true
                        } label: {
                            Label("Edit Exercise", systemImage: "pencil")
                        }
                        Button {
                            duplicateExercise()
                        } label: {
                            Label("Duplicate Exercise", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showEditExercise, onDismiss: { exerciseToEdit = nil }) {
                if let ex = exerciseToEdit {
                    ExerciseEditorView(
                        exercise: ex,
                        onSave: { updatedExercise in
                            // Update existing exercise properties directly
                            ex.name = updatedExercise.name
                            ex.bodyPartStr = updatedExercise.bodyPartStr
                            ex.categoryStr = updatedExercise.categoryStr
                            ex.notes = updatedExercise.notes
                            ex.isTimed = updatedExercise.isTimed
                            ex.isUnilateral = updatedExercise.isUnilateral
                            ex.primaryMuscles = updatedExercise.primaryMuscles
                            ex.secondaryMuscles = updatedExercise.secondaryMuscles
                            try? modelContext.save()
                        }
                    )
                }
            }
        }
    }
    
    private func duplicateExercise() {
        let newExercise = ExerciseM(
            id: "custom-\(UUID().uuidString)",
            name: "\(exercise.name) (Copy)",
            bodyPart: exercise.bodyPartStr,
            category: exercise.categoryStr,
            notes: exercise.notes,
            isTimed: exercise.isTimed,
            isUnilateral: exercise.isUnilateral,
            primaryMuscles: exercise.primaryMuscles,
            secondaryMuscles: exercise.secondaryMuscles
        )
        modelContext.insert(newExercise)
        try? modelContext.save()
    }
}

// MARK: - Tab Content View

struct TabContentView: View {
    let tab: ExerciseDetailView.DetailTab
    let exercise: ExerciseM
    let history: [ExerciseHistoryEntry]
    let records: [PersonalRecord]
    let chartData: (e1rm: [(Date, Double)], volume: [(Date, Double)], maxWeight: [(Date, Double)], maxReps: [(Date, Double)])
    let bestSet: ExerciseBestSet?
    
    var body: some View {
        ScrollView {
            switch tab {
            case .description:
                DescriptionTabView(exercise: exercise, bestSet: bestSet)
            case .history:
                HistoryTabView(history: history)
            case .graphs:
                GraphsTabView(exercise: exercise, chartData: chartData)
            case .records:
                RecordsTabView(records: records, bestSet: bestSet)
            }
        }
    }
}

// MARK: - Description Tab

struct DescriptionTabView: View {
    let exercise: ExerciseM
    let bestSet: ExerciseBestSet?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Best Set Card
            if let best = bestSet {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        Text("Personal Best")
                            .font(.headline)
                    }
                    
                    HStack(spacing: 16) {
                        VStack {
                            Text(String(format: best.weight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", best.weight))
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Weight")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider().frame(height: 40)
                        
                        VStack {
                            Text("\(best.reps)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Text(best.sessionName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Exercise Details
            Section {
                LabeledContent("Body Part", value: exercise.bodyPartStr)
                LabeledContent("Category", value: exercise.categoryStr)
                LabeledContent("Timed", value: exercise.isTimed ? "Yes" : "No")
                LabeledContent("Unilateral", value: exercise.isUnilateral ? "Yes" : "No")
            } header: {
                Text("Details")
                    .font(.headline)
            }
            
            if let notes = exercise.notes, !notes.isEmpty {
                Section {
                    Text(notes)
                        .font(.body)
                } header: {
                    Text("Notes")
                        .font(.headline)
                }
            }
            
            if !exercise.primaryMuscles.isEmpty {
                Section {
                    FlowLayout {
                        ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.red.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                } header: {
                    Text("Primary Muscles")
                        .font(.headline)
                }
            }
            
            if !exercise.secondaryMuscles.isEmpty {
                Section {
                    FlowLayout {
                        ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                } header: {
                    Text("Secondary Muscles")
                        .font(.headline)
                }
            }
        }
        .padding()
    }
}

// MARK: - History Tab

struct HistoryTabView: View {
    let history: [ExerciseHistoryEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if history.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Complete workouts with this exercise to see your history")
                )
            } else {
                Text("\(history.count) session\(history.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                ForEach(Array(history.enumerated()), id: \.element.sessionId) { index, entry in
                    HistoryEntryCard(entry: entry, isLatest: index == 0)
                }
            }
        }
        .padding()
    }
}

struct HistoryEntryCard: View {
    let entry: ExerciseHistoryEntry
    let isLatest: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.sessionName)
                        .font(.headline)
                    Text(dateFormatter.string(from: entry.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isLatest {
                    Text("LATEST")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 16) {
                StatItem(icon: "list.bullet", value: "\(entry.totalSets)", label: "sets")
                StatItem(icon: "flame.fill", value: String(format: "%.0f", entry.totalVolume), label: "volume")
                if entry.bestE1RM > 0 {
                    StatItem(icon: "trophy.fill", value: String(format: "%.1f", entry.bestE1RM), label: "best 1RM")
                }
            }
        }
        .padding()
        .background(isLatest ? AnyShapeStyle(Color.blue.opacity(0.05)) : AnyShapeStyle(Material.ultraThinMaterial), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Graphs Tab

struct GraphsTabView: View {
    let exercise: ExerciseM
    let chartData: (e1rm: [(Date, Double)], volume: [(Date, Double)], maxWeight: [(Date, Double)], maxReps: [(Date, Double)])
    
    var body: some View {
        VStack(spacing: 16) {
            if chartData.e1rm.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.bar.fill",
                    description: Text("Complete workouts to see progress charts")
                )
            } else {
                MiniChartView(title: "Best 1RM", data: chartData.e1rm, color: .indigo)
                MiniChartView(title: "Max Weight", data: chartData.maxWeight, color: .red)
                MiniChartView(title: "Total Volume", data: chartData.volume, color: .blue)
                MiniChartView(title: "Max Reps", data: chartData.maxReps, color: .yellow)
            }
        }
        .padding()
    }
}

// MARK: - Mini Chart View (Simple Line Chart)

struct MiniChartView: View {
    let title: String
    let data: [(Date, Double)]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            if data.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 80)
            } else {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Date", point.0),
                            y: .value("Value", point.1)
                        )
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Date", point.0),
                            y: .value("Value", point.1)
                        )
                        .foregroundStyle(color.opacity(0.1))
                    }
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: Date.FormatStyle().month(.abbreviated).day(.twoDigits))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Records Tab

struct RecordsTabView: View {
    let records: [PersonalRecord]
    let bestSet: ExerciseBestSet?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Records",
                    systemImage: "trophy",
                    description: Text("Complete workouts to set personal records")
                )
            } else {
                ForEach(records.indices, id: \.self) { index in
                    RecordCard(record: records[index])
                }
            }
        }
        .padding()
    }
}

struct RecordCard: View {
    let record: PersonalRecord
    
    var icon: String {
        switch record.title {
        case "Best 1RM": return "trophy.fill"
        case "Max Weight": return "weight.scale.fill"
        case "Max Reps": return "repeat"
        case "Max Volume": return "chart.line.uptrend.xyaxis"
        default: return "star.fill"
        }
    }
    
    var iconColor: Color {
        switch record.title {
        case "Best 1RM": return .indigo
        case "Max Weight": return .red
        case "Max Reps": return .yellow
        case "Max Volume": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(String(format: record.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", record.value))
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !record.detail.isEmpty {
                    Text(record.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    TabExercisesView()
}