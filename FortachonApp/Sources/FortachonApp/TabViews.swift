import SwiftUI
import SwiftData
import FortachonCore


struct TrainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSessionM.startTime, order: .reverse)
    private var sessions: [WorkoutSessionM]
    @Query private var routines: [RoutineM]
    @Query private var preferences: [UserPreferencesM]
    @Query private var supplements: [SupplementLogM]
    
    @State private var checkInDone = false
    @State private var selectedRoutine: RoutineM?
    @State private var quickTrainOpen = true
    
    var prefs: UserPreferencesM? { preferences.first }
    
    var isNewUser: Bool {
        sessions.isEmpty && !routines.contains { !$0.rtId.hasPrefix("rt-") }
    }
    
    var recommendation: Recommendation? {
        prefs == nil ? nil : getRecommendation(
            history: sessions.map { WorkoutSession(from: $0) },
            routines: routines.map { Routine(from: $0) },
            exercises: [], userGoal: prefs?.mainGoal ?? .muscle
        )
    }
    
    var activeSupplements: [SupplementPlanItem] {
        let today = Calendar.current.startOfDay(for: Date())
        return supplements
            .filter { !$0.isSnoozed || ($0.snoozedUntil ?? today) < today }
            .map { SupplementPlanItem(
                id: $0.id.uuidString, supplement: $0.name,
                dosage: $0.dosage, time: $0.timingStr)
            }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let rec = recommendation, !isNewUser {
                        RecommendationBanner(
                            recommendation: rec, onDismiss: { },
                            onRoutineSelect: { _ in }
                        )
                    }
                    if isNewUser { OnboardingCard() }
                    if sessions.isEmpty && !checkInDone {
                        CheckInCardView {
                            markCheckIn(reason: $0)
                            checkInDone = true
                        }
                    }
                    QuickTrainingButtons(
                        isOpen: quickTrainOpen,
                        onToggle: { quickTrainOpen.toggle() },
                        onStartSession: { startQuickSession(focus: $0) }
                    )
                    StartWorkoutButton { startEmptyWorkout() }
                    if !sessions.isEmpty {
                        LatestWorkoutsSection(sessions: Array(sessions.prefix(3)))
                    }
                    if !routines.isEmpty {
                        RoutinesSection(
                            routines: routines.filter { !$0.rtId.hasPrefix("rt-") },
                            onRoutineSelect: { selectedRoutine = $0 }
                        )
                        RoutinesSection(
                            routines: routines.filter { $0.rtId.hasPrefix("rt-") && $0.routineTypeStr == "strength" },
                            title: "Sample Workouts",
                            onRoutineSelect: { selectedRoutine = $0 }
                        )
                    }
                    if !activeSupplements.isEmpty {
                        SupplementCardView(
                            items: activeSupplements,
                            onLog: { markSupplementsTaken(ids: $0) },
                            onSnoozeAll: { snoozeAllSupplements() }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Train")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .sheet(item: $selectedRoutine) { routine in
                RoutineDetailSheet(routine: routine, onStart: { startRoutine(routine) })
            }
        }
        .onAppear {
            if routines.isEmpty { seedSampleData() }
        }
    }
    
    private func markCheckIn(reason: CheckInReason) {
        if prefs == nil {
            modelContext.insert(UserPreferencesM(
                lastCheckInDate: Date(), lastCheckInReason: reason.rawValue))
        } else {
            prefs?.lastCheckInDate = Date()
            prefs?.lastCheckInReason = reason.rawValue
        }
    }
    
    private func markSupplementsTaken(ids: [String]) {
        for sup in supplements where ids.contains(sup.id.uuidString) {
            sup.takenDate = Date()
        }
        try? modelContext.save()
    }
    
    private func snoozeAllSupplements() {
        for sup in supplements {
            sup.isSnoozed = true
            sup.snoozedUntil = Date().addingTimeInterval(24 * 3600)
        }
        try? modelContext.save()
    }
    
    private func startQuickSession(focus: RoutineFocus) {
        let settings = SurveyAnswers(
            experience: prefs == nil ? .beginner : .intermediate,
            goal: prefs?.mainGoal ?? .muscle, equipment: .gym, time: .medium)
        let routine = generateSmartRoutine(focus: focus, settings: settings)
        let routineM = RoutineM(
            id: "quick-\(Date().timeIntervalSince1970)",
            name: "Quick \(focus.rawValue.capitalized)",
            desc: "Auto-generated \(focus.rawValue)", isTemplate: false,
            type: "strength")
        for ex in routine.exercises {
            let exM = WorkoutExerciseM(id: ex.id, exerciseId: ex.exerciseId)
            for set in ex.sets {
                exM.sets.append(PerformedSetM(
                    id: set.id, reps: set.reps, weight: set.weight, type: set.type.rawValue))
            }
            routineM.exercises.append(exM)
        }
        modelContext.insert(routineM)
        selectedRoutine = routineM
        try? modelContext.save()
    }
    
    private func startEmptyWorkout() {
        let routineM = RoutineM(
            id: "empty-\(Date().timeIntervalSince1970)",
            name: "Quick Workout", desc: "Empty workout", type: "strength")
        modelContext.insert(routineM)
        selectedRoutine = routineM
        try? modelContext.save()
    }
    
    private func startRoutine(_ routine: RoutineM) {
        let session = WorkoutSessionM(
            id: "ws-\(Date().timeIntervalSince1970)",
            routineId: routine.rtId, routineName: routine.name,
            startTime: Date(), endTime: Date())
        for ex in routine.exercises {
            let exM = WorkoutExerciseM(id: "ex-\(UUID().uuidString)", exerciseId: ex.exerciseId)
            session.exercises.append(exM)
        }
        modelContext.insert(session)
        selectedRoutine = nil
        try? modelContext.save()
    }
    
    private func seedSampleData() {
        let samples: [(String, String, [String])] = [
            ("rt-push-1", "Push Day A", ["ex-1", "ex-4", "ex-26", "ex-85"]),
            ("rt-pull-1", "Pull Day A", ["ex-5", "ex-10", "ex-7"]),
            ("rt-legs-1", "Leg Day A", ["ex-2", "ex-16", "ex-17", "ex-20"])
        ]
        for (id, name, exIds) in samples {
            let r = RoutineM(id: id, name: name, desc: "Sample routine",
                             isTemplate: true, type: "strength")
            for exId in exIds {
                r.exercises.append(WorkoutExerciseM(
                    id: "we-\(id)-\(exId)", exerciseId: exId))
            }
            modelContext.insert(r)
        }
        modelContext.insert(UserPreferencesM())
        modelContext.insert(SupplementLogM(
            name: "Creatine Monohydrate", dosage: "5g", timing: "Daily"))
        modelContext.insert(SupplementLogM(
            name: "Whey Protein", dosage: "30g", timing: "Post-workout"))
        try? modelContext.save()
    }
}

// MARK: - Recommendation Banner

struct RecommendationBanner: View {
    let recommendation: Recommendation
    let onDismiss: () -> Void
    let onRoutineSelect: (String) -> Void
    
    var gradient: LinearGradient {
        switch recommendation.type {
        case .workout:
            return LinearGradient(colors: [.blue, .indigo],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rest, .activeRecovery:
            return LinearGradient(colors: [.green, .mint],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .deload:
            return LinearGradient(colors: [.red, .pink],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .promotion:
            return LinearGradient(colors: [.orange, .yellow],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .imbalance:
            return LinearGradient(colors: [.orange, .yellow],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var icon: String {
        switch recommendation.type {
        case .workout: return "figure.strengthtraining.traditional"
        case .rest: return "moon.stars.fill"
        case .activeRecovery: return "sparkles"
        case .deload: return "exclamationmark.triangle.fill"
        case .promotion: return "trophy.fill"
        case .imbalance: return "scalemass.fill"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(recommendation.title).font(.headline).foregroundColor(.white)
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                Text(recommendation.reason)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(3)
                ForEach(Array(recommendation.relevantRoutineIds.prefix(2)), id: \.self) { id in
                    Button { onRoutineSelect(id) } label: {
                        HStack {
                            Text("Start")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding(8)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .foregroundColor(.white)
                }
                if recommendation.generatedRoutine != nil {
                    Button { } label: {
                        Label("View Generated Routine", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(.white, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(gradient, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
}

// MARK: - Onboarding Card

struct OnboardingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "sparkles").font(.largeTitle).foregroundColor(.white)
            Text("Welcome to Fortachon").font(.title2.bold()).foregroundColor(.white)
            Text("Set up your profile to get personalized workout recommendations.")
                .foregroundColor(.white.opacity(0.85))
            Button {
                // Navigate to onboarding
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity).padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
            }
        }
        .padding(16)
        .background(LinearGradient(colors: [.blue, .indigo],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
}

// MARK: - Check-In Card

struct CheckInCardView: View {
    let onCheckIn: (CheckInReason) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.indigo)
                    .padding(10)
                    .background(.indigo.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check In").font(.headline)
                    Text("How are you feeling?")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                ForEach(CheckInReason.allCases, id: \.self) { reason in
                    Button { onCheckIn(reason) } label: {
                        Text(reason.label).font(.caption).fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .foregroundStyle(.indigo)
                }
            }
        }
        .padding(16)
        .background(LinearGradient(colors: [.indigo.opacity(0.12), .purple.opacity(0.12)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.indigo.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Quick Training

struct QuickTrainingButtons: View {
    let isOpen: Bool
    let onToggle: () -> Void
    let onStartSession: (RoutineFocus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { onToggle() } label: {
                HStack {
                    Text("Quick Training").font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(isOpen ? .degrees(90) : .zero)
                }
            }.buttonStyle(.plain)
            if isOpen {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 8) {
                    QuickSessionButton(title: "Push", icon: "arrowshape.up.fill",
                                       color: .blue) { onStartSession(.push) }
                    QuickSessionButton(title: "Pull", icon: "arrowshape.down.fill",
                                       color: .purple) { onStartSession(.pull) }
                    QuickSessionButton(title: "Legs", icon: "figure.walk",
                                       color: .green) { onStartSession(.legs) }
                }
                HStack(spacing: 8) {
                    TimerButton(label: "5 min")
                    TimerButton(label: "10 min")
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Start Workout
struct StartWorkoutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Workout").font(.title3.bold())
                    Text("Start an empty workout")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "plus.app.fill").font(.title)
            }
            .foregroundColor(.white)
            .padding(16)
            .background(LinearGradient(colors: [.blue, .cyan.opacity(0.8)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Latest Workouts

struct LatestWorkoutsSection: View {
    let sessions: [WorkoutSessionM]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latest Workouts").font(.headline)
            ForEach(sessions) { session in
                Label(session.routineName, systemImage: "checkmark.circle")
                    .padding(12)
                    .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Routines Section

struct RoutinesSection: View {
    let routines: [RoutineM]
    var title: String = "My Templates"
    let onRoutineSelect: (RoutineM) -> Void
    @State private var isOpen = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { withAnimation { isOpen.toggle() } } label: {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(isOpen ? .degrees(90) : .zero)
                }
            }.buttonStyle(.plain)
            if isOpen {
                if routines.isEmpty {
                    Text("No routines yet").foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 20)
                } else {
                    ForEach(routines) { routine in
                        Button { onRoutineSelect(routine) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(routine.name).fontWeight(.semibold)
                                    Text("\(routine.exercises.count) exercises")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickSessionButton: View {
    let title, icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption.bold())
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity)
            .padding(12).background(color, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct TimerButton: View {
    let label: String
    
    var body: some View {
        Button { } label: {
            VStack(spacing: 4) {
                Image(systemName: "stopwatch")
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Supplement Card

struct SupplementCardView: View {
    let items: [SupplementPlanItem]
    let onLog: ([String]) -> Void
    let onSnoozeAll: () -> Void
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
                        Image(systemName: selectedIds.contains(item.id)
                              ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(.cyan)
                        Text(item.supplement).fontWeight(.medium)
                        Spacer()
                        Text(item.dosage)
                            .font(.caption.monospaced())
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 12) {
                Button { onSnoozeAll() } label: {
                    Text("Snooze").frame(maxWidth: .infinity).padding(10)
                        .background(Color(white: 0.2),
                                    in: RoundedRectangle(cornerRadius: 10))
                }
                .foregroundStyle(.white.opacity(0.7))
                Button { onLog(Array(selectedIds)) } label: {
                    Label("Log \(selectedIds.count)", systemImage: "checkmark")
                        .frame(maxWidth: .infinity).padding(10)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10))
                }
                .foregroundStyle(.cyan)
                .disabled(selectedIds.isEmpty)
            }
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(LinearGradient(
            colors: [Color(red: 0.02, green: 0.16, blue: 0.31),
                     Color(red: 0.01, green: 0.13, blue: 0.27)],
            startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1))
        .onAppear { selectedIds = Set(items.map { $0.id }) }
        .onChange(of: items) { _, _ in selectedIds = Set(items.map { $0.id }) }
    }
}

// MARK: - Routine Detail Sheet

struct RoutineDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let routine: RoutineM
    let onStart: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section("Exercises") {
                    ForEach(routine.exercises) { ex in
                        HStack {
                            Text(ex.exerciseId)
                            Spacer()
                            Text("\(ex.sets.count) sets").foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    Button {
                        onStart()
                        dismiss()
                    } label: {
                        Label("Start Workout", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(routine.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#if os(macOS)
@main
struct FortachonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(try! makeInMemoryContainer())
        }
    }
}
#endif
