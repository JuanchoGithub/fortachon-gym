import SwiftUI
import SwiftData
import FortachonCore

struct TabTrainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSessionM.startTime, order: .reverse) private var sessions: [WorkoutSessionM]
    @Query private var routines: [RoutineM]
    @Query private var preferences: [UserPreferencesM]
    @Query private var supplements: [SupplementLogM]
    
    @State private var selectedRoutine: RoutineM?
    @State private var showEmptyWorkout = false
    
    var prefs: UserPreferencesM? { preferences.first }
    
    var isNewUser: Bool {
        sessions.isEmpty && !routines.contains { !$0.rtId.hasPrefix("rt-") }
    }
    
    var recommendation: Recommendation? {
        prefs == nil ? nil : getRecommendation(
            history: sessions.map { WorkoutSession(from: $0) },
            routines: routines.map { Routine(from: $0) },
            exercises: [],
            userGoal: prefs?.mainGoal ?? .muscle
        )
    }
    
    var activeSupplements: [SupplementPlanItem] {
        let today = Calendar.current.startOfDay(for: Date())
        return supplements
            .filter { !$0.isSnoozed || ($0.snoozedUntil ?? today) < today }
            .map { SupplementPlanItem(
                id: $0.id.uuidString,
                supplement: $0.name,
                dosage: $0.dosage,
                time: $0.timingStr
            )}
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Recommendation Banner
                    if let rec = recommendation, !isNewUser {
                        RecommendationBannerView(
                            recommendation: rec,
                            onRoutineSelect: { startRoutine(fromTemplate: routines.first { $0.rtId == $0 }) }
                        )
                    }
                    
                    // New User Onboarding
                    if isNewUser {
                        OnboardingCardView()
                    }
                    
                    // Quick Training Buttons
                    QuickTrainingButtonsView(
                        onStartSession: { startRoutineSession(focus: $0) }
                    )
                    
                    // Start Empty Workout Button
                    Button {
                        showEmptyWorkout = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quick Workout").font(.title3.bold())
                                Text("Start an empty workout")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            Spacer()
                            Image(systemName: "plus.app.fill").font(.title)
                        }
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    
                    // Latest Workouts
                    if !sessions.isEmpty {
                        LatestWorkoutsView(sessions: Array(sessions.prefix(3)))
                    }
                    
                    // My Templates
                    let customRoutines = routines.filter { !$0.rtId.hasPrefix("rt-") }
                    if !customRoutines.isEmpty {
                        RoutinesSectionView(
                            title: "My Templates",
                            routines: customRoutines,
                            onRoutineSelect: { selectedRoutine = $0 }
                        )
                    }
                    
                    // Sample Workouts
                    let sampleRoutines = routines.filter { $0.rtId.hasPrefix("rt-") && $0.routineTypeStr == "strength" }
                    if !sampleRoutines.isEmpty {
                        RoutinesSectionView(
                            title: "Sample Workouts",
                            routines: sampleRoutines,
                            onRoutineSelect: { selectedRoutine = $0 }
                        )
                    }
                    
                    // Supplements
                    if !activeSupplements.isEmpty {
                        SupplementPlanView(items: activeSupplements)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Train")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedRoutine) { routine in
                RoutineDetailSheetView(routine: routine)
            }
            .sheet(isPresented: $showEmptyWorkout) {
                Text("Empty Workout View - Coming Soon")
                    .presentationDetents([.medium])
            }
        }
        .task {
            if routines.isEmpty {
                seedSampleData()
            }
        }
    }
    
    private func startRoutineSession(focus: RoutineFocus) {
        let settings = SurveyAnswers(
            experience: prefs?.mainGoal == nil ? .beginner : .intermediate,
            goal: prefs?.mainGoal ?? .muscle,
            equipment: .gym,
            time: .medium
        )
        let routine = generateSmartRoutine(focus: focus, settings: settings)
        
        let routineM = RoutineM(
            id: "quick-\(UUID().uuidString)",
            name: "Quick \(focus.rawValue.capitalized)",
            desc: "Auto-generated \(focus.rawValue)",
            isTemplate: false,
            type: "strength"
        )
        
        for ex in routine.exercises {
            let exM = WorkoutExerciseM(id: ex.id, exerciseId: ex.exerciseId)
            for set in ex.sets {
                exM.sets.append(PerformedSetM(
                    id: set.id,
                    reps: set.reps,
                    weight: set.weight,
                    type: set.type.rawValue
                ))
            }
            routineM.exercises.append(exM)
        }
        
        modelContext.insert(routineM)
        selectedRoutine = routineM
        try? modelContext.save()
    }
    
    private func startRoutine(fromTemplate routine: RoutineM? = nil) {
        guard let routine = routine else { return }
        // Implementation for starting from template
        selectedRoutine = routine
    }
    
    private func seedSampleData() {
        let samples: [(String, String, [String])] = [
            ("rt-push-1", "Push Day A", ["ex-1", "ex-4", "ex-26", "ex-85"]),
            ("rt-pull-1", "Pull Day A", ["ex-5", "ex-10", "ex-7"]),
            ("rt-legs-1", "Leg Day A", ["ex-2", "ex-16", "ex-17", "ex-20"])
        ]
        
        for (id, name, exIds) in samples {
            let r = RoutineM(id: id, name: name, desc: "Sample routine", isTemplate: true, type: "strength")
            for exId in exIds {
                r.exercises.append(WorkoutExerciseM(id: "we-\(id)-\(exId)", exerciseId: exId))
            }
            modelContext.insert(r)
        }
        
        if preferences.isEmpty {
            modelContext.insert(UserPreferencesM())
            modelContext.insert(SupplementLogM(name: "Creatine Monohydrate", dosage: "5g", timing: "Daily"))
            modelContext.insert(SupplementLogM(name: "Whey Protein", dosage: "30g", timing: "Post-workout"))
        }
        
        try? modelContext.save()
    }
}

#Preview {
    TabTrainView()
}