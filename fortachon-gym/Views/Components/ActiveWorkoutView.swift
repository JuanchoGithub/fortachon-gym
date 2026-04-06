import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Snapshot State for Reorder Save/Cancel

/// Captures the state of exercises for reorder undo.
struct SnapshotState {
    let exerciseOrder: [String]  // weId array in order
    let exercises: [(weId: String, exerciseId: String, supersetId: String?, sets: [(id: String, reps: Int, weight: Double, type: String)])]
    
    init(from session: WorkoutSessionM) {
        exerciseOrder = session.exercises.map { $0.weId }
        exercises = session.exercises.map { ex in
            (
                weId: ex.weId,
                exerciseId: ex.exerciseId,
                supersetId: ex.supersetId,
                sets: ex.sets.map { (id: $0.setId, reps: $0.reps, weight: $0.weight, type: $0.setTypeStr) }
            )
        }
    }
}

// MARK: - Minimized Workout Floating View

struct MinimizedWorkoutView: View {
    @Binding var isActive: Bool
    var routineName: String
    var elapsed: TimeInterval
    var onExpand: () -> Void
    var onFinish: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routineName)
                    .font(.headline)
                    .lineLimit(1)
                Text(elapsed.formattedAsWorkout)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Expand", systemImage: "arrow.up.left.and.arrow.down.right") {
                withAnimation(.spring()) {
                    onExpand()
                }
            }
            .buttonStyle(.bordered)
            Button("Finish", systemImage: "checkmark.circle.fill") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
    }
}

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ActiveWorkoutSession.self) private var globalSession
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
    @State private var showSupersetPlayer = false
    @State private var supersetPlayerId: String? = nil
    @State private var collapsedSupersetIds: Set<String> = []
    
    // P0 #1: Minimized state delegated to globalSession
    // Kept for backwards-compat with existing minimizeWorkout/expandWorkout calls
    @State private var isMinimized = false
    
    // Drag and drop
    @State private var isReorderMode = false
    
    // P0 #2: Scroll-to-active-set tracking
    @State private var scrollToExerciseId: String? = nil
    @State private var pendingReorderState: SnapshotState?
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
    // Historical sessions loaded from database (for real coach suggestions)
    @State private var loadedSessions: [WorkoutSessionM] = []
    @State private var showNotesEditor = false
    @State private var validationIssues: [ValidationIssue] = []
    @State private var showValidationErrors = false
    
    // Phase 3: Smart weight suggestion
    @State private var showWeightSuggestion = false
    @State private var weightSuggestion: (exerciseName: String, currentWeight: Double, suggestedWeight: Double, setIndex: Int, exerciseIndex: Int)? = nil

    // Coach suggestion system (Item 1 & 2)
    @State private var showCoachSuggestion = false
    @State private var coachSuggestionResult: CoachSuggestionResult?

    // Exercise upgrade/rollback (Item 3 & 4)
    @State private var showingUpgradeAlert: (exerciseWeId: String, targetExerciseId: String, targetName: String)? = nil
    @State private var exerciseUpgrades: [String: String] = [:] // exerciseWeId -> targetExerciseId
    @State private var showExercisePicker = false
    @State private var upgradePickerExerciseIndex: Int?

    // Query for routines (needed for coach suggestion)
    @Query private var allRoutines: [RoutineM]
    
    // RPE editing state
    @State private var showRPEEditor = false
    @State private var rpeEditingExerciseIndex: Int? = nil
    @State private var rpeEditingSetIndex: Int? = nil
    
    // Per-exercise rest time config
    @State private var showRestConfig = false
    @State private var restConfigExerciseIndex: Int? = nil
    
    // Per-exercise notes editing (web parity — inline notes per exercise)
    @State private var notesExerciseIndex: Int? = nil
    @State private var exerciseNoteText: String = ""
    @State private var showExerciseNoteEditor = false
    
    // Bodyweight input
    @State private var showBodyweightInput = false
    @State private var bodyweightInput: Double = 0
    @State private var bodyweightExerciseIndex: Int? = nil
    
    // Volume tracking
    @State private var exerciseVolumes: [String: Double] = [:]  // weId -> total volume
    
    // Insight banner with undo
    @State private var insightBannerState: InsightBannerState? = nil
    
    // Promotion banner (web parity)
    @State private var promotionBannerState: PromotionBannerState? = nil
    
    struct PromotionBannerState: Identifiable {
        let id = UUID()
        let exerciseIndex: Int
        let targetExerciseId: String
        let targetExerciseName: String
    }
    
    // Timed set start button
    @State private var showTimedSetStart = false
    @State private var timedSetExerciseIndex: Int? = nil
    @State private var timedSetCountdown: Int = 3
    
    // Active rest exercise tracking for inline overlay
    @State private var activeRestExerciseIndex: Int? = nil
    @State private var activeRestExerciseName: String = ""
    
    // Bodyweight storage
    @State private var storedBodyWeight: Double = 0
    
    // Set completion animation
    @State private var completedSetAnimation: Set<String> = []  // set IDs being animated
    
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
    
    // MARK: - Exercise Details State
    @State private var showExerciseDetails = false
    @State private var detailsExerciseDef: ExerciseM?
    
    // MARK: - ScrollView Proxy for P0 #2
    
    @ViewBuilder
    private func exerciseListWithScrollProxy(scrollViewProxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Group exercises by superset
                let groupedExercises = buildSupersetGroups()
                
                ForEach(Array(groupedExercises.enumerated()), id: \.offset) { groupIdx, group in
                   switch group {
                    case .superset(let superset, let exercises):
                        supersetGroupCard(superset: superset, exercises: exercises, groupIndex: groupIdx)
                    case .single(let exercise, let idx):
                        exerciseCardWithScrollID(for: exercise, at: idx, scrollID: exercise.weId)
                    }
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
            .onChange(of: scrollToExerciseId) { _, newID in
                if let id = newID {
                    withAnimation(.spring()) {
                        scrollViewProxy.scrollTo(id, anchor: UnitPoint(x: 0.5, y: 0.1))
                    }
                    self.scrollToExerciseId = nil
                }
            }
        }
    }
    
    var body: some View {
        if isMinimized {
            MinimizedWorkoutView(
                isActive: $isActive,
                routineName: session.routineName,
                elapsed: elapsed,
                onExpand: expandWorkout,
                onFinish: finishWorkoutFromMinimized
            )
            .frame(maxWidth: 400)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            mainWorkoutView
        }
    }
    
    @ViewBuilder
    private var mainWorkoutView: some View {
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
                            Text("\u{2022} \(completedCount)/\(totalCount) sets")
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
                    // Minimize button
                    Button("Minimize", systemImage: "arrow.down.left.and.arrow.up.right") {
                        minimizeWorkout()
                    }
                    // Reorder mode toggle with save/cancel
                    if !isReorderMode {
                        Button("Reorder", systemImage: "arrow.up.arrow.down") {
                            startReorderMode()
                        }
                    } else {
                        Button("Cancel", systemImage: "xmark") {
                            cancelReorder()
                        }
                        .tint(.red)
                        Button("Save", systemImage: "checkmark") {
                            saveReorder()
                        }
                        .tint(.green)
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
                        Image(systemName: session.notes.isEmpty ? "note.text.badge.plus" : "note.text")
                            .font(.title3)
                            .foregroundColor(session.notes.isEmpty ? .secondary : .blue)
                    }
                    // Coach suggest button (Item 2)
                    Button(action: { showCoachSuggestionSheet() }) {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundStyle(.purple)
                    }
                    // Finish button
                    Button("Finish") { validateAndFinish() }
                        .font(.headline).padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.green).foregroundStyle(.white).clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
            
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
                ScrollViewReader { proxy in
                    exerciseListWithScrollProxy(scrollViewProxy: proxy)
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
        // Exercise notes editor (per-exercise)
        .sheet(isPresented: $showExerciseNoteEditor) {
            NavigationStack {
                VStack {
                    Text("Notes for: \(exerciseNoteTitle)")
                        .font(.headline)
                        .padding()
                    TextEditor(text: $exerciseNoteText)
                        .padding()
                    Spacer()
                }
                .navigationTitle("Exercise Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showExerciseNoteEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveExerciseNotes() }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        // Validation errors modal (Item 5)
        .sheet(isPresented: $showValidationErrors) {
            ValidationErrorsModalView(
                issues: validationIssues,
                onContinueAnyway: { endWorkout() }
            )
        }

        // Coach suggestion modal (Item 2)
        .sheet(isPresented: $showCoachSuggestion) {
            if let result = coachSuggestionResult {
                CoachSuggestionModalView(
                    suggestion: result,
                    onAccept: { acceptCoachSuggestion(result) },
                    onAggressive: { acceptAggressiveSuggestion() }
                )
            }
        }
        // MARK: - Inline Rest Timer Overlay (P0: Replaces fullScreenCover with overlay)
        .overlay {
            if showRestTimer {
                InlineRestTimerOverlay(
                    timeRemaining: $restRemaining,
                    totalTime: restTotal,
                    exerciseName: activeRestExerciseName,
                    onSkip: { showRestTimer = false; activeRestExerciseIndex = nil },
                    onDismiss: { showRestTimer = false; activeRestExerciseIndex = nil }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showRestTimer)
            }
        }
        .sheet(isPresented: $showSupersetManager) {
            SupersetManagerViewWrapper(session: session)
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
        .fullScreenCover(isPresented: $showSupersetPlayer) {
            if let supersetId = supersetPlayerId {
                SupersetPlayerView(session: session, supersetId: supersetId)
            }
        }
        // Rest Config Sheet
        .sheet(isPresented: $showRestConfig) {
            if let exIdx = restConfigExerciseIndex, exIdx < session.exercises.count {
                let ex = session.exercises[exIdx]
                let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
                let exerciseName = exerciseDef?.name ?? ex.exerciseId
                RestConfigSheet(
                    exerciseName: exerciseName,
                    restNormal: ex.restNormal,
                    restWarmup: ex.restWarmup,
                    restDrop: ex.restDrop,
                    restTimed: ex.restTimed,
                    restEffort: ex.restEffort,
                    restFailure: ex.restFailure,
                    onSave: { newTimes in
                        ex.restNormal = newTimes.normal
                        ex.restWarmup = newTimes.warmup
                        ex.restDrop = newTimes.drop
                        ex.restTimed = newTimes.timed
                        ex.restEffort = newTimes.effort
                        ex.restFailure = newTimes.failure
                        showRestConfig = false
                        restConfigExerciseIndex = nil
                    }
                )
            }
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
            // Phase 3: Smart weight suggestion overlay
            if showWeightSuggestion, let suggestion = weightSuggestion {
                VStack {
                    SmartWeightSuggestionBanner(
                        exerciseName: suggestion.exerciseName,
                        currentWeight: suggestion.currentWeight,
                        suggestedWeight: suggestion.suggestedWeight,
                        onApply: {
                            applyWeightSuggestion(suggestion)
                        },
                        onDismiss: {
                            showWeightSuggestion = false
                            weightSuggestion = nil
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: showWeightSuggestion)
            }
            // Insight banner with undo (web parity)
            if let insight = insightBannerState {
                VStack {
                    InsightBannerView(
                        exerciseName: insight.exerciseName,
                        oldValue: insight.oldValue,
                        newValue: insight.newValue,
                        type: insight.isApplied ? .applied : (insight.newValue > insight.oldValue ? .increase : .decrease),
                        onApply: {
                            applyInsight(insight)
                        },
                        onUndo: {
                            undoInsight(insight)
                        },
                        onDismiss: {
                            insightBannerState = nil
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: insightBannerState?.id)
            }
            // Promotion banner (web parity)
            if let promo = promotionBannerState {
                VStack {
                    PromotionBannerView(
                        exerciseName: promo.targetExerciseName,
                        onUpgrade: {
                            upgradeExercise(at: promo.exerciseIndex, to: promo.targetExerciseId)
                            promotionBannerState = nil
                        },
                        onDismiss: {
                            promotionBannerState = nil
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: promotionBannerState?.id)
            }
        }
        // Exercise details sheet (web parity)
        .sheet(isPresented: $showExerciseDetails) {
            if let exerciseDef = detailsExerciseDef {
                ExerciseInfoSheet(exercise: exerciseDef, historicalData: historicalData[exerciseDef.id], useLocalizedNames: useLocalizedNames)
            }
        }
        // Validation errors alert removed - now uses ValidationErrorsModalView sheet
        .alert("Finish?", isPresented: $showFinishConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Finish", role: .destructive) { endWorkout() }
        }
        .onAppear {
            // P0 #1: Notify global session that a workout is active
            globalSession.start(routineName: session.routineName)
            
            // Start workout timer
            timerTask = Task { [start = session.startTime] in
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(1)) } catch { break }
                    if !Task.isCancelled {
                        await MainActor.run {
                            elapsed = Date().timeIntervalSince(start)
                            // Update global session for minimized bar display across tabs
                            globalSession.updateProgress(
                                completed: completedCount,
                                total: totalCount
                            )
                        }
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
            
            // P0 #1: Listen for notifications from global minimized bar
            NotificationCenter.default.addObserver(
                forName: .expandWorkoutFromMinimized,
                object: nil,
                queue: .main
            ) { _ in
                withAnimation(.spring()) {
                    globalSession.expand()
                    isMinimized = false
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .finishWorkoutFromMinimized,
                object: nil,
                queue: .main
            ) { _ in
                validateAndFinish()
            }
        }
        .onDisappear {
            timerTask?.cancel()
            NotificationCenter.default.removeObserver(self)
            // Don't end globalSession here — it should persist
            // until workout is actually finished (endWorkout called)
        }
    }
    
    // MARK: - Scroll-ID Exercise Card Builder (P0 #2)
    
    /// Exercise card with explicit .id() for ScrollViewReader targeting.
    @ViewBuilder
    private func exerciseCardWithScrollID(for ex: WorkoutExerciseM, at idx: Int, scrollID: String) -> some View {
        exerciseCard(for: ex, at: idx)
            .id(scrollID)
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
        let isCardio = ["Cardio", "Duration"].contains(exerciseDef?.categoryStr ?? "")
        
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
            let isWeightOptional = isCategoryWeightOptional(exerciseDef?.categoryStr ?? "")
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
                        // Log actual rest time from previous set
                        if let prevCompleted = ex.sets.last(where: { $0.isComplete && $0.setId != set.setId }) {
                            set.actualRestTime = Int(Date().timeIntervalSince(prevCompleted.completedAt ?? Date()))
                        }
                        let t = SetType(rawValue: set.setTypeStr) ?? .normal
                        restRemaining = TimeInterval(restFor(t))
                        restTotal = restRemaining
                        // P0: Track exercise name for inline overlay
                        activeRestExerciseIndex = idx
                        activeRestExerciseName = exerciseName(for: exerciseDef)
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
                        // Update volume tracking
                        updateVolume(for: ex)
                        // P0 #2: Scroll to exercise on set completion
                        scrollToExerciseId = ex.weId
                        // Phase 6: Auto-collapse when all sets complete
                        if ex.sets.allSatisfy({ $0.isComplete }) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                expandedIds.remove(ex.weId)
                            }
                        }
                        // Check weight suggestion after completion
                        checkWeightSuggestionAfterCompletion(exerciseIndex: idx, setIndex: ex.sets.firstIndex(where: { $0.setId == set.setId }) ?? 0)
                    } else {
                        set.completedAt = nil
                        set.actualRestTime = nil
                        // Re-expand if user unchecks a set
                        if !expandedIds.contains(ex.weId) {
                            expandedIds.insert(ex.weId)
                        }
                    }
                },
                historicalData: historicalData[ex.exerciseId],
                onRPETap: { setIndex in
                    rpeEditingExerciseIndex = idx
                    rpeEditingSetIndex = setIndex
                    showRPEEditor = true
                },
                // Phase 1: Inline editing callbacks
                onUpdateSetWeight: { setIndex, newWeight in
                    updateSetWeightWithCascade(exerciseIndex: idx, setIndex: setIndex, weight: newWeight)
                },
                onUpdateSetReps: { setIndex, newReps in
                    updateSetRepsWithCascade(exerciseIndex: idx, setIndex: setIndex, reps: newReps)
                },
                onUpdateSetTime: { setIndex, newTime in
                    ex.sets[setIndex].setTime = newTime
                },
                onUpdateSetType: { setIndex, newType in
                    ex.sets[setIndex].setTypeStr = newType.rawValue
                },
                onDeleteSet: { setIndex in
                    ex.sets.remove(at: setIndex)
                },
                isWeightOptional: isWeightOptional,
                exerciseCategory: exerciseDef?.categoryStr ?? "",
                canRollback: canRollback(at: idx),
                onRollback: { rollbackExercise(at: idx) },
                onRestConfig: {
                    restConfigExerciseIndex = idx
                    showRestConfig = true
                },
                onNotes: {
                    openExerciseNotes(at: idx)
                },
                volume: exerciseVolumes[ex.weId] ?? 0
            )
            
            if expandedIds.contains(ex.weId) {
                Button {
                    addSet(to: ex)
                } label: {
                    Label("Add Set", systemImage: "plus").frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Per-Exercise Notes (Web Parity)
    
    /// Get the exercise title for the notes editor
    private var exerciseNoteTitle: String {
        guard let idx = notesExerciseIndex, idx < session.exercises.count else { return "Exercise" }
        let ex = session.exercises[idx]
        let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
        return exerciseName(for: exerciseDef)
    }
    
    /// Open per-exercise notes editor
    private func openExerciseNotes(at index: Int) {
        guard index < session.exercises.count else { return }
        notesExerciseIndex = index
        exerciseNoteText = session.exercises[index].note ?? ""
        showExerciseNoteEditor = true
    }
    
    /// Save per-exercise notes
    private func saveExerciseNotes() {
        guard let idx = notesExerciseIndex, idx < session.exercises.count else { return }
        session.exercises[idx].note = exerciseNoteText.isEmpty ? nil : exerciseNoteText
        showExerciseNoteEditor = false
        notesExerciseIndex = nil
    }
    
    /// Check if exercise has existing notes indicator
    private func hasExerciseNotes(at index: Int) -> Bool {
        guard index < session.exercises.count else { return false }
        return !(session.exercises[index].note ?? "").isEmpty
    }
    
    // MARK: - Actions
    
    /// Add a new set with last-set values (Phase 4: last-set doubling for rest time)
    private func addSet(to ex: WorkoutExerciseM) {
        let last = ex.sets.last
        let lastWeight = last?.weight ?? 0
        let lastReps = last?.reps ?? 0
        let lastType = last?.setTypeStr ?? "normal"
        let newSet = PerformedSetM(
            id: "set-\(UUID())", reps: lastReps, weight: lastWeight,
            type: lastType
        )
        ex.sets.append(newSet)
        
        // Phase 4: If this is the last set and it's a normal set, double the rest time
        if lastType == "normal" {
            let baseRest = restFor(.normal)
            restRemaining = TimeInterval(baseRest * 2)
            restTotal = restRemaining
        }
    }
    
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
    
    // MARK: - Validation (Item 5)

    private func validateAndFinish() {
        let issues = detailedValidateWorkout()
        if issues.isEmpty {
            showFinishConfirmation = true
        } else {
            validationIssues = issues
            showValidationErrors = true
        }
    }

    /// Detailed validation returning structured issues (Phase 7: Web parity - per-set value validation)
    private func detailedValidateWorkout() -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        if session.exercises.isEmpty {
            issues.append(ValidationIssue(exerciseName: "Workout", issue: "No exercises added"))
        }
        for ex in session.exercises {
            let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
            let name = exerciseDef?.name ?? ex.exerciseId
            let isWeightOptional = isCategoryWeightOptional(exerciseDef?.categoryStr ?? "")
            let hasCompletedSets = ex.sets.contains { $0.isComplete }
            if !hasCompletedSets {
                issues.append(ValidationIssue(exerciseName: name, issue: "No completed sets"))
            }
            // Phase 7: Validate individual completed set values (web parity)
            for (setIdx, set) in ex.sets.enumerated() {
                guard set.isComplete else { continue }
                var setErrors: [String] = []
                if set.setTypeStr == "timed" {
                    if (set.setTime ?? 0) <= 0 {
                        setErrors.append("Set \(setIdx + 1): time must be > 0")
                    }
                    if set.reps <= 0 {
                        setErrors.append("Set \(setIdx + 1): reps must be > 0")
                    }
                } else {
                    if !isWeightOptional && set.weight <= 0 {
                        setErrors.append("Set \(setIdx + 1): weight must be > 0")
                    }
                    if set.reps <= 0 {
                        setErrors.append("Set \(setIdx + 1): reps must be > 0")
                    }
                }
                if !setErrors.isEmpty {
                    issues.append(ValidationIssue(exerciseName: name, issue: setErrors.joined(separator: ", ")))
                }
            }
        }
        return issues
    }

    // MARK: - Coach Suggestion (Items 1 & 2)
    
    private func showCoachSuggestionSheet() {
        let suggestion = CoachSuggestionEngine.generateSuggestion(
            sessions: loadedSessions,  // Use real sessions instead of empty array
            allExercises: allExercises,
            routines: allRoutines,
            prefs: prefs
        )

        guard let s = suggestion else { return }

        // Build a RoutineM from the suggestion
        let tempRoutine = RoutineM(id: "coach-\(UUID())", name: s.focusLabel, desc: s.description, isTemplate: false, type: "strength")
        for exData in s.exercises {
            let we = WorkoutExerciseM(id: "we-\(UUID())", exerciseId: exData.exerciseId)
            for setData in exData.sets {
                we.sets.append(PerformedSetM(id: "set-\(UUID())", reps: setData.reps, weight: setData.weight, type: setData.type))
            }
            tempRoutine.exercises.append(we)
        }

        coachSuggestionResult = CoachSuggestionResult(
            routine: Routine(from: tempRoutine),
            focusLabel: s.focusLabel,
            description: s.description,
            isFallback: s.isFallback
        )
        showCoachSuggestion = true
    }

    private func acceptCoachSuggestion(_ result: CoachSuggestionResult) {
        // Replace exercises with the suggested routine
        session.exercises.removeAll()
        // We need to rebuild from the Routine (FortachonCore) back to WorkoutExerciseM
        // Store original routine's sets
        for coreEx in result.routine.exercises {
            let we = WorkoutExerciseM(id: "we-\(UUID())", exerciseId: coreEx.exerciseId)
            for coreSet in coreEx.sets {
                we.sets.append(PerformedSetM(
                    id: "set-\(UUID())",
                    reps: coreSet.reps,
                    weight: coreSet.weight,
                    type: coreSet.type.rawValue
                ))
            }
            session.exercises.append(we)
        }
        // Reset expansion
        expandedIds.removeAll()
        if let first = session.exercises.first {
            expandedIds.insert(first.weId)
        }
        audioCoach.announceWorkoutStart(routineName: result.focusLabel)
    }

    private func acceptAggressiveSuggestion() {
        let suggestion = CoachSuggestionEngine.generateAggressiveSuggestion(
            sessions: loadedSessions,
            allExercises: allExercises,
            routines: allRoutines,
            prefs: prefs
        )

        session.exercises.removeAll()
        for exData in suggestion.exercises {
            let we = WorkoutExerciseM(id: "we-\(UUID())", exerciseId: exData.exerciseId)
            for setData in exData.sets {
                we.sets.append(PerformedSetM(id: "set-\(UUID())", reps: setData.reps, weight: setData.weight, type: setData.type))
            }
            session.exercises.append(we)
        }
        expandedIds.removeAll()
        if let first = session.exercises.first {
            expandedIds.insert(first.weId)
        }
        audioCoach.announceWorkoutStart(routineName: "\(suggestion.focusLabel) (Aggressive)")
    }

    // MARK: - Exercise Upgrade & Rollback (Items 3 & 4)

    /// Check if an exercise has available upgrades
    private func availableUpgrade(for exerciseId: String) -> (targetId: String, targetName: String)? {
        let upgradePaths: [String: (String, String)] = [
            "ex-1": ("ex-2", "Dumbbell Bench Press"),  // Bench -> harder variant
            "ex-4": ("ex-26", "Incline Bench Press"),   // OHP -> Incline
            "ex-5": ("ex-10", "Weighted Pull-ups"),     // Rows -> Pull-ups
        ]
        return upgradePaths[exerciseId]
    }

    /// Upgrade an exercise to a harder variant with smart starting weight.
    /// Stores previous state for rollback support.
    private func upgradeExercise(at index: Int, to targetId: String) {
        upgradeExerciseWithSmartWeight(at: index, to: targetId)
    }

    /// Rollback an exercise to its previous version
    private func rollbackExercise(at index: Int) {
        guard index < session.exercises.count else { return }
        let ex = session.exercises[index]

        guard let prevId = ex.prevExerciseId else { return }

        // Restore exercise ID
        ex.exerciseId = prevId
        ex.note = ex.prevNote

        // Restore sets from JSON
        if let prevJson = ex.prevSetsJson,
           let data = prevJson.data(using: .utf8),
           let setsArray = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
            ex.sets.removeAll()
            for setDict in setsArray {
                let reps = Int(setDict["reps"] ?? "0") ?? 0
                let weight = Double(setDict["weight"] ?? "0") ?? 0
                let type = setDict["type"] ?? "normal"
                ex.sets.append(PerformedSetM(
                    id: "set-\(UUID())",
                    reps: reps,
                    weight: weight,
                    type: type
                ))
            }
        }

        // Clear previous state
        ex.prevExerciseId = nil
        ex.prevSetsJson = nil
        ex.prevNote = nil
    }

    /// Check if an exercise can be rolled back
    private func canRollback(at index: Int) -> Bool {
        guard index < session.exercises.count else { return false }
        return session.exercises[index].prevExerciseId != nil
    }
    
    // MARK: - Reorder Save/Cancel
    
    /// Start reorder mode - capture current state for undo.
    private func startReorderMode() {
        pendingReorderState = SnapshotState(from: session)
        isReorderMode = true
    }
    
    // MARK: - Superset-Aware Reorder
    
    /// Check if exercises at given indices belong to the same superset
    private func exercisesBelongToSameSuperset(_ indices: [Int]) -> Bool {
        guard !indices.isEmpty else { return false }
        let firstSupersetId = session.exercises[indices[0]].supersetId
        return indices.allSatisfy { idx in
            session.exercises[idx].supersetId == firstSupersetId
        }
    }
    
    /// Save reorder - clear pending state.
    private func saveReorder() {
        pendingReorderState = nil
        isReorderMode = false
    }
    
    /// Cancel reorder - restore snapshot.
    private func cancelReorder() {
        guard let snapshot = pendingReorderState else {
            isReorderMode = false
            return
        }
        
        // Restore exercise order
        var restoredExercises: [WorkoutExerciseM] = []
        for weId in snapshot.exerciseOrder {
            if let ex = session.exercises.first(where: { $0.weId == weId }) {
                restoredExercises.append(ex)
            }
        }
        // Add any exercises not in the snapshot (newly added during workout)
        for ex in session.exercises where !snapshot.exerciseOrder.contains(ex.weId) {
            restoredExercises.append(ex)
        }
        
        session.exercises = restoredExercises
        pendingReorderState = nil
        isReorderMode = false
    }
    
    // MARK: - Minimize Workout (P0 #1: Sync with global session)
    
    /// Minimize the workout view - allows user to browse app while workout runs.
    private func minimizeWorkout() {
        withAnimation(.spring()) {
            isMinimized = true
            globalSession.minimize()
        }
    }
    
    /// Expand the minimized workout view.
    private func expandWorkout() {
        withAnimation(.spring()) {
            isMinimized = false
            globalSession.expand()
        }
    }
    
    /// End the workout from minimized state.
    private func finishWorkoutFromMinimized() {
        withAnimation(.spring()) {
            isMinimized = false
        }
        validateAndFinish()
    }
    
    // MARK: - Superset Management from Workout
    
    /// Join an exercise to an existing superset.
    private func joinExerciseToSuperset(exerciseIndex: Int, supersetId: String) {
        guard exerciseIndex < session.exercises.count else { return }
        let ex = session.exercises[exerciseIndex]
        ex.supersetId = supersetId
        
        // Create superset definition if it doesn't exist
        if session.supersets.first(where: { $0.ssId == supersetId }) == nil {
            let ss = SupersetM(id: supersetId, name: "Superset \(session.supersets.count + 1)")
            session.supersets.append(ss)
        }
    }
    
    /// Ungroup a superset - return all exercises to standalone.
    private func ungroupSuperset(supersetId: String) {
        for ex in session.exercises where ex.supersetId == supersetId {
            ex.supersetId = nil
        }
        session.supersets.removeAll { $0.ssId == supersetId }
        collapsedSupersetIds.remove(supersetId)
    }
    
    /// Rename a superset.
    private func renameSuperset(supersetId: String, newName: String) {
        if let ss = session.supersets.first(where: { $0.ssId == supersetId }) {
            ss.name = newName
        }
    }
    
    // MARK: - Exercise Details View
    
    /// Get exercise definition for display.
    private func getExerciseDef(for exerciseId: String) -> ExerciseM? {
        let exerciseDef = allExercises.first { $0.id == exerciseId }
        return exerciseDef
    }
    
    // MARK: - Smart Weight for Exercise Upgrade
    
    /// Upgrade an exercise with smart weight calculation (matches web's getSmartStartingWeight).
    private func upgradeExerciseWithSmartWeight(at index: Int, to targetId: String) {
        guard index < session.exercises.count else { return }
        let ex = session.exercises[index]
        let targetDef = allExercises.first { $0.id == targetId }
        
        // Store current state for rollback
        ex.prevExerciseId = ex.exerciseId
        ex.prevNote = ex.note
        
        // Encode current sets as JSON for restoration
        let setsData = ex.sets.map { set in
            [
                "id": set.setId,
                "reps": "\(set.reps)",
                "weight": "\(set.weight)",
                "type": set.setTypeStr
            ]
        }
        if let json = try? JSONSerialization.data(withJSONObject: setsData),
           let jsonStr = String(data: json, encoding: .utf8) {
            ex.prevSetsJson = jsonStr
        }
        
        // Perform the upgrade
        ex.exerciseId = targetId
        
        // Calculate smart starting weight using HistoricalLookup
        let lookup = HistoricalLookup(modelContext: modelContext)
        let smartWeight: Double = {
            if let hist = lookup.getLastSessionValues(for: targetId) {
                return hist.avgWeight
            }
            // Fallback to bar weight
            return 20.0
        }()
        
        // Suppress unused variable warning for targetDef
        _ = targetDef
        
        // Reset sets with smart weight
        ex.sets.removeAll()
        ex.sets.append(PerformedSetM(id: "set-\(UUID())", reps: 0, weight: 0, type: "warmup"))
        for _ in 0..<3 {
            ex.sets.append(PerformedSetM(id: "set-\(UUID())", reps: 8, weight: smartWeight, type: "normal"))
        }
        
        // Log exercise unlock for analytics
        logExerciseUnlock(from: ex.prevExerciseId, to: targetId)
        
        expandedIds.insert(ex.weId)
    }
    
    /// Log exercise unlock/upgrade for analytics.
    private func logExerciseUnlock(from: String?, to targetId: String) {
        guard let fromId = from else { return }
        let fromDef = getExerciseDef(for: fromId)
        let toDef = getExerciseDef(for: targetId)
        // Could store in analytics or user preferences for tracking
        print("Exercise upgrade logged: \(fromDef?.name ?? fromId) → \(toDef?.name ?? targetId)")
    }
    
    private func endWorkout() {
        session.endTime = Date()
        modelContext.insert(session)
        try? modelContext.save()
        isActive = false
        
        // P0 #1: End the global session (removes minimized bar)
        globalSession.end()
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
        
        // Load recent sessions for coach suggestion engine
        loadedSessions = lookup.getRecentSessions(limit: 30)
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
        
        // Check for auto-triggering weight suggestions on expand
        checkAutoWeightSuggestions()
    }
    
    /// Auto-trigger smart weight suggestion based on performance trends
    private func checkAutoWeightSuggestions() {
        for (exIdx, ex) in session.exercises.enumerated() {
            // Get first uncompleted normal set
            guard let firstUncompleted = ex.sets.first(where: { !$0.isComplete && $0.setTypeStr == "normal" }),
                  let hist = historicalData[ex.exerciseId],
                  let exerciseDef = allExercises.first(where: { $0.id == ex.exerciseId })
            else { continue }
            
            let suggestion = hist.avgWeight
            if suggestion > 0 && abs(suggestion - firstUncompleted.weight) >= 2.5 {
                let exerciseName = exerciseDef.displayName(useSpanish: useLocalizedNames)
                weightSuggestion = (
                    exerciseName: exerciseName,
                    currentWeight: firstUncompleted.weight,
                    suggestedWeight: suggestion,
                    setIndex: ex.sets.firstIndex(where: { $0.setId == firstUncompleted.setId }) ?? 0,
                    exerciseIndex: exIdx
                )
                showWeightSuggestion = true
                return // Show one at a time
            }
        }
    }
    
    /// Check weight suggestion when completing a set (auto-trigger)
    private func checkWeightSuggestionAfterCompletion(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        
        let ex = session.exercises[exerciseIndex]
        let set = ex.sets[setIndex]
        let exerciseDef = allExercises.first { $0.id == ex.exerciseId }
        let exerciseName = exerciseDef?.name ?? ex.exerciseId
        
        // Get historical data
        guard let hist = historicalData[ex.exerciseId] else { return }
        
        // If current weight is same as historical and reps are higher, suggest increase
        if set.weight == hist.avgWeight && set.reps > hist.avgReps + 2 && set.reps >= 10 {
            let suggestedIncrease: Double = set.weight >= 100 ? 5 : 2.5
            weightSuggestion = (
                exerciseName: exerciseName,
                currentWeight: set.weight,
                suggestedWeight: set.weight + suggestedIncrease,
                setIndex: setIndex,
                exerciseIndex: exerciseIndex
            )
            showWeightSuggestion = true
        }
    }
    
    /// Check for available promotion for an exercise (web parity)
    private func checkAvailablePromotion(for exerciseId: String) -> (targetId: String, targetName: String)? {
        let upgradePaths: [String: (String, String)] = [
            "ex-1": ("ex-2", "Dumbbell Bench Press"),
            "ex-4": ("ex-26", "Incline Bench Press"),
            "ex-5": ("ex-10", "Weighted Pull-ups"),
        ]
        // Check if user has history with this exercise
        let hist = historicalData[exerciseId]
        if hist != nil, let upgrade = upgradePaths[exerciseId] {
            return upgrade
        }
        return nil
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
    
    // MARK: - Phase 1: Weight/Reps Inheritance Cascade (Web parity)
    
    /// Update set weight with cascade to subsequent inherited sets (matches web behavior)
    private func updateSetWeightWithCascade(exerciseIndex: Int, setIndex: Int, weight: Double) {
        guard exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        
        let ex = session.exercises[exerciseIndex]
        let oldWeight = ex.sets[setIndex].weight
        ex.sets[setIndex].weight = weight
        
        // Break inheritance if value changed
        if weight != oldWeight {
            ex.sets[setIndex].isWeightInherited = false
        }
        
        // Cascade to subsequent sets that have inheritance enabled
        if weight != oldWeight {
            for i in (setIndex + 1)..<ex.sets.count {
                let currentSet = ex.sets[i]
                if currentSet.isComplete || !currentSet.isWeightInherited { break }
                if currentSet.setTypeStr == ex.sets[setIndex].setTypeStr {
                    ex.sets[i].weight = weight
                }
            }
        }
    }
    
    /// Update set reps with cascade to subsequent inherited sets (matches web behavior)
    private func updateSetRepsWithCascade(exerciseIndex: Int, setIndex: Int, reps: Int) {
        guard exerciseIndex < session.exercises.count,
              setIndex < session.exercises[exerciseIndex].sets.count else { return }
        
        let ex = session.exercises[exerciseIndex]
        let oldReps = ex.sets[setIndex].reps
        ex.sets[setIndex].reps = reps
        
        // Break inheritance if value changed
        if reps != oldReps {
            ex.sets[setIndex].isRepsInherited = false
        }
        
        // Cascade to subsequent sets that have inheritance enabled
        if reps != oldReps {
            for i in (setIndex + 1)..<ex.sets.count {
                let currentSet = ex.sets[i]
                if currentSet.isComplete || !currentSet.isRepsInherited { break }
                if currentSet.setTypeStr == ex.sets[setIndex].setTypeStr {
                    ex.sets[i].reps = reps
                }
            }
        }
    }
    
    /// Check if an exercise category doesn't require weight input (web parity)
    private func isCategoryWeightOptional(_ category: String) -> Bool {
        return ["Reps Only", "Cardio", "Duration", "Bodyweight", "Assisted Bodyweight", "Plyometrics"].contains(category)
    }
    
    // MARK: - Volume Tracking
    
    /// Calculate and update total volume for an exercise
    private func updateVolume(for ex: WorkoutExerciseM) {
        var totalVolume: Double = 0
        for set in ex.sets where set.isComplete && set.setTypeStr != "warmup" {
            totalVolume += set.weight * Double(set.reps)
        }
        exerciseVolumes[ex.weId] = totalVolume
    }
    
    // MARK: - Insight Banner with Undo (web parity)
    
    /// Apply an insight suggestion
    private func applyInsight(_ insight: InsightBannerState) {
        guard insight.exerciseIndex < session.exercises.count,
              insight.setIndex < session.exercises[insight.exerciseIndex].sets.count else { return }
        
        let ex = session.exercises[insight.exerciseIndex]
        let set = ex.sets[insight.setIndex]
        
        // Store old value for undo
        let oldValue = set.weight
        set.weight = insight.newValue
        set.isWeightInherited = false
        
        // Cascade to subsequent sets
        for i in (insight.setIndex + 1)..<ex.sets.count {
            if ex.sets[i].isComplete || !ex.sets[i].isWeightInherited { break }
            ex.sets[i].weight = insight.newValue
        }
        
        // Update banner to applied state
        insightBannerState = InsightBannerState(
            exerciseIndex: insight.exerciseIndex,
            setIndex: insight.setIndex,
            exerciseName: insight.exerciseName,
            oldValue: oldValue,
            newValue: insight.newValue,
            type: .applied,
            isApplied: true
        )
    }
    
    /// Undo an insight application
    private func undoInsight(_ insight: InsightBannerState) {
        guard insight.exerciseIndex < session.exercises.count,
              insight.setIndex < session.exercises[insight.exerciseIndex].sets.count else { return }
        
        let ex = session.exercises[insight.exerciseIndex]
        let set = ex.sets[insight.setIndex]
        
        // Restore old value
        set.weight = insight.oldValue
        set.isWeightInherited = false
        
        insightBannerState = nil
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
    let onRPETap: ((Int) -> Void)?
    // Phase 1: Inline editing callbacks
    let onUpdateSetWeight: (Int, Double) -> Void       // (setIndex, weight)
    let onUpdateSetReps: (Int, Int) -> Void            // (setIndex, reps)
    let onUpdateSetTime: (Int, Int) -> Void            // (setIndex, seconds)
    let onUpdateSetType: (Int, SetType) -> Void        // (setIndex, type)
    let onDeleteSet: (Int) -> Void                     // (setIndex)
    let isWeightOptional: Bool
    let exerciseCategory: String
    // Phase 8: Rollback support
    let canRollback: Bool
    let onRollback: () -> Void
    // Rest config
    let onRestConfig: () -> Void
    // Per-exercise notes
    let onNotes: () -> Void
    // Volume tracking
    let volume: Double
    
    @State private var showSetTypePicker: SetTypePickerContext? = nil
    
    // P2: Bodyweight input for bodyweight exercises
    @State private var showBodyweightInput = false
    @State private var localBodyweight: Double = 0
    
    struct SetTypePickerContext: Identifiable {
        let id = UUID()
        let setIndex: Int
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggleExpand) {
                HStack {
                    Text("\(idx + 1). \(exerciseName)").font(.headline).lineLimit(1)
                    Spacer()
                    // Notes indicator
                    if hasNotes {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    // Volume tracking display
                    if volume > 0 {
                        Text("\(Int(volume))kg")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.blue)
                    }
                    let done = ex.sets.filter { $0.isComplete }.count
                    Text("\(done)/\(ex.sets.count)").font(.caption).foregroundStyle(.secondary)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption)
                }
            }
            
            if expanded {
                // Phase 8: Rollback banner (web parity)
                if showRollbackButton {
                    rollbackBanner
                }
                
                // HStack for Rest Config and Notes buttons
                HStack(spacing: 8) {
                    restConfigButton
                    notesButton
                    // P2: Bodyweight input button for bodyweight exercises
                    if isBodyweightCategory || isAssistedCategory {
                        bodyweightButton
                    }
                }
                
                // P2: Bodyweight indicator
                if (isBodyweightCategory || isAssistedCategory) && localBodyweight > 0 {
                    bodyweightIndicator
                }
                
                // Column headers
                setColumnHeaders
                
                ForEach(Array(ex.sets.enumerated()), id: \.offset) { i, set in
                    // Get previous set data for this set
                    let prevData: (weight: Double, reps: Int)? = i > 0 ? (ex.sets[i-1].weight, ex.sets[i-1].reps) : nil
                    // Calculate actual rest time for this completed set
                    let actualRest: Int? = set.isComplete ? (set.actualRestTime ?? nil) : nil
                    SetRow(
                        set: set,
                        i: i,
                        historicalWeight: set.setTypeStr != "warmup" ? historicalData?.avgWeight : nil,
                        onToggle: { onToggleSet(set, SetType(rawValue: set.setTypeStr) ?? .normal) },
                        onRPETap: { onRPETap?(i) },
                        onUpdateWeight: { onUpdateSetWeight(i, $0) },
                        onUpdateReps: { onUpdateSetReps(i, $0) },
                        updateTime: { onUpdateSetTime(i, $0) },
                        onShowTypePicker: { showSetTypePicker = SetTypePickerContext(setIndex: i) },
                        onDeleteSet: { onDeleteSet(i) },
                        isWeightOptional: isWeightOptional,
                        exerciseCategory: exerciseCategory,
                        previousSetData: prevData,
                        actualRestSeconds: actualRest,
                        isWeightInherited: set.isWeightInherited,
                        isRepsInherited: set.isRepsInherited
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(item: $showSetTypePicker) { context in
            SetTypePickerSheet(
                currentType: SetType(rawValue: ex.sets[context.setIndex].setTypeStr) ?? .normal,
                onSelect: { newType in
                    onUpdateSetType(context.setIndex, newType)
                    showSetTypePicker = nil
                },
                onDelete: {
                    onDeleteSet(context.setIndex)
                    showSetTypePicker = nil
                },
                canDelete: ex.sets.count > 1
            )
        }
    }
    
    private var hasNotes: Bool {
        !(ex.note ?? "").isEmpty
    }
    
    private var setColumnHeaders: some View {
        HStack(spacing: 10) {
            Text("").frame(width: 20)
            Text("Set").font(.caption).fontWeight(.bold).foregroundStyle(.secondary).frame(width: 44, alignment: .leading)
            // Phase 9: Previous set data column (web parity)
            Text("Prev").font(.caption).fontWeight(.bold).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
            // Phase 2: Bodyweight context in column header
            if isBodyweightCategory {
                Text("Extra").font(.caption).fontWeight(.bold).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
            } else if isAssistedCategory {
                Text("Assist").font(.caption).fontWeight(.bold).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
            } else {
                Text("kg").font(.caption).fontWeight(.bold).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
            }
            Text("Reps").font(.caption).fontWeight(.bold).foregroundStyle(.secondary).frame(width: 36, alignment: .leading)
            Spacer()
            Text("").frame(width: 40)
        }
        .padding(.horizontal, 4)
    }
    
    // Phase 2: Bodyweight exercise detection
    private var isBodyweightCategory: Bool {
        exerciseCategory == "Bodyweight" || exerciseCategory == "Plyometrics"
    }
    
    private var isAssistedCategory: Bool {
        exerciseCategory == "Assisted Bodyweight"
    }
    
    // Phase 8: Rollback banner (web parity)
    private var showRollbackButton: Bool {
        canRollback
    }
    
    private var rollbackBanner: some View {
        HStack {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundStyle(.secondary)
            Text("Rollback to previous exercise")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Rollback") {
                onRollback()
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var restConfigButton: some View {
        Button(action: onRestConfig) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.secondary)
                Text("Rest Times")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatRestTime(ex.restNormal))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var notesButton: some View {
        Button(action: onNotes) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(hasNotes ? .yellow : .secondary)
                Text(hasNotes ? "Edit Notes" : "Add Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    // MARK: - Bodyweight Components
    
    private var bodyweightButton: some View {
        Button(action: { showBodyweightInput = true }) {
            HStack {
                Image(systemName: "person.text.rectangle")
                    .foregroundStyle(localBodyweight > 0 ? .blue : .secondary)
                Text(localBodyweight > 0 ? "Edit BW" : "Set BW")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $showBodyweightInput) {
            BodyweightInputSheet(
                exerciseName: exerciseName,
                isAssisted: isAssistedCategory,
                onSave: { weight in
                    localBodyweight = weight
                }
            )
        }
    }
    
    private var bodyweightIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.fill")
                .font(.caption)
                .foregroundStyle(.blue)
            Text("Bodyweight: \(formatWeight(localBodyweight)) kg")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.blue)
            if isBodyweightCategory {
                Text("(+ extra = total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if isAssistedCategory {
                Text("(- assist = total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
    }
    
    private func formatWeight(_ w: Double) -> String {
        w == floor(w) ? "\(Int(w))" : String(format: "%.1f", w)
    }
}

// MARK: - Set Type Picker Sheet

struct SetTypePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let currentType: SetType
    let onSelect: (SetType) -> Void
    let onDelete: () -> Void
    let canDelete: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section("Set Type") {
                    ForEach(SetType.allCases, id: \.self) { type in
                        Button {
                            onSelect(type)
                        } label: {
                            HStack {
                                let (icon, color) = typeStyle(type)
                                Image(systemName: icon).foregroundStyle(color).frame(width: 24)
                                Text(type.displayName)
                                Spacer()
                                if type == currentType {
                                    Image(systemName: "checkmark").foregroundStyle(.accent)
                                }
                            }
                        }
                    }
                }
                
                if canDelete {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Set", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Set Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func typeStyle(_ type: SetType) -> (String, Color) {
        switch type {
        case .warmup: ("sunrise", .orange)
        case .drop: ("arrow.down.circle", .red)
        case .failure: ("bolt.fill", .yellow)
        case .timed: ("clock.fill", .purple)
        default: ("dumbbell", .blue)
        }
    }
}

// MARK: - Set Row View (Phase 1: Inline Editing)

struct SetRow: View {
    let set: PerformedSetM
    let i: Int
    let historicalWeight: Double?
    let onToggle: () -> Void
    let onRPETap: (() -> Void)?
    // Phase 1: Inline editing callbacks
    let onUpdateWeight: (Double) -> Void
    let onUpdateReps: (Int) -> Void
    let updateTime: (Int) -> Void
    let onShowTypePicker: () -> Void
    let onDeleteSet: () -> Void
    let isWeightOptional: Bool
    let exerciseCategory: String
    // Phase 9: Previous set data
    let previousSetData: (weight: Double, reps: Int)?
    // Inline rest display (web parity) — actual rest time from previous completed set
    let actualRestSeconds: Int?
    // Visual inheritance indicators — dim inherited values
    let isWeightInherited: Bool
    let isRepsInherited: Bool
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var timeText: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case weight(Int)
        case reps(Int)
        case time(Int)
    }
    
    init(
        set: PerformedSetM,
        i: Int,
        historicalWeight: Double?,
        onToggle: @escaping () -> Void,
        onRPETap: (() -> Void)?,
        onUpdateWeight: @escaping (Double) -> Void,
        onUpdateReps: @escaping (Int) -> Void,
        updateTime: @escaping (Int) -> Void,
        onShowTypePicker: @escaping () -> Void,
        onDeleteSet: @escaping () -> Void,
        isWeightOptional: Bool,
        exerciseCategory: String,
        previousSetData: (weight: Double, reps: Int)? = nil,
        actualRestSeconds: Int? = nil,
        isWeightInherited: Bool = false,
        isRepsInherited: Bool = false
    ) {
        self.set = set
        self.i = i
        self.historicalWeight = historicalWeight
        self.onToggle = onToggle
        self.onRPETap = onRPETap
        self.onUpdateWeight = onUpdateWeight
        self.onUpdateReps = onUpdateReps
        self.updateTime = updateTime
        self.onShowTypePicker = onShowTypePicker
        self.onDeleteSet = onDeleteSet
        self.isWeightOptional = isWeightOptional
        self.exerciseCategory = exerciseCategory
        self.previousSetData = previousSetData
        self.actualRestSeconds = actualRestSeconds
        self.isWeightInherited = isWeightInherited
        self.isRepsInherited = isRepsInherited
        
        // Initialize local state
        _weightText = State(initialValue: set.weight > 0 ? formatWeight(set.weight) : "")
        _repsText = State(initialValue: set.reps > 0 ? "\(set.reps)" : "")
        _timeText = State(initialValue: formatTime(set.setTime ?? 0))
    }
    
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
    
    private var isValid: Bool {
        guard set.isComplete else { return true }
        if set.setTypeStr == "timed" {
            return (set.setTime ?? 0) > 0 && set.reps > 0
        } else {
            if !isWeightOptional && set.weight <= 0 { return false }
            if set.reps <= 0 { return false }
        }
        return true
    }
    
    // Phase 9: Previous set data display (web parity)
    private var previousSetDataDisplay: some View {
        Group {
            if let prev = previousSetData {
                if set.setTypeStr == "timed" {
                    Text("-")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(formatWeight(prev.weight))\u{00D7}\(prev.reps)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("-")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 50, alignment: .leading)
    }
    
    // Inheritance visual indicator — slightly dim inherited values
    private var weightForeground: Color {
        if set.isComplete && !isValid {
            return .red
        } else if set.isComplete {
            return .green
        } else if isWeightInherited {
            return .secondary.opacity(0.6)
        }
        return inputTextColor
    }
    
    private var repsForeground: Color {
        if set.isComplete && !isValid {
            return .red
        } else if set.isComplete {
            return .green
        } else if isRepsInherited {
            return .secondary.opacity(0.6)
        }
        return inputTextColor
    }
    
    // P0 #3: Track blur to commit changes even when user doesn't press Return
    
    var body: some View {
        HStack(spacing: 10) {
            // Set type button (tap to change)
            Button(action: onShowTypePicker) {
                let (ic, cl) = style(set.setTypeStr)
                Image(systemName: ic)
                    .font(.caption)
                    .foregroundStyle(cl)
                    .frame(width: 20)
            }
            
            // Set number
            Text("\(i + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
            
            // Phase 9: Previous set data column (web parity)
            previousSetDataDisplay
            
            // Weight column with inline editing
            if set.setTypeStr != "timed" {
                VStack(alignment: .leading, spacing: 0) {
                    TextField(
                        "-",
                        text: Binding(
                            get: { weightText },
                            set: { weightText = $0 }
                        )
                    )
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .weight(i))
                    .onSubmit { commitWeight() }
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 40)
                    .disabled(set.isComplete)
                    .foregroundStyle(weightForeground)
                    historicalIndicator
                }
                .frame(width: 40, alignment: .leading)
                
                // Reps column with inline editing
                TextField(
                    "-",
                    text: Binding(
                        get: { repsText },
                        set: { repsText = $0 }
                    )
                )
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .reps(i))
                .onSubmit { commitReps() }
                .font(.subheadline.monospacedDigit())
                .frame(width: 36)
                .disabled(set.isComplete)
                .foregroundStyle(repsForeground)
            } else {
                // Timed set: show time and reps
                TextField(
                    "0:00",
                    text: Binding(
                        get: { timeText },
                        set: { timeText = $0 }
                    )
                )
                .keyboardType(.numbersAndPunctuation)
                .focused($focusedField, equals: .time(i))
                .onSubmit { commitTime() }
                .font(.subheadline.monospacedDigit())
                .frame(width: 50)
                .disabled(set.isComplete)
                .foregroundStyle(inputTextColor)
                
                TextField(
                    "-",
                    text: Binding(
                        get: { repsText },
                        set: { repsText = $0 }
                    )
                )
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .reps(i))
                .onSubmit { commitReps() }
                .font(.subheadline.monospacedDigit())
                .frame(width: 36)
                .disabled(set.isComplete)
                .foregroundStyle(inputTextColor)
            }
            
            Spacer()
            
            // RPE indicator
            if let onRPETap = onRPETap {
                InlineRPEDisplay(rpe: set.rpe, onTap: onRPETap)
            }
            
            // Complete button
            Button(action: onToggle) {
                Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(completeButtonColor)
            }
        }
        .onChange(of: focusedField) { _, newFocus in
            // Commit any field that just lost focus (P0 #3: Blur-to-commit)
            if let prev = focusedField, prev != newFocus {
                switch prev {
                case .weight:
                    commitWeight()
                case .reps:
                    commitReps()
                case .time:
                    commitTime()
                }
            }
        }
        .padding(.vertical, 8)
        .background(setBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
        // Inline actual rest time display below completed set (web parity)
        .overlay(alignment: .bottom) {
            if let restSec = actualRestSeconds, restSec > 0, set.isComplete {
                Text("\(restSec / 60):\(String(format: "%02d", restSec % 60)) rest")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
                    .offset(y: 4)
            }
        }
        .onAppear { syncTextFromSet() }
    }
    
    // MARK: - Input Styling
    
    private var inputTextColor: Color {
        if set.isComplete && !isValid {
            return .red
        } else if set.isComplete {
            return .green
        }
        return .primary
    }
    
    private var completeButtonColor: Color {
        if set.isComplete && !isValid {
            return .red
        } else if set.isComplete {
            return .green
        }
        return .secondary
    }
    
    private var setBackgroundColor: Color {
        if set.isComplete && !isValid {
            return Color.red.opacity(0.1)
        } else if set.isComplete {
            return Color.green.opacity(0.1)
        }
        return .clear
    }
    
    // MARK: - Commit Logic (P0 #3: Blur-to-commit matching web behavior)
    // Web uses onFocus/blur state to track focus and commit on blur.
    // iOS matches this via @FocusState + onChange(of: focusedField).
    
    /// Commit weight for a specific set index, even if not the current focused field.
    private func commitWeightForIndex(_ idx: Int) {
        guard set.setTypeStr != "timed" else { return }
        let parsed = Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        if parsed != set.weight {
            onUpdateWeight(parsed)
        }
    }
    
    /// Commit reps for a specific set index.
    private func commitRepsForIndex(_ idx: Int) {
        let parsed = Int(repsText) ?? 0
        if parsed != set.reps {
            onUpdateReps(parsed)
        }
    }
    
    /// Commit time for a specific set index.
    private func commitTimeForIndex(_ idx: Int) {
        guard set.setTypeStr == "timed" else { return }
        let seconds = parseTimeInput(timeText)
        if seconds != set.setTime {
            updateTime(seconds)
        }
    }
    
    // MARK: - Commit Logic (Web parity: blur-to-commit)
    
    private func commitWeight() {
        let parsed = Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        if parsed != set.weight {
            onUpdateWeight(parsed)
        } else {
            // Sync back in case of formatting differences
            syncTextFromSet()
        }
    }
    
    private func commitReps() {
        let parsed = Int(repsText) ?? 0
        if parsed != set.reps {
            onUpdateReps(parsed)
        } else {
            syncTextFromSet()
        }
    }
    
    private func commitTime() {
        let seconds = parseTimeInput(timeText)
        if seconds != set.setTime {
            updateTime(seconds)
        } else {
            syncTextFromSet()
        }
    }
    
    private func syncTextFromSet() {
        if set.setTypeStr != "timed" {
            weightText = set.weight > 0 ? formatWeight(set.weight) : ""
        }
        repsText = set.reps > 0 ? "\(set.reps)" : ""
        if set.setTypeStr == "timed" {
            timeText = formatTime(set.setTime ?? 0)
        }
    }
    
    private func formatWeight(_ w: Double) -> String {
        if w == floor(w) {
            return "\(Int(w))"
        }
        return String(format: "%.1f", w)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func parseTimeInput(_ input: String) -> Int {
        let components = input.split(separator: ":")
        if components.count == 2 {
            let mins = Int(components[0]) ?? 0
            let secs = Int(components[1]) ?? 0
            return mins * 60 + secs
        }
        return Int(input) ?? 0
    }
    
    private func style(_ t: String) -> (String, Color) {
        switch t {
        case "warmup": ("sunrise", .orange)
        case "drop": ("arrow.down.circle", .red)
        case "failure": ("bolt.fill", .yellow)
        case "timed": ("clock.fill", .purple)
        default: ("dumbbell", .blue)
        }
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

// MARK: - Smart Weight Suggestion Banner (Phase 3)

struct SmartWeightSuggestionBanner: View {
    let exerciseName: String
    let currentWeight: Double
    let suggestedWeight: Double
    let onApply: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Smart Suggestion")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.purple)
                Text("\(exerciseName): Try \(Int(suggestedWeight))kg instead of \(Int(currentWeight))kg")
                    .font(.subheadline)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Apply") {
                onApply()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .purple.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Weight Suggestion Logic

extension ActiveWorkoutView {
    /// Apply a weight suggestion to the specified set and cascade to subsequent sets
    private func applyWeightSuggestion(_ suggestion: (exerciseName: String, currentWeight: Double, suggestedWeight: Double, setIndex: Int, exerciseIndex: Int)) {
        guard suggestion.exerciseIndex < session.exercises.count,
              suggestion.setIndex < session.exercises[suggestion.exerciseIndex].sets.count else { return }
        
        let ex = session.exercises[suggestion.exerciseIndex]
        ex.sets[suggestion.setIndex].weight = suggestion.suggestedWeight
        ex.sets[suggestion.setIndex].isWeightInherited = false
        
        // Cascade to subsequent sets
        for i in (suggestion.setIndex + 1)..<ex.sets.count {
            if ex.sets[i].isComplete || !ex.sets[i].isWeightInherited { break }
            ex.sets[i].weight = suggestion.suggestedWeight
        }
        
        showWeightSuggestion = false
        weightSuggestion = nil
    }
}

// MARK: - Rest Config Sheet

struct RestConfigSheet: View {
    @Environment(\.dismiss) var dismiss
    let exerciseName: String
    let restNormal: Int
    let restWarmup: Int
    let restDrop: Int
    let restTimed: Int
    let restEffort: Int
    let restFailure: Int
    let onSave: (RestConfigTimes) -> Void
    
    @State private var normal: Int
    @State private var warmup: Int
    @State private var drop: Int
    @State private var timed: Int
    @State private var effort: Int
    @State private var failure: Int
    
    init(exerciseName: String, restNormal: Int, restWarmup: Int, restDrop: Int, restTimed: Int, restEffort: Int, restFailure: Int, onSave: @escaping (RestConfigTimes) -> Void) {
        self.exerciseName = exerciseName
        self.restNormal = restNormal
        self.restWarmup = restWarmup
        self.restDrop = restDrop
        self.restTimed = restTimed
        self.restEffort = restEffort
        self.restFailure = restFailure
        self.onSave = onSave
        _normal = State(initialValue: restNormal)
        _warmup = State(initialValue: restWarmup)
        _drop = State(initialValue: restDrop)
        _timed = State(initialValue: restTimed)
        _effort = State(initialValue: restEffort)
        _failure = State(initialValue: restFailure)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rest Times") {
                    restRow(label: "Normal", value: $normal, icon: "dumbbell", color: .blue)
                    restRow(label: "Warmup", value: $warmup, icon: "sunrise", color: .orange)
                    restRow(label: "Drop Set", value: $drop, icon: "arrow.down.circle", color: .red)
                    restRow(label: "Timed", value: $timed, icon: "clock", color: .purple)
                    restRow(label: "Effort", value: $effort, icon: "flame", color: .yellow)
                    restRow(label: "Failure", value: $failure, icon: "bolt", color: .pink)
                }
            }
            .navigationTitle("Rest Times — \(exerciseName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(RestConfigTimes(normal: normal, warmup: warmup, drop: drop, timed: timed, effort: effort, failure: failure))
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func restRow(label: String, value: Binding<Int>, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
            Spacer()
            Stepper(value: value, in: 0...600, step: 5) {
                Text(formatSeconds(value.wrappedValue))
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct RestConfigTimes {
    let normal: Int
    let warmup: Int
    let drop: Int
    let timed: Int
    let effort: Int
    let failure: Int
}

// MARK: - Superset Group Types

enum SupersetGroupItem {
    case superset(SupersetM, [WorkoutExerciseM])
    case single(WorkoutExerciseM, Int)
}

// MARK: - Superset Group Card

extension ActiveWorkoutView {
    /// Build grouped exercises for superset display
    private func buildSupersetGroups() -> [SupersetGroupItem] {
        var groups: [SupersetGroupItem] = []
        var processedSupersetIds: Set<String> = []
        
        for ex in session.exercises {
            if let ssId = ex.supersetId {
                if !processedSupersetIds.contains(ssId) {
                    processedSupersetIds.insert(ssId)
                    let superset = session.supersets.first { $0.ssId == ssId }
                    let exercises = session.exercises.filter { $0.supersetId == ssId }
                    if let superset = superset {
                        groups.append(.superset(superset, exercises))
                    } else {
                        // Superset not found, treat as single
                        if let idx = session.exercises.firstIndex(where: { $0.weId == ex.weId }) {
                            groups.append(.single(ex, idx))
                        }
                    }
                }
            } else {
                if let idx = session.exercises.firstIndex(where: { $0.weId == ex.weId }) {
                    groups.append(.single(ex, idx))
                }
            }
        }
        
        return groups
    }
    
    @ViewBuilder
    private func supersetGroupCard(superset: SupersetM, exercises: [WorkoutExerciseM], groupIndex: Int) -> some View {
        let color = SupersetColors.allColors[superset.color ?? SupersetColors.defaultColor] ?? .blue
        let isCollapsed = collapsedSupersetIds.contains(superset.ssId)
        
        VStack(alignment: .leading, spacing: 0) {
            // Superset header
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(superset.name)
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
                Text("\(exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                // Superset player button
                Button {
                    supersetPlayerId = superset.ssId
                    showSupersetPlayer = true
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color, in: Capsule())
                        .foregroundStyle(.white)
                }
                // Collapse toggle
                Button {
                    if isCollapsed {
                        collapsedSupersetIds.remove(superset.ssId)
                    } else {
                        collapsedSupersetIds.insert(superset.ssId)
                    }
                } label: {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            if !isCollapsed {
                // Exercise cards within superset
                VStack(spacing: 8) {
                    ForEach(Array(exercises.enumerated()), id: \.element.weId) { idx, ex in
                        exerciseCard(for: ex, at: session.exercises.firstIndex(where: { $0.weId == ex.weId }) ?? 0)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview { ActiveWorkoutView(isActive: .constant(true), routine: nil) }

// MARK: - Insight Banner State

struct InsightBannerState: Identifiable {
    let id = UUID()
    let exerciseIndex: Int
    let setIndex: Int
    let exerciseName: String
    let oldValue: Double
    let newValue: Double
    let type: InsightType
    var isApplied: Bool = false
    
    enum InsightType {
        case increase, decrease, applied
    }
}

struct InsightBannerView: View {
    let exerciseName: String
    let oldValue: Double
    let newValue: Double
    let type: InsightBannerState.InsightType
    let onApply: () -> Void
    let onUndo: () -> Void
    let onDismiss: () -> Void
    
    private var bgColor: Color {
        switch type {
        case .applied: return Color.green.opacity(0.1)
        case .increase: return Color.green.opacity(0.1)
        case .decrease: return Color.yellow.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch type {
        case .applied: return Color.green.opacity(0.2)
        case .increase: return Color.green.opacity(0.2)
        case .decrease: return Color.yellow.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch type {
        case .applied: return .green
        case .increase: return .green
        case .decrease: return .yellow
        }
    }
    
    private var iconName: String {
        switch type {
        case .applied: return "checkmark.circle.fill"
        case .increase: return "arrow.up.right"
        case .decrease: return "arrow.down.right"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(textColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type == .applied ? "Applied" : "Smart Suggestion")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(textColor)
                if type != .applied {
                    Text("\(exerciseName): Try \(Int(newValue))kg instead of \(Int(oldValue))kg")
                        .font(.subheadline)
                        .lineLimit(2)
                } else {
                    Text("\(exerciseName): Changed to \(Int(newValue))kg")
                        .font(.subheadline)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if type == .applied {
                Button("Undo") {
                    onUndo()
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            } else {
                Button("Apply") {
                    onApply()
                }
                .buttonStyle(.borderedProminent)
                .tint(textColor)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(bgColor, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: textColor.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Superset Player View

struct SupersetPlayerView: View {
    @Environment(\.dismiss) var dismiss
    @Query private var allExercises: [ExerciseM]
    
    let session: WorkoutSessionM
    let supersetId: String
    
    @State private var currentExerciseIndex: Int = 0
    @State private var currentRoundIndex: Int = 0
    @State private var phase: PlayerPhase = .work
    @State private var timeLeft: Int = 10
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    
    enum PlayerPhase {
        case work
        case rest
        case done
    }
    
    var superset: SupersetM? {
        session.supersets.first { $0.ssId == supersetId }
    }
    
    var exercises: [WorkoutExerciseM] {
        session.exercises.filter { $0.supersetId == supersetId }
    }
    
    var currentExercise: WorkoutExerciseM? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    var currentSet: PerformedSetM? {
        guard let ex = currentExercise, currentRoundIndex < ex.sets.count else { return nil }
        return ex.sets[currentRoundIndex]
    }
    
    var isLastExercise: Bool {
        currentExerciseIndex >= exercises.count - 1
    }
    
    var isLastRound: Bool {
        guard let ex = currentExercise else { return false }
        return currentRoundIndex >= ex.sets.count - 1
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if phase == .done {
                doneView
            } else {
                VStack(spacing: 24) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Round \(currentRoundIndex + 1)")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("\(currentExerciseIndex + 1)/\(exercises.count)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    
                    if let ex = currentExercise {
                        let def = allExercises.first { $0.id == ex.exerciseId }
                        Text(def?.name ?? "Exercise")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    }
                    
                    if let set = currentSet {
                        VStack(spacing: 16) {
                            if set.setTypeStr != "timed" {
                                HStack {
                                    Text("Weight")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    TextField("0", text: $weightInput)
                                        .keyboardType(.decimalPad)
                                        .font(.title.monospacedDigit())
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(.white)
                                        .frame(width: 100)
                                }
                            }
                            
                            HStack {
                                Text("Reps")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                TextField("0", text: $repsInput)
                                    .keyboardType(.numberPad)
                                    .font(.title.monospacedDigit())
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(.white)
                                    .frame(width: 100)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    if phase == .work {
                        Button {
                            completeCurrentSet()
                        } label: {
                            Text("Complete Set")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal)
                    } else if phase == .rest {
                        restTimerView
                    }
                }
            }
        }
        .onAppear {
            if let set = currentSet {
                weightInput = set.weight > 0 ? String(format: "%.1f", set.weight) : ""
                repsInput = set.reps > 0 ? "\(set.reps)" : ""
            }
        }
    }
    
    @MainActor
    private var restTimerView: some View {
        VStack(spacing: 16) {
            Text("Rest & Switch")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("\(timeLeft)s")
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(timeLeft <= 3 ? .orange : .blue)
            
            HStack(spacing: 24) {
                Button {
                    timeLeft += 10
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    advanceToNextExercise()
                } label: {
                    Text("Skip Rest")
                        .font(.headline)
                        .foregroundStyle(.green)
                }
                
                Button {
                    timeLeft = max(0, timeLeft - 10)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .onAppear { startRestTimer() }
    }
    
    private var doneView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Superset Complete!")
                .font(.title.bold())
                .foregroundStyle(.white)
            
            Text(superset?.name ?? "Superset")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
        }
    }
    
    private func completeCurrentSet() {
        guard let ex = currentExercise else { return }
        guard currentRoundIndex < ex.sets.count else { return }
        
        if let weight = Double(weightInput) {
            ex.sets[currentRoundIndex].weight = weight
        }
        if let reps = Int(repsInput) {
            ex.sets[currentRoundIndex].reps = reps
        }
        ex.sets[currentRoundIndex].isComplete = true
        ex.sets[currentRoundIndex].completedAt = Date()
        
        if isLastExercise && isLastRound {
            for exercise in exercises {
                let lastSet = exercise.sets.last
                exercise.sets.append(PerformedSetM(
                    id: "set-\(UUID())",
                    reps: lastSet?.reps ?? 10,
                    weight: lastSet?.weight ?? 0,
                    type: lastSet?.setTypeStr ?? "normal"
                ))
            }
        }
        
        timeLeft = 10
        phase = .rest
    }
    
    private func advanceToNextExercise() {
        if isLastExercise {
            currentRoundIndex += 1
            currentExerciseIndex = 0
        } else {
            currentExerciseIndex += 1
        }
        
        if let set = currentSet {
            weightInput = set.weight > 0 ? String(format: "%.1f", set.weight) : ""
            repsInput = set.reps > 0 ? "\(set.reps)" : ""
        }
        
        phase = .work
    }
    
    private func startRestTimer() {
        Task {
            while timeLeft > 0 {
                try? await Task.sleep(for: .seconds(1))
                timeLeft -= 1
            }
            if timeLeft <= 0 {
                advanceToNextExercise()
            }
        }
    }
}

// MARK: - Exercise Info Sheet (inline replacement for ExerciseDetailsView)

struct ExerciseInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: ExerciseM
    let historicalData: (avgWeight: Double, avgReps: Int)?
    let useLocalizedNames: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(exercise.displayName(useSpanish: useLocalizedNames))
                        .font(.title.bold())
                    
                    HStack(spacing: 12) {
                        Label(exercise.bodyPartStr, systemImage: "figure.strengthtraining.traditional")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    
                    if let hist = historicalData {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Session Average").font(.headline)
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("\(String(format: "%.1f", hist.avgWeight)) kg")
                                        .font(.title2.bold())
                                        .foregroundStyle(.blue)
                                    Text("Weight").font(.caption).foregroundStyle(.secondary)
                                }
                                VStack(alignment: .leading) {
                                    Text("\(hist.avgReps)")
                                        .font(.title2.bold())
                                        .foregroundStyle(.green)
                                    Text("Reps").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Promotion Banner View (web parity)

struct PromotionBannerView: View {
    let exerciseName: String
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    
    private let accentColor = Color(red: 1.0, green: 0.75, blue: 0.0)
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Ready for a Challenge?")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
                Text("Try \(exerciseName) — you're ready to level up!")
                    .font(.subheadline)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Upgrade") {
                onUpgrade()
            }
            .buttonStyle(.borderedProminent)
            .tint(accentColor)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(0.2), radius: 8, y: 4)
    }
}
