import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import FortachonCore
import UIKit
import AVFAudio

struct TabProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferencesM]
    @Query(sort: \WorkoutSessionM.startTime, order: .reverse) private var sessions: [WorkoutSessionM]
    @Query(sort: \WeightEntryM.date, order: .reverse) private var sortedWeightEntries: [WeightEntryM]
    @Query private var exercises: [ExerciseM]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    
    // Tab selection
    @State private var activeTab: ProfileTab = .profile
    
    // Settings
    @State private var selectedWeightUnit = "kg"
    @State private var selectedGoal = "muscle"
    @State private var bodyWeight: String = ""
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var selectedGender = ""
    @State private var showWeightChart = false
    @State private var showRestTimerSettings = false
    struct IdentifiableString: Identifiable {
        let id: String
        let value: String
    }
    @State private var selectedOrmExerciseId: IdentifiableString?
    @State private var showGenderPicker = false
    
    // Analytics
    @State private var lifterStats = LifterStats(
        consistencyScore: 0, volumeScore: 0, intensityScore: 0,
        experienceLevel: 0, archetype: .beginner, favMuscle: "N/A",
        efficiencyScore: 0, rawConsistency: 0, rawVolume: 0, rawIntensity: 0
    )
    @State private var muscleFreshness: [MuscleFreshness] = []
    @State private var strengthProfile: [StrengthProfileEntry] = []
    
    // Import/Export
    @State private var dataManager: DataImportExportManager?
    @State private var showImportPicker = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var pendingImportData: ExportData?
    @State private var showImportConfirm = false
    @State private var importSummary: DataImportExportManager.ImportSummary?
    @State private var importStatusMsg: DataImportExportManager.StatusMessage?
    
    // Cloud Sync
    @State private var cloudSync = CloudSyncService()
    @State private var isSyncing = false
    @State private var syncMessage: String?
    @State private var syncIsError = false
    
    // Screen wake
    @StateObject private var screenWakeManager = ScreenWakeManager.shared
    
    // Voice
    @State private var selectedVoiceURI: String? = nil
    @State private var speechVoices = [AVSpeechSynthesisVoice]()
    
    var prefs: UserPreferencesM? { preferences.first }
    var isImperial: Bool { selectedWeightUnit == "lbs" }
    
    // Stats
    var totalWorkouts: Int { sessions.count }
    
    var thisWeekWorkouts: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startTime > weekAgo }.count
    }
    
    var totalSets: Int {
        sessions.reduce(0) { sum, session in
            sum + session.exercises.reduce(0) { exSum, ex in
                exSum + ex.sets.filter { $0.isComplete }.count
            }
        }
    }
    
    var currentBodyWeight: Double {
        sortedWeightEntries.first?.weight ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab bar
                HStack {
                    ForEach(ProfileTab.allCases) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(tab.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(activeTab == tab ? .primary : .secondary)
                                Rectangle()
                                    .fill(activeTab == tab ? Color.blue : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 0)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch activeTab {
                        case .profile:
                            profileTabContent
                        case .account:
                            accountTabContent
                        case .settings:
                            settingsTabContent
                        case .about:
                            aboutTabContent
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showWeightChart) {
                WeightChartView(
                    weightHistory: sortedWeightEntries.map { WeightEntry(id: $0.id, weight: $0.weight, date: $0.date) },
                    currentWeight: $bodyWeightDouble
                )
            }
            .sheet(isPresented: $showRestTimerSettings) {
                RestTimerSettingsSheetView(prefs: prefs)
            }
            .sheet(item: $selectedOrmExerciseId) { item in
                if let exercise = exercises.first(where: { $0.id == item.value }) {
                    OneRepMaxView(exercise: exercise)
                }
            }
            .sheet(isPresented: $showGenderPicker) {
                genderPickerSheet
            }
            .sheet(isPresented: $showImportConfirm) {
                importConfirmationSheet
            }
            .alert(item: $importStatusMsg) { msg in
                Alert(
                    title: Text(msg.title),
                    message: Text(msg.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportSelection(result)
            }
            .onAppear {
                loadSettings()
                loadVoices()
                calculateAnalytics()
            }
        }
    }
    
    // MARK: - Profile Tab
    
    private var profileTabContent: some View {
        VStack(spacing: 20) {
            // Stats Summary Cards
            statsCards
            
            // Current Weight + Log
            currentWeightCard
            
            // Fatigue Monitor
            if sessions.count > 0 {
                FatigueMonitorView(muscleFreshness: muscleFreshness)
            }
            
            // Muscle Heatmap
            if sessions.count > 0 {
                MuscleHeatmapView(freshnessData: muscleFreshness)
            }
            
            // LifterDNA
            if sessions.count >= 5 {
                LifterDNAView(stats: lifterStats)
            }
            
            // Strength Profile
            if sessions.count > 0 {
                strengthProfileSection
            }
            
            // Personal Records
            personalRecordsSection
            
            // Achievements
            if sessions.count > 0 {
                UnlockHistoryView(unlocks: generateUnlocks())
            }
        }
    }
    
    @State private var bodyWeightDouble: Double = 0
    
    private var statsCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                MiniStatCard(
                    icon: "figure.strengthtraining.traditional",
                    title: "Workouts",
                    value: "\(totalWorkouts)",
                    color: .blue
                )
                MiniStatCard(
                    icon: "calendar",
                    title: "This Week",
                    value: "\(thisWeekWorkouts)",
                    color: .green
                )
            }
            HStack(spacing: 8) {
                MiniStatCard(
                    icon: "list.number",
                    title: "Total Sets",
                    value: "\(totalSets)",
                    color: .orange
                )
                MiniStatCard(
                    icon: "clock",
                    title: "Avg Duration",
                    value: averageWorkoutDuration,
                    color: .purple
                )
            }
        }
    }
    
    var averageWorkoutDuration: String {
        guard !sessions.isEmpty else { return "0m" }
        let totalMinutes = sessions.reduce(0.0) { sum, session in
            sum + session.endTime.timeIntervalSince(session.startTime) / 60.0
        }
        let avg = totalMinutes / Double(sessions.count)
        return "\(Int(avg))m"
    }
    
    private var currentWeightCard: some View {
        VStack(spacing: 12) {
            // Weight display + chart button
            Button {
                showWeightChart = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if currentBodyWeight > 0 {
                            Text("\(String(format: "%.1f", currentBodyWeight))")
                                .font(.title.bold())
                                .foregroundStyle(Color.blue)
                            Text("Body Weight (\(prefs?.weightUnitStr.uppercased() ?? "KG"))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No weight logged")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Text("Tap to log your weight")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if currentBodyWeight > 0 {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundStyle(Color.blue)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Inline weight logging
            HStack {
                TextField("0", text: $bodyWeight)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Button {
                    logBodyWeight()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(bodyWeight.isEmpty ? Color(.systemGray2) : Color.blue)
                }
                .disabled(bodyWeight.isEmpty)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Strength Profile Section
    
    private var strengthProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strength Profile")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(strengthProfile, id: \.patternName) { entry in
                    strengthProfileRow(entry: entry)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func strengthProfileRow(entry: StrengthProfileEntry) -> some View {
        HStack {
            Text(entry.patternName)
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)
            
            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.tertiary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.5), .blue],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(entry.normalizedScore / 100, 1), height: 8)
                }
            }
            .frame(height: 8)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.maxWeight))")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                if !entry.exerciseName.isEmpty {
                    Text(entry.exerciseName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80)
        }
    }
    
    // MARK: - Personal Records Section
    
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(bigLifts, id: \.id) { lift in
                        PRCard(exerciseId: lift.id, exerciseName: lift.name, sessions: sessions)
                            .frame(width: 160)
                            .onTapGesture {
                                selectedOrmExerciseId = IdentifiableString(id: lift.id, value: lift.id)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var bigLifts: [(id: String, name: String)] {
        [
            ("ex-2", "Squat"),
            ("ex-1", "Bench Press"),
            ("ex-3", "Deadlift"),
            ("ex-4", "Overhead Press"),
            ("ex-5", "Barbell Row")
        ]
    }
    
    // MARK: - Account Tab
    
    private var accountTabContent: some View {
        AccountView()
    }
    
    // MARK: - Settings Tab
    
    private var settingsTabContent: some View {
        VStack(spacing: 20) {
            personalInfoSection
            goalSection
            restTimersSection
            appBehaviorSection
        }
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Info")
                .font(.headline)
            
            VStack(spacing: 1) {
                // Gender
                Button {
                    showGenderPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gender")
                                .font(.subheadline)
                            Text(genderDisplayText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                Divider().padding(.leading)
                
                // Height
                SettingRow(title: "Height", subtitle: heightDisplayText) {
                    if isImperial {
                        imperialHeightInputs
                    } else {
                        TextField("cm", text: $bodyWeight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                if isImperial {
                    Divider().padding(.leading)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Height (ft/in)")
                                .font(.subheadline)
                            Text(heightFeet.isEmpty && heightInches.isEmpty ? "Not set" : "\(heightFeet)ft \(heightInches)in")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        TextField("ft", text: $heightFeet)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .onChange(of: heightFeet) { _, _ in updateHeightCmFromImperial() }
                        Text("ft")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("in", text: $heightInches)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .onChange(of: heightInches) { _, _ in updateHeightCmFromImperial() }
                        Text("in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    Divider().padding(.leading)
                    
                    SettingRow(title: "Height (cm)", subtitle: heightCm.isEmpty ? "Not set" : "\(heightCm) cm") {
                        TextField("cm", text: $heightCm)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    .onChange(of: heightCm) { _, newValue in
                        if let cm = Double(newValue), cm > 0 {
                            prefs?.heightCm = cm
                            try? modelContext.save()
                        }
                    }
                }
                
                Divider().padding(.leading)
                
                // Weight Unit
                SettingRow(title: "Weight Unit", subtitle: "Metric or Imperial") {
                    Picker("", selection: $selectedWeightUnit) {
                        Text("kg").tag("kg")
                        Text("lbs").tag("lbs")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                .onChange(of: selectedWeightUnit) { _, newValue in
                    prefs?.weightUnitStr = newValue
                    try? modelContext.save()
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    @State private var heightCm: String = ""
    
    private var genderDisplayText: String {
        switch selectedGender {
        case "male": return "Male"
        case "female": return "Female"
        case "other": return "Other"
        default: return "Not set"
        }
    }
    
    private var genderPickerSheet: some View {
        NavigationStack {
            Form {
                Section("Select your gender") {
                    ForEach(["male", "female", "other"], id: \.self) { gender in
                        Button {
                            selectedGender = gender
                            prefs?.gender = gender
                            try? modelContext.save()
                            showGenderPicker = false
                        } label: {
                            HStack {
                                Text(gender.capitalized)
                                Spacer()
                                if selectedGender == gender {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gender")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showGenderPicker = false }
                }
            }
        }
    }
    
    private var imperialHeightInputs: some View {
        HStack(spacing: 8) {
            TextField("ft", text: $heightFeet)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 50)
            Text("ft")
            TextField("in", text: $heightInches)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 50)
            Text("in")
        }
        .onChange(of: heightFeet) { _, _ in updateHeightCmFromImperial() }
        .onChange(of: heightInches) { _, _ in updateHeightCmFromImperial() }
    }
    
    private func updateHeightCmFromImperial() {
        let feet = Int(heightFeet) ?? 0
        let inches = Int(heightInches) ?? 0
        let totalCm = Double(feet) * 30.48 + Double(inches) * 2.54
        if totalCm > 0 {
            prefs?.heightCm = totalCm
            try? modelContext.save()
        }
    }
    
    private var heightDisplayText: String {
        if isImperial {
            let feet = heightFeet.isEmpty ? "0" : heightFeet
            let inches = heightInches.isEmpty ? "0" : heightInches
            return heightFeet.isEmpty && heightInches.isEmpty ? "Not set" : "\(feet)ft \(inches)in"
        } else {
            return heightCm.isEmpty ? "Not set" : "\(heightCm) cm"
        }
    }
    
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Goal")
                .font(.headline)
            
            VStack(spacing: 1) {
                SettingRow(title: "Main Goal", subtitle: goalDescription) {
                    Picker("", selection: $selectedGoal) {
                        Text("Strength").tag("strength")
                        Text("Muscle").tag("muscle")
                        Text("Endurance").tag("endurance")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                .onChange(of: selectedGoal) { _, newValue in
                    prefs?.mainGoalStr = newValue
                    prefs?.smartGoalDetection = true
                    try? modelContext.save()
                }
                
                Divider().padding(.leading)
                
                // Smart Goal Detection
                SettingToggleRow(
                    title: "Smart Goal Detection",
                    subtitle: "Auto-detect your goal from training patterns",
                    isOn: Binding(
                        get: { prefs?.smartGoalDetection ?? true },
                        set: { prefs?.smartGoalDetection = $0; try? modelContext.save() }
                    )
                )
                
                Divider().padding(.leading)
                
                // Bio-Adaptive Engine
                SettingToggleRow(
                    title: "Bio-Adaptive Engine",
                    subtitle: "Auto-regulate recovery based on training load",
                    isOn: Binding(
                        get: { prefs?.bioAdaptiveEngine ?? true },
                        set: { prefs?.bioAdaptiveEngine = $0; try? modelContext.save() }
                    )
                )
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    var goalDescription: String {
        switch selectedGoal {
        case "strength": return "Low reps, high weight"
        case "muscle": return "Moderate reps, hypertrophy"
        case "endurance": return "High reps, low weight"
        default: return "Muscle building"
        }
    }
    
    private var restTimersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                showRestTimerSettings = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest Timers")
                            .font(.subheadline)
                        Text("Customize default rest durations")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "timer")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private var appBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Behavior")
                .font(.headline)
            
            VStack(spacing: 1) {
                // Language
                SettingRow(title: "Language", subtitle: languageDisplayText) {
                    Picker("", selection: $appLanguage) {
                        Text("System").tag("system")
                        Text("English").tag("en")
                        Text("Español").tag("es")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                
                Divider().padding(.leading)
                
                // Localized Exercise Names (only when Spanish)
                if appLanguage == "es" || Locale.current.language.languageCode?.identifier == "es" {
                    SettingToggleRow(
                        title: "Localized Names",
                        subtitle: "Show exercise names in Spanish",
                        isOn: Binding(
                            get: { prefs?.localizedExerciseNames ?? false },
                            set: { prefs?.localizedExerciseNames = $0; try? modelContext.save() }
                        )
                    )
                    
                    Divider().padding(.leading)
                }
                
                // Font Size
                SettingRow(title: "Font Size", subtitle: "Adjust text size") {
                    Picker("", selection: Binding(
                        get: { prefs?.fontSize ?? "normal" },
                        set: { prefs?.fontSize = $0; try? modelContext.save() }
                    )) {
                        Text("Normal").tag("normal")
                        Text("Large").tag("large")
                        Text("XL").tag("xl")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                
                Divider().padding(.leading)
                
                // Keep Screen Awake
                SettingToggleRow(
                    title: "Keep Screen Awake",
                    subtitle: "Prevent screen from dimming during workouts",
                    isOn: Binding(
                        get: { screenWakeManager.isAwake },
                        set: { screenWakeManager.toggle($0) }
                    )
                )
                
                Divider().padding(.leading)
                
                // Notifications
                SettingToggleRow(
                    title: "Notifications",
                    subtitle: notificationStatusText,
                    isOn: Binding(
                        get: { prefs?.notificationsEnabled ?? false },
                        set: { toggleNotifications($0) }
                    )
                )
                    .task {
                        _ = await refreshNotificationStatus()
                    }
                
                Divider().padding(.leading)
                
                // Voice
                SettingRow(title: "Voice", subtitle: "Text-to-speech for timers") {
                    VStack(spacing: 8) {
                        if #available(iOS 17.0, *) {
                            Picker("", selection: Binding(
                                get: { selectedVoiceURI },
                                set: { newValue in
                                    selectedVoiceURI = newValue
                                    prefs?.selectedVoiceURI = newValue
                                    try? modelContext.save()
                                }
                            )) {
                                Text("Default").tag(nil as String?)
                                ForEach(speechVoices, id: \.voiceURI) { voice in
                                    Text(voice.name).tag(voice.voiceURI as String?)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Menu("Select Voice") {
                                Button("Default") {
                                    selectedVoiceURI = nil
                                    prefs?.selectedVoiceURI = nil
                                    try? modelContext.save()
                                }
                                ForEach(speechVoices, id: \.voiceURI) { voice in
                                    Button(voice.name) {
                                        selectedVoiceURI = voice.voiceURI
                                        prefs?.selectedVoiceURI = voice.voiceURI
                                        try? modelContext.save()
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        Button("Play Sample") {
                            playVoiceSample()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Divider().padding(.leading)
                
                // Reset Onboarding
                Button {
                    hasCompletedOnboarding = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reset Onboarding")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                            Text("Show welcome screen again")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.red.opacity(0.6))
                    }
                    .padding()
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    @State private var notifEnabled = false
    @State private var notifStatus = "Not requested"
    
    private var languageDisplayText: String {
        switch appLanguage {
        case "en": return "English"
        case "es": return "Español"
        default: return "System"
        }
    }
    
    private var notificationStatusText: String {
        switch notifStatus {
        case "denied": return "Blocked in Settings"
        case "authorized": return "Enabled"
        default: return "Tap to enable"
        }
    }
    
    @MainActor
    private func toggleNotifications(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await NotificationUtils.requestPermission()
                await MainActor.run {
                    prefs?.notificationsEnabled = granted
                    notifEnabled = granted
                    notifStatus = granted ? "authorized" : "denied"
                    try? modelContext.save()
                }
            }
        } else {
            prefs?.notificationsEnabled = false
            notifEnabled = false
            try? modelContext.save()
        }
    }
    
    @MainActor
    private func refreshNotificationStatus() async -> String {
        let status = await NotificationUtils.currentStatus
        await MainActor.run {
            switch status {
            case .authorized: notifStatus = "authorized"
            case .denied: notifStatus = "denied"
            default: notifStatus = "notDetermined"
            }
            notifEnabled = status == .authorized || status == .provisional
        }
        return notifStatus
    }
    
    private func loadVoices() {
        let targetLanguage = appLanguage == "es" ? "es" : "en"
        speechVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(targetLanguage) }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
        selectedVoiceURI = prefs?.selectedVoiceURI
    }
    
    private func playVoiceSample() {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: "Rest time is over. Let's go!")
        utterance.rate = 0.5
        
        if let voiceURI = selectedVoiceURI,
           let voice = speechVoices.first(where: { $0.voiceURI == voiceURI }) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: appLanguage == "es" ? "es-ES" : "en-US")
        }
        synthesizer.speak(utterance)
    }
    
    // MARK: - About Tab
    
    private var aboutTabContent: some View {
        VStack(spacing: 20) {
            dataManagementSection
            cloudSyncSection
            shareAppSection
            
            // About
            VStack(alignment: .leading, spacing: 12) {
                Text("About")
                    .font(.headline)
                
                VStack(spacing: 1) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 40)
                        VStack(alignment: .leading) {
                            Text("Fortachon Gym")
                                .font(.subheadline)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Divider().padding(.leading)
                    
                    Link(destination: URL(string: "https://github.com/JuanchoGithub/fortachon-gym")!) {
                        HStack {
                            Image(systemName: "link")
                                .frame(width: 40)
                            Text("GitHub Repository")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Management")
                .font(.headline)
            
            VStack(spacing: 1) {
                // Export
                Button {
                    exportData()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Export Data")
                                .font(.subheadline)
                            Text("Backup your workout data as JSON")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.green)
                    }
                    .padding()
                }
                
                Divider().padding(.leading)
                
                // Import
                Button {
                    showImportPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import Data")
                                .font(.subheadline)
                            Text("Restore from a backup file")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "square.and.arrow.down")
                            .foregroundStyle(.blue)
                    }
                    .padding()
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ActivityViewController(activityItems: [url])
            }
        }
    }
    
    private var cloudSyncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cloud Sync")
                .font(.headline)
            
            VStack(spacing: 1) {
                // Sync status
                if let lastSync = CloudSyncService.getLastSyncTime() {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Last Synced")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatSyncTime(lastSync))
                                .font(.subheadline.monospacedDigit())
                        }
                        Spacer()
                        if isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: syncIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(syncIsError ? .red : .green)
                        }
                    }
                    .padding()
                }
                
                Divider().padding(.leading)
                
                // Sync buttons
                HStack(spacing: 12) {
                    Button {
                        uploadToCloud()
                    } label: {
                        HStack {
                            Image(systemName: "cloud.arrow.up")
                            Text("Upload")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSyncing)
                    
                    Button {
                        downloadFromCloud()
                    } label: {
                        HStack {
                            Image(systemName: "cloud.arrow.down")
                            Text("Download")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSyncing)
                }
                .padding()
                
                if let msg = syncMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(syncIsError ? .red : .green)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var shareAppSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share")
                .font(.headline)
            
            Button {
                shareApp()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share Fortachon Gym")
                            .font(.subheadline)
                        Text("Tell your friends about the app")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.green)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Import Confirm Sheet
    
    private var importConfirmationSheet: some View {
        NavigationStack {
            Form {
                if let summary = importSummary {
                    Section("Import Summary") {
                        LabeledContent("Workouts", value: "\(summary.workouts)")
                        LabeledContent("Routines", value: "\(summary.routines)")
                        LabeledContent("Exercises", value: "\(summary.exercises)")
                        LabeledContent("Weight Entries", value: "\(summary.weightEntries)")
                        LabeledContent("Settings", value: summary.hasSettings ? "Yes" : "No")
                        LabeledContent("Profile", value: summary.hasProfile ? "Yes" : "No")
                    }
                    
                    Section {
                        Text("This will merge the imported data with your existing data. Your current workouts and routines will not be lost.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Confirm Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showImportConfirm = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import") {
                        if let data = pendingImportData {
                            dataManager?.executeImport(data)
                        }
                        showImportConfirm = false
                    }
                    .fontWeight(.bold)
                    .disabled(dataManager?.isImporting == true)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func logBodyWeight() {
        guard let w = Double(bodyWeight), w > 0 else { return }
        let entry = WeightEntryM(weight: w, date: Date())
        modelContext.insert(entry)
        try? modelContext.save()
        bodyWeight = ""
    }
    
    private func generateUnlocks() -> [UnlockHistoryEntry] {
        var unlocks: [UnlockHistoryEntry] = []
        
        if totalWorkouts >= 1 {
            unlocks.append(UnlockHistoryEntry(
                id: "first",
                title: "First Workout",
                desc: "Completed your first workout",
                date: sessions.last?.startTime ?? Date(),
                icon: "star.fill"
            ))
        }
        
        if totalWorkouts >= 10 {
            unlocks.append(UnlockHistoryEntry(
                id: "ten",
                title: "Getting Serious",
                desc: "10 workouts completed",
                date: Date(),
                icon: "figure.strengthtraining.traditional"
            ))
        }
        
        if totalWorkouts >= 50 {
            unlocks.append(UnlockHistoryEntry(
                id: "fifty",
                title: "Half Century",
                desc: "50 workouts completed",
                date: Date(),
                icon: "trophy.fill"
            ))
        }
        
        if totalSets >= 1000 {
            unlocks.append(UnlockHistoryEntry(
                id: "thousand",
                title: "Iron Addict",
                desc: "1000 total sets completed",
                date: Date(),
                icon: "flame.fill"
            ))
        }
        
        return unlocks
    }
    
    private func exportData() {
        dataManager = DataImportExportManager(
            modelContext: modelContext,
            prefs: prefs,
            sessions: sessions,
            routines: [],
            exercises: exercises,
            weightEntries: sortedWeightEntries
        )
        
        if let url = dataManager?.exportData() {
            exportURL = url
            showExportSheet = true
        }
    }
    
    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            dataManager = DataImportExportManager(
                modelContext: modelContext,
                prefs: prefs,
                sessions: sessions,
                routines: [],
                exercises: exercises,
                weightEntries: sortedWeightEntries
            )
            
            if let importData = dataManager?.parseImportData(from: url) {
                pendingImportData = importData
                importSummary = dataManager?.previewImport(importData)
                showImportConfirm = true
            }
            
        case .failure(let error):
            importStatusMsg = DataImportExportManager.StatusMessage(
                title: "Import Error",
                message: error.localizedDescription,
                isError: true
            )
        }
    }
    
    private func uploadToCloud() {
        Task {
            await MainActor.run {
                isSyncing = true
                syncMessage = nil
                syncIsError = false
            }
            
            let syncData = buildSyncData()
            let response = await cloudSync.pushData(syncData)
            
            await MainActor.run {
                isSyncing = false
                if response.success {
                    syncMessage = "Synced successfully"
                    syncIsError = false
                } else {
                    syncMessage = response.error ?? "Sync failed"
                    syncIsError = true
                }
            }
        }
    }
    
    private func downloadFromCloud() {
        Task {
            await MainActor.run {
                isSyncing = true
                syncMessage = nil
                syncIsError = false
            }
            
            let lastSync = CloudSyncService.getLastSyncTime() ?? 0
            let response = await cloudSync.pullData(since: lastSync)
            
            await MainActor.run {
                isSyncing = false
                if response.success {
                    syncMessage = "Downloaded successfully"
                    syncIsError = false
                    // Process downloaded data
                    if let data = response.data {
                        applySyncData(data)
                    }
                } else {
                    syncMessage = response.error ?? "Download failed"
                    syncIsError = true
                }
            }
        }
    }
    
    private func buildSyncData() -> SyncData {
        return SyncData(
            history: nil, // Sessions handled separately
            routines: nil,
            exercises: nil,
            profile: UserPreferencesSync(gender: prefs?.gender, heightCm: prefs?.heightCm),
            settings: SettingsSync(
                measureUnit: prefs?.weightUnitStr ?? "kg",
                defaultRestTimes: RestTimesSync(
                    normal: prefs?.restNormal ?? 90,
                    warmup: prefs?.restWarmup ?? 60,
                    drop: prefs?.restDrop ?? 30,
                    timed: prefs?.restTimed ?? 10,
                    effort: prefs?.restEffort ?? 90,
                    failure: prefs?.restFailure ?? 300
                ),
                useLocalizedExerciseNames: prefs?.localizedExerciseNames ?? false,
                keepScreenAwake: screenWakeManager.isAwake,
                enableNotifications: prefs?.notificationsEnabled ?? false,
                selectedVoiceURI: prefs?.selectedVoiceURI,
                fontSize: prefs?.fontSize ?? "normal"
            ),
            weightEntries: sortedWeightEntries.map { WeightEntrySync(weight: $0.weight, date: $0.date.timeIntervalSince1970) }
        )
    }
    
    private func applySyncData(_ data: SyncData) {
        if let profile = data.profile {
            prefs?.gender = profile.gender
            prefs?.heightCm = profile.heightCm
        }
        
        if let settings = data.settings {
            prefs?.weightUnitStr = settings.measureUnit
            prefs?.fontSize = settings.fontSize
            prefs?.localizedExerciseNames = settings.useLocalizedExerciseNames
            prefs?.notificationsEnabled = settings.enableNotifications
            prefs?.selectedVoiceURI = settings.selectedVoiceURI
            screenWakeManager.toggle(settings.keepScreenAwake)
            
            if let restTimes = settings.defaultRestTimes {
                prefs?.restNormal = restTimes.normal
                prefs?.restWarmup = restTimes.warmup
                prefs?.restDrop = restTimes.drop
                prefs?.restTimed = restTimes.timed
                prefs?.restEffort = restTimes.effort
                prefs?.restFailure = restTimes.failure
            }
        }
        
        if let weightEntries = data.weightEntries {
            for entry in weightEntries {
                let existing = sortedWeightEntries.first { $0.weight == entry.weight && abs($0.date.timeIntervalSince1970 - entry.date) < 1 }
                if existing == nil {
                    let newEntry = WeightEntryM(weight: entry.weight, date: Date(timeIntervalSince1970: entry.date))
                    modelContext.insert(newEntry)
                }
            }
        }
        
        try? modelContext.save()
    }
    
    private func formatSyncTime(_ time: Double) -> String {
        let date = Date(timeIntervalSince1970: time)
        return date.formatted(date: .abbreviated, time: .shortened)
    }
    
    // MARK: - Load Settings & Analytics
    
    private func loadSettings() {
        selectedWeightUnit = prefs?.weightUnitStr ?? "kg"
        selectedGoal = prefs?.mainGoalStr ?? "muscle"
        if let height = prefs?.heightCm {
            heightCm = "\(Int(height))"
            let feet = Int(height) / 30
            let inches = (Int(height) - feet * 30) / 2
            heightFeet = "\(feet)"
            heightInches = "\(inches)"
        }
        selectedGender = prefs?.gender ?? ""
        bodyWeightDouble = currentBodyWeight
    }
    
    private func calculateAnalytics() {
        guard !sessions.isEmpty else { return }
        
        // Calculate LifterDNA
        let historyData = sessions.map { session in
            (
                startTime: session.startTime,
                endTime: session.endTime,
                exercises: session.exercises.map { ex in
                    (
                        exerciseId: ex.exerciseId,
                        sets: ex.sets.map { set in
                            (reps: set.reps, weight: set.weight, isComplete: set.isComplete, type: set.setTypeStr)
                        }
                    )
                }
            )
        }
        
        lifterStats = calculateLifterDNA(history: historyData, currentBodyWeight: currentBodyWeight)
        
        // Calculate Muscle Freshness
        let freshnessData = sessions.map { session in
            (
                startTime: session.startTime,
                exercises: session.exercises.map { ex in
                    (
                        exerciseId: ex.exerciseId,
                        sets: ex.sets.map { set in
                            (reps: set.reps, weight: set.weight, isComplete: set.isComplete)
                        }
                    )
                }
            )
        }
        
        muscleFreshness = calculateMuscleFreshness(history: freshnessData)
        
        // Calculate Strength Profile
        let strengthHistoryData = sessions.map { session in
            (
                startTime: session.startTime,
                exercises: session.exercises.map { ex in
                    (
                        exerciseId: ex.exerciseId,
                        sets: ex.sets.map { set in
                            (reps: set.reps, weight: set.weight, isComplete: set.isComplete, type: set.setTypeStr)
                        }
                    )
                }
            )
        }
        
        strengthProfile = calculateStrengthProfile(history: strengthHistoryData)
    }
    
    private func shareApp() {
        let url = URL(string: "https://fortachon.vercel.app")!
        let activityVC = UIActivityViewController(
            activityItems: ["Check out Fortachon Gym - the ultimate workout tracker! \(url)"],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Activity View Controller

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Enum

enum ProfileTab: String, CaseIterable, Identifiable {
    case profile
    case account
    case settings
    case about
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .profile: return "You"
        case .account: return "Account"
        case .settings: return "Settings"
        case .about: return "About"
        }
    }
}

// MARK: - Setting Toggle Row

struct SettingToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { _, newValue in
                    onChange?(newValue)
                }
        }
        .padding()
    }
}

// MARK: - Rest Timer Settings Sheet (uses UserPreferences)

struct RestTimerSettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let prefs: UserPreferencesM?
    
    @State private var normal: Int = 90
    @State private var warmup: Int = 60
    @State private var drop: Int = 30
    @State private var timed: Int = 10
    @State private var effort: Int = 90
    @State private var failure: Int = 300
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Default Rest Times") {
                    TimerSettingRow(title: "Working Sets", value: $normal, icon: "dumbbell", color: .blue)
                    TimerSettingRow(title: "Warm-up Sets", value: $warmup, icon: "sunrise", color: .orange)
                    TimerSettingRow(title: "Drop Sets", value: $drop, icon: "arrow.down.circle", color: .red)
                    TimerSettingRow(title: "Timed Sets", value: $timed, icon: "timer", color: .purple)
                    TimerSettingRow(title: "Effort Sets", value: $effort, icon: "flame", color: .orange)
                    TimerSettingRow(title: "Failure Recovery", value: $failure, icon: "bolt.fill", color: .yellow)
                }
                
                Section {
                    Text("These are the default rest times used when completing sets. You can override them per exercise during workouts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Rest Timers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveSettings(); dismiss() }
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                normal = prefs?.restNormal ?? 90
                warmup = prefs?.restWarmup ?? 60
                drop = prefs?.restDrop ?? 30
                timed = prefs?.restTimed ?? 10
                effort = prefs?.restEffort ?? 90
                failure = prefs?.restFailure ?? 300
            }
        }
    }
    
    private func saveSettings() {
        prefs?.restNormal = normal
        prefs?.restWarmup = warmup
        prefs?.restDrop = drop
        prefs?.restTimed = timed
        prefs?.restEffort = effort
        prefs?.restFailure = failure
        try? modelContext.save()
    }
}

// MARK: - Setting Row (generic container)

struct SettingRow<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            content()
        }
        .padding()
    }
}

// MARK: - Timer Setting Row

struct TimerSettingRow: View {
    let title: String
    @Binding var value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
            Spacer()
            Stepper(value: $value, in: 0...600, step: 5) {
                Text(formatTime(value))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - PR Card

struct PRCard: View {
    let exerciseId: String
    let exerciseName: String
    let sessions: [WorkoutSessionM]
    
    @State private var estimated1RM: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseName)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if estimated1RM > 0 {
                Text("\(Int(estimated1RM))")
                    .font(.title2.bold())
                    .foregroundStyle(.blue)
            } else {
                Text("--")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            Text("1RM est.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            calculate1RM()
        }
    }
    
    private func calculate1RM() {
        var max1RM: Double = 0
        
        for session in sessions {
            for exercise in session.exercises where exercise.exerciseId == exerciseId {
                for set in exercise.sets where set.isComplete && set.reps > 0 && set.weight > 0 {
                    let est = set.weight * (1.0 + Double(set.reps) / 30.0)
                    if est > max1RM {
                        max1RM = est
                    }
                }
            }
        }
        
        estimated1RM = max1RM
    }
}

// MARK: - Preview

#Preview {
    TabProfileView()
}