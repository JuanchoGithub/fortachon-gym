import SwiftUI
import SwiftData
import FortachonCore

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [ExerciseM]
    let routine: RoutineM?
    
    @Binding var isActive: Bool
    @State private var session: WorkoutSessionM
    @State private var showAddExercise = false
    @State private var selectedExerciseIndexAndSet: ExerciseSetKey?
    @State private var showFinishConfirmation = false
    @State private var expandedIds: Set<String> = []
    @State private var timerTask: Task<Void, Never>?
    @State private var elapsed: TimeInterval = 0
    @State private var showRestTimer = false
    @State private var restRemaining: TimeInterval = 0
    @State private var restTotal: TimeInterval = 0
    
    // Superset management
    @State private var showSupersetManager = false
    
    // Drag and drop
    @State private var isReorderMode = false
    @State private var draggedExerciseIndex: Int? = nil
    
    // Auto 1RM updates
    @State private var pending1RMUpdates: [(exerciseName: String, oldMax: Double, newMax: Double)] = []
    @State private var show1RMBanner = false
    
    // Plate calculator
    @State private var showPlateCalculator = false
    
    // Set timer for timed sets
    @State private var showSetTimer = false
    @State private var setTimerRemaining: TimeInterval = 0
    @State private var setTimerTotal: TimeInterval = 0
    
    // Sound effects
    @State private var soundEffects = SoundEffectsService()
    
    // New features
    @State private var audioCoach = AudioCoach()
    @State private var coachSuggestions: [UpgradeSuggestion] = []
    @State private var historicalData: [String: (avgWeight: Double, avgReps: Int)] = [:]
    @State private var showNotesEditor = false
    @State private var validationErrors: [String] = []
    @State private var showValidationErrors = false
    
    // RPE editing state
    @State private var showRPEEditor = false
    @State private var rpeEditingExerciseIndex: Int? = nil
    @State private var rpeEditingSetIndex: Int? = nil
    
    // Muscle freshness
    @State private var muscleFreshness: [MuscleFreshness] = []
    @State private var exerciseFreshness: [String: Double] = [:]  // exerciseId -> freshness %
    @State private var showFreshnessDetail = false
    @State private var freshnessDetailExerciseId: String = ""
    
    // Preference
    @Query private var preferences: [UserPreferencesM]
    var prefs: UserPreferencesM? { preferences.first }
    var useLocalizedNames: Bool { prefs?.localizedExerciseNames ?? false }
    
    /// Get localized exercise name
    private func exerciseName(for exerciseDef: ExerciseM?) -> String {
        guard let ex = exerciseDef else { return "Unknown Exercise" }
        return ex.displayName(useSpanish: useLocalizedNames)
    }
    
    struct ExerciseSetKey: Identifiable {
        let id = UUID()
        let ex: Int
        let set: Int
    }
    
    init(isActive: Binding<Bool>, routine: RoutineM? = nil) {
        self._isActive = isActive
        self.routine = routine
        let s = WorkoutSessionM(
            id: "ws-\(UUID().uuidString)",
            routineId: routine?.rtId ?? "quick-",
            routineName: routine?.name ?? "Quick Workout",
            startTime: Date(), endTime: Date()
        )
        if let r = routine {
            for ex in r.exercises {
                let we = WorkoutExerciseM(id: "we-\(UUID().uuidString)", exerciseId: ex.exerciseId)
                for set in ex.sets {
                    we.sets.append(PerformedSetM(id: "set-\(UUID().uuidString)", reps: set.reps, weight: set.weight, type: set.setTypeStr))
                }
                s.exercises.append(we)
            }
        }
        _session = State(initialValue: s)
    }
    
    private var progress: Double {
        guard !session.exercises.isEmpty else { return 0 }
        var completed = 0
        var total = 0
        for ex in session.exercises {
            for set in ex.sets where set.setTypeStr != "warmup" {
                total += 1
                if set.isComplete { completed += 1 }
            }
        }
        return total > 0 ? Double(completed) / Double(total) : 0
    }
    
    private var completedCount: Int {
        session.exercises.reduce(0) { count, ex in
            count + ex.sets.filter { $0.isComplete && $0.setTypeStr != "warmup" }.count
        }
    }
    
    private var totalCount: Int {
        session.exercises.reduce(0) { count, ex in
            count + ex.sets.filter { $0.setTypeStr != "warmup" }.count
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                VStack(alignment: .leading) {
                    Text(session.routineName).font(.title3.bold())
                    HStack(spacing: 8) {
                        Text(elapsed.formattedAsWorkout)
                            .font(.title2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        if totalCount > 0 {
                            Text("• \(completedCount)/\(totalCount) sets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    // Progress percentage
                    if totalCount > 0 {
                        let pct = progress * 100
                        Text("\(Int(pct))% complete")
                            .font(.caption)
                            .foregroundStyle(pct >= 100 ? .green : .blue)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    // Reorder mode toggle
                    Button(action: { isReorderMode.toggle() }) {
                        Image(systemName: isReorderMode ? "checkmark.square.fill" : "arrow.up.arrow.down")
                            .font(.title3)
                            .foregroundStyle(isReorderMode ? .orange : .secondary)
                    }
                    // Superset manager
                    Button(action: { showSupersetManager = true }) {
                        Image(systemName: "rectangle.3.group.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    // Plate calculator
                    Button(action: { showPlateCalculator = true }) {
                        Image(systemName: "scalemass.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    // Audio coach toggle
                    Button(action: { audioCoach.isEnabled.toggle() }) {
                        Image(systemName: audioCoach.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title3)
                            .foregroundStyle(audioCoach.isEnabled ? .blue : .secondary)
                    }
                    // Notes button
                    Button(action: { showNotesEditor = true }) {
                        Image(systemName: "note.text")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    // Finish button
                    Button("Finish") { validateAndFinish() }
                        .font(.headline).padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.green).foregroundStyle(.white).clipShape(Capsule())
                }
            }
            .padding().padding(.horizontal)
            
            // Progress bar
            if totalCount > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(progress >= 1.0 ? .green : .blue)
                    .padding(.horizontal)
            }
            
            Divider()
            
            // MARK: - Exercise List
            if isReorderMode {
                // Reorder mode with drag & drop using List
                List {
                    ForEach(Array(session.exercises.enumerated()), id: \.element.weId) { idx, ex in
                        exerciseCardReorderable(for: ex, at: idx)
                    }
                    .onMove { source, destination in
                        session.exercises.move(fromOffsets: source, toOffset: destination)
                    }
                }
                .listStyle(.plain)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(session.exercises.enumerated()), id: \.element.weId) { idx, ex in
                            exerciseCard(for: ex, at: idx)
                        }
                        
                        // Coach Suggestions Banner
                        CoachSuggestionsBanner(
                            suggestions: coachSuggestions,
                            onUpgrade: handleUpgrade
                        )
                        
                        // Add Exercise button
                        Button { showAddExercise = true } label: {
                            Label("Add Exercise", systemImage: "plus.circle").frame(maxWidth: .infinity).padding()
                        }.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal).padding(.top, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddExercise) { ExPicker { id in
            addExercise(id)
        }}
        .sheet(isPresented: $showNotesEditor) {
            NavigationStack {
                VStack {
                    TextEditor(text: $session.notes)
                        .padding()
                }
                .navigationTitle("Workout Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showNotesEditor = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Validation Errors", isPresented: $showValidationErrors) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
        .fullScreenCover(isPresented: $showRestTimer) {
            RestTimerOverlay(timeRemaining: $restRemaining, totalTime: restTotal)
        }
        .sheet(isPresented: $showSupersetManager) {
            SupersetManagerView(
                sessionExercises: $session.exercises,
                sessionSupersets: $session.supersets
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showPlateCalculator) {
            PlateCalculatorView(
                barWeight: 20,
                plateSizes: [25, 20, 15, 10, 5, 2.5, 1.25]
            )
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showSetTimer) {
            SetTimerOverlay(
                timeRemaining: $setTimerRemaining,
                totalTime: setTimerTotal
            )
        }
        // RPE Editor Sheet
        .sheet(isPresented: $showRPEEditor) {
            if let exIdx = rpeEditingExerciseIndex,
               let setIdx = rpeEditingSetIndex,
               exIdx < session.exercises.count,
               setIdx < session.exercises[exIdx].sets.count {
                let ex = session.exercises[exIdx]
                let set = ex.sets[setIdx]
                let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
                let exerciseName = exerciseDef?.name ?? ex.exerciseId
                let setNumber = setIdx + 1
                let setInfo = "\(exerciseName) — Set \(setNumber)"
                RPEEntrySheet(
                    rpe: Binding(
                        get: { set.rpe },
                        set: { newValue in set.rpe = newValue }
                    ),
                    setInfo: setInfo
                ) {
                    showRPEEditor = false
                    rpeEditingExerciseIndex = nil
                    rpeEditingSetIndex = nil
                }
            }
        }
        // Auto 1RM Update Banner
        .overlay {
            if show1RMBanner && !pending1RMUpdates.isEmpty {
                VStack {
                    OneRMUpdateBanner(
                        updates: pending1RMUpdates,
                        onDismiss: {
                            pending1RMUpdates.removeAll()
                            show1RMBanner = false
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: show1RMBanner)
            }
        }
        .alert("Finish?", isPresented: $showFinishConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Finish", role: .destructive) { endWorkout() }
        }
        .onAppear {
            // Start workout timer
            timerTask = Task.detached { [start = session.startTime] in
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(1)) } catch { break }
                    if !Task.isCancelled {
                        await MainActor.run { elapsed = Date().timeIntervalSince(start) }
                    }
                }
            }
            // Announce workout start
            audioCoach.announceWorkoutStart(routineName: session.routineName)
            // Load historical data
            loadHistoricalData()
            // Load muscle freshness
            loadMuscleFreshness()
            // Generate coach suggestions
            generateSuggestions()
            // Expand first exercise
            if let first = session.exercises.first {
                expandedIds.insert(first.weId)
            }
        }
        .onDisappear { timerTask?.cancel() }
    }
    
    // MARK: - Reorderable Exercise Card Builder
    
    @ViewBuilder
    private func exerciseCardReorderable(for ex: WorkoutExerciseM, at idx: Int) -> some View {
        HStack(spacing: 8) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            exerciseCard(for: ex, at: idx)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Exercise Card Builder
    
    @ViewBuilder
    private func exerciseCard(for ex: WorkoutExerciseM, at idx: Int) -> some View {
        // Find the exercise definition
        let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
        let isTimed = exerciseDef?.isTimed ?? false
        let isCardio = exerciseDef?.categoryStr == "Cardio" || exerciseDef?.categoryStr == "Duration" ||
                       exerciseDef?.categoryStr == "Cardio"
        
        if isTimed {
            TimedExerciseCard(
                exercise: exerciseDef ?? unknownExerciseModel(),
                idx: idx,
                existingSets: ex.sets,
                onAddSet: { seconds in
                    ex.sets.append(PerformedSetM(
                        id: "set-\(UUID())", reps: 0, weight: 0,
                        time: seconds, type: "timed", isComplete: true,
                        completedAt: Date()
                    ))
                    audioCoach.announceSetComplete(
                        exerciseName: exerciseDef?.name ?? "Exercise",
                        setNumber: ex.sets.filter { $0.setTypeStr == "timed" && $0.isComplete }.count,
                        weight: 0, reps: 0
                    )
                }
            )
            .padding(.horizontal, 0)
        } else if isCardio {
            CardioExerciseCard(
                exercise: exerciseDef ?? unknownExerciseModel(),
                idx: idx,
                existingSets: ex.sets
            ) { durationSecs, distance in
                ex.sets.append(PerformedSetM(
                    id: "set-\(UUID())", reps: 0, weight: distance,
                    time: durationSecs, type: "normal", isComplete: true,
                    completedAt: Date()
                ))
                audioCoach.announceSetComplete(
                    exerciseName: exerciseDef?.name ?? "Exercise",
                    setNumber: ex.sets.count,
                    weight: 0, reps: 0
                )
            }
            .padding(.horizontal, 0)
        } else {
            ExCard(
                ex: ex,
                idx: idx,
                exerciseName: exerciseName(for: exerciseDef),
                expanded: expandedIds.contains(ex.weId),
                onToggleExpand: {
                    if expandedIds.contains(ex.weId) { expandedIds.remove(ex.weId) }
                    else { expandedIds.insert(ex.weId) }
                },
                onToggleSet: { set, type in
                    set.isComplete = !set.isComplete
                    if set.isComplete {
                        set.completedAt = Date()
                        let t = SetType(rawValue: set.setTypeStr) ?? .normal
                        restRemaining = TimeInterval(restFor(t))
                        restTotal = restRemaining
                        showRestTimer = true
                        // Audio announcement
                        let exerciseName = exerciseName(for: exerciseDef)
                        let setNum = ex.sets.filter { $0.setTypeStr == set.setTypeStr }.firstIndex(where: { $0.setId == set.setId }) ?? 0
                        audioCoach.announceSetComplete(
                            exerciseName: exerciseName,
                            setNumber: setNum + 1,
                            weight: set.weight,
                            reps: set.reps
                        )
                        // Set historical comparison
                        if let hist = historicalData[ex.exerciseId] {
                            set.historicalWeight = hist.avgWeight
                            set.historicalReps = hist.avgReps
                        }
                    } else {
                        set.completedAt = nil
                    }
                },
                historicalData: historicalData[ex.exerciseId],
                onRPETap: { setIndex in
                    rpeEditingExerciseIndex = idx
                    rpeEditingSetIndex = setIndex
                    showRPEEditor = true
                }
            )
            
            if expandedIds.contains(ex.weId) {
                Button {
                    let last = ex.sets.last
                    let lastWeight = last?.weight ?? 0
                    let lastReps = last?.reps ?? 0
                    let lastType = last?.setTypeStr ?? "normal"
                    ex.sets.append(PerformedSetM(
                        id: "set-\(UUID())", reps: lastReps, weight: lastWeight,
                        type: lastType
                    ))
                } label: {
                    Label("Add Set", systemImage: "plus").frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Actions
    
    private func addExercise(_ id: String) {
        let we = WorkoutExerciseM(id: "we-\(UUID())", exerciseId: id)
        we.sets.append(PerformedSetM(id: "s1", reps: 0, weight: 0, type: "warmup"))
        for _ in 0..<3 { we.sets.append(PerformedSetM(id: "s-\(UUID())", reps: 0, weight: 0, type: "normal")) }
        session.exercises.append(we)
        expandedIds.insert(we.weId)
        // Regenerate suggestions
        generateSuggestions()
    }
    
    private func handleUpgrade(_ suggestion: UpgradeSuggestion) {
        guard let idx = session.exercises.firstIndex(where: { $0.exerciseId == suggestion.currentExerciseId }) else { return }
        session.exercises[idx].exerciseId = suggestion.targetExerciseId
        // Remove the suggestion
        coachSuggestions.removeAll { $0.id == suggestion.id }
        generateSuggestions()
    }
    
    private func validateAndFinish() {
        let errors = validateWorkout()
        if errors.isEmpty {
            showFinishConfirmation = true
        } else {
            validationErrors = errors
            showValidationErrors = true
        }
    }
    
    private func validateWorkout() -> [String] {
        var errors: [String] = []
        if session.exercises.isEmpty {
            errors.append("No exercises added. Add at least one exercise to finish.")
        }
        for ex in session.exercises {
            let hasCompletedSets = ex.sets.contains { $0.isComplete }
            if !hasCompletedSets {
                let name = allExercises.first { $0.id == ex.exerciseId }?.name ?? ex.exerciseId
                errors.append("\"\(name)\" has no completed sets.")
            }
        }
        return errors
    }
    
    private func endWorkout() {
        session.endTime = Date()
        modelContext.insert(session)
        try? modelContext.save()
        isActive = false
    }
    
    private func restFor(_ t: SetType) -> Int {
        switch t { case .warmup: 60; case .drop: 30; case .failure: 300; case .timed: 10; default: 90 }
    }
    
    // MARK: - Helpers
    
    private func loadHistoricalData() {
        let lookup = HistoricalLookup(modelContext: modelContext)
        var data: [String: (avgWeight: Double, avgReps: Int)] = [:]
        for ex in session.exercises {
            if let hist = lookup.getLastSessionValues(for: ex.exerciseId) {
                data[ex.exerciseId] = hist
            }
        }
        historicalData = data
    }
    
    private func generateSuggestions() {
        let exerciseIds = session.exercises.map { $0.exerciseId }
        let lookup = HistoricalLookup(modelContext: modelContext)
        let frequency = lookup.getExerciseFrequency()
        coachSuggestions = UpgradeSuggestions.generate(
            currentExerciseIds: exerciseIds,
            allExercises: allExercises,
            frequency: frequency
        )
    }
    
    private func loadMuscleFreshness() {
        let historyLookup = HistoricalLookup(modelContext: modelContext)
        let latestSessions = historyLookup.getRecentSessions(limit: 10)
        
        // Convert to freshness calculation format
        let sessions = latestSessions.map { session -> (exercises: [WorkoutExercise], startTime: Date, endTime: Date) in
            let exercises = session.exercises.map { WorkoutExercise(from: $0) }
            return (exercises: exercises, startTime: session.startTime, endTime: session.endTime)
        }
        let exercises = allExercises.map { Exercise(from: $0) }
        
        // Use bio-adaptive if enabled
        let bioAdaptive = prefs?.bioAdaptiveEngine ?? false
        let baseline = prefs?.mainGoal == .strength ? 10.0 : (prefs?.mainGoal == .endurance ? 20.0 : 15.0)
        
        muscleFreshness = calculateMuscleFreshnessAdvanced(
            sessions: sessions,
            exercises: exercises,
            capacityBaseline: baseline,
            bioAdaptiveEnabled: bioAdaptive
        )
        
        // Calculate per-exercise freshness
        var freshnessMap: [String: Double] = [:]
        for ex in exercises {
            if let freshness = getExerciseFreshness(exerciseId: ex.id, freshnessData: muscleFreshness, exercises: exercises) {
                freshnessMap[ex.id] = freshness
            }
        }
        exerciseFreshness = freshnessMap
    }
    
    private func unknownExerciseModel() -> ExerciseM {
        ExerciseM(id: "unknown", name: "Unknown Exercise", bodyPart: "Full Body", category: "Bodyweight")
    }
}

// MARK: - Exercise Card View

struct ExCard: View {
    let ex: WorkoutExerciseM
    let idx: Int
    let exerciseName: String
    let expanded: Bool
    let onToggleExpand: () -> Void
    let onToggleSet: (PerformedSetM, SetType) -> Void
    let historicalData: (avgWeight: Double, avgReps: Int)?
    let onRPETap: ((Int) -> Void)?  // Pass set index for RPE editing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggleExpand) {
                HStack {
                    Text("\(idx + 1). \(exerciseName)").font(.headline).lineLimit(1)
                    Spacer()
                    let done = ex.sets.filter { $0.isComplete }.count
                    Text("\(done)/\(ex.sets.count)").font(.caption).foregroundStyle(.secondary)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption)
                }
            }
            
            if expanded {
                ForEach(Array(ex.sets.enumerated()), id: \.offset) { i, set in
                    SetRow(
                        set: set, i: i,
                        historicalWeight: set.setTypeStr != "warmup" ? historicalData?.avgWeight : nil,
                        onToggle: { onToggleSet(set, SetType(rawValue: set.setTypeStr) ?? .normal) },
                        onRPETap: { onRPETap?(i) }
                    )
                    .onTapGesture { /* open detail */ }
                }
            }
        }
        .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Set Row View

struct SetRow: View {
    let set: PerformedSetM
    let i: Int
    let historicalWeight: Double?
    let onToggle: () -> Void
    let onRPETap: (() -> Void)?
    
    private var historicalIndicator: some View {
        Group {
            if let histWeight = historicalWeight, set.weight > 0 {
                let diff = set.weight - histWeight
                if diff > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 8))
                        Text("+\(Int(diff))")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundStyle(.green)
                } else if diff < 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 8))
                        Text("\(Int(diff))")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundStyle(.red)
                } else {
                    Text("=")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            let (ic, cl) = style(set.setTypeStr)
            Image(systemName: ic).font(.caption).foregroundStyle(cl).frame(width: 20)
            Text(" \(i + 1)").font(.subheadline).foregroundStyle(.secondary).frame(width: 44, alignment: .leading)
            
            // Weight column with historical indicator
            VStack(alignment: .leading, spacing: 0) {
                Text(set.weight > 0 ? "\(Int(set.weight))" : "-")
                    .font(.subheadline.monospacedDigit())
                historicalIndicator
            }
            .frame(width: 40, alignment: .leading)
            
            // Reps or time column
            if set.setTypeStr == "timed", let time = set.setTime {
                Text(formatTime(time)).font(.subheadline.monospacedDigit()).frame(width: 50, alignment: .leading)
            } else {
                Text(set.reps > 0 ? "\(set.reps)" : "-").font(.subheadline.monospacedDigit()).frame(width: 36, alignment: .leading)
            }
            
            Spacer()
            
            // RPE indicator
            if let onRPETap = onRPETap {
                InlineRPEDisplay(rpe: set.rpe, onTap: onRPETap)
            }
            
            Button(action: onToggle) {
                Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(set.isComplete ? .green : .secondary)
            }
        }
        .padding(.vertical, 8)
        .background(set.isComplete ? Color.green.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
    }
    
    func style(_ t: String) -> (String, Color) {
        switch t {
        case "warmup": ("sunrise", .orange)
        case "drop": ("arrow.down.circle", .red)
        case "failure": ("bolt.fill", .yellow)
        case "timed": ("clock.fill", .purple)
        default: ("dumbbell", .blue)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Exercise Picker

struct ExPicker: View {
    @Environment(\.dismiss) var dismiss
    @Query var exercises: [ExerciseM]
    @State var search = ""
    let onSelect: (String) -> Void
    
    var filtered: [ExerciseM] {
        search.isEmpty ? exercises.sorted { $0.name < $1.name } : exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search...", text: $search)
                }.padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12)).padding()
                List(filtered) { ex in
                    Button { onSelect(ex.id); dismiss() } label: {
                        VStack(alignment: .leading) { Text(ex.name).font(.headline); Text(ex.bodyPartStr).font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
            .navigationTitle("Add Exercise").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } } }
        }
    }
}

#Preview { ActiveWorkoutView(isActive: .constant(true), routine: nil) }