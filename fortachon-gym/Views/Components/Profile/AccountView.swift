import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Account View

struct AccountView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthService.shared
    @Query private var preferences: [UserPreferencesM]
    var prefs: UserPreferencesM? { preferences.first }
    @Query(sort: \WorkoutSessionM.startTime, order: .reverse) private var sessions: [WorkoutSessionM]
    @Query private var routines: [RoutineM]
    @Query private var exercises: [ExerciseM]
    @Query(sort: \WeightEntryM.date, order: .reverse) private var weightEntries: [WeightEntryM]
    
    // Auth form state
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true
    @State private var showLoginForm = false
    @State private var showSyncChoice = false
    
    // Sync state
    @State private var isSyncing = false
    @State private var syncMessage: String?
    @State private var syncIsError = false
    
    // Login conflict resolution
    @State private var showConflictDialog = false
    @State private var pendingCloudChoice: CloudChoice?
    
    enum CloudChoice {
        case useCloudData
        case pushLocalData
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if authService.isAuthenticated {
                // Logged in state
                loggedInView
            } else {
                // Logged out state
                loggedOutView
            }
            
            // Sync message alert
            if let message = syncMessage {
                VStack {
                    HStack {
                        Image(systemName: syncIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(syncIsError ? .red : .green)
                        Text(message)
                            .font(.caption)
                        Spacer()
                    }
                    .padding()
                    .background(syncIsError ? Color.red.opacity(0.1) : Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .sheet(isPresented: $showLoginForm) {
            AuthFormView(
                email: $email,
                password: $password,
                isLoginMode: $isLoginMode,
                authService: authService
            )
        }
        .alert("Sync Conflict", isPresented: $showConflictDialog) {
            Button("Use Cloud Data", role: .none) {
                syncChoice(useCloud: true)
            }
            Button("Keep Local Data", role: .none) {
                syncChoice(useCloud: false)
            }
            Button("Cancel", role: .cancel) {
                pendingCloudChoice = nil
            }
        } message: {
            Text("You already have local data. Do you want to download your cloud data or push your local data to the cloud?")
        }
    }
    
    // MARK: - Logged In View
    
    private var loggedInView: some View {
        VStack(spacing: 16) {
            // User info card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentUser?.email ?? "User")
                            .font(.headline)
                        if let lastSync = CloudSyncService.getLastSyncTime() {
                            Text("Last sync: \(formatSyncTime(lastSync))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Sync buttons
                HStack(spacing: 12) {
                    Button {
                        Task { await pushData() }
                    } label: {
                        HStack {
                            Image(systemName: "cloud.arrow.up")
                            Text("Upload")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSyncing || !authService.isAuthenticated)
                    
                    Button {
                        Task { await pullData() }
                    } label: {
                        HStack {
                            Image(systemName: "cloud.arrow.down")
                            Text("Download")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSyncing || !authService.isAuthenticated)
                }
                
                if isSyncing {
                    ProgressView("Syncing...")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            // Logout button
            Button(role: .destructive) {
                authService.logout()
                syncMessage = nil
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Logged Out View
    
    private var loggedOutView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.badge.key")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
            
            VStack(spacing: 8) {
                Text("Sign in to Sync Your Data")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                
                Text("Create an account or sign in to backup your workout data and sync across devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                isLoginMode = true
                showLoginForm = true
            } label: {
                Label("Sign In", systemImage: "arrow.right.circle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            
            Button {
                isLoginMode = false
                showLoginForm = true
            } label: {
                Label("Create Account", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Sync Actions
    
    private func pushData() async {
        guard authService.isAuthenticated else { return }
        
        await MainActor.run {
            isSyncing = true
            syncMessage = nil
            syncIsError = false
        }
        
        // Check if user has local data that should trigger a conflict dialog
        let hasLocalData = !sessions.isEmpty || !routines.isEmpty
        
        if hasLocalData && CloudSyncService.getLastSyncTime() == nil {
            await MainActor.run {
                pendingCloudChoice = .pushLocalData
                showConflictDialog = true
                isSyncing = false
            }
            return
        }
        
        await executePush()
    }
    
    private func executePush() async {
        // Build sync data
        let syncData = buildSyncData()
        
        let response = await authService.pushData(syncData)
        
        await MainActor.run {
            isSyncing = false
            if response.success {
                syncMessage = "Upload successful"
                syncIsError = false
            } else {
                syncMessage = response.error ?? "Upload failed"
                syncIsError = true
            }
        }
    }
    
    private func pullData() async {
        guard authService.isAuthenticated else { return }
        
        await MainActor.run {
            isSyncing = true
            syncMessage = nil
            syncIsError = false
        }
        
        let hasLocalData = !sessions.isEmpty || !routines.isEmpty
        
        if hasLocalData && CloudSyncService.getLastSyncTime() == nil {
            await MainActor.run {
                pendingCloudChoice = .useCloudData
                showConflictDialog = true
                isSyncing = false
            }
            return
        }
        
        await executePull()
    }
    
    private func executePull() async {
        let lastSync = CloudSyncService.getLastSyncTime() ?? 0
        let response = await authService.pullData(since: lastSync)
        
        await MainActor.run {
            isSyncing = false
            if response.success, let data = response.data {
                applySyncData(data)
                syncMessage = "Download successful"
                syncIsError = false
                if let lastUpdated = response.lastUpdated {
                    CloudSyncService.setLastSyncTime(lastUpdated)
                }
            } else {
                syncMessage = response.error ?? "Download failed"
                syncIsError = true
            }
        }
    }
    
    private func syncChoice(useCloud: Bool) {
        if useCloud {
            Task { await executePull() }
        } else {
            Task { await executePush() }
        }
        pendingCloudChoice = nil
    }
    
    private func buildSyncData() -> SyncData {
        let p = prefs ?? UserPreferencesM()
        return SyncData(
            history: nil,
            routines: nil,
            exercises: nil,
            profile: UserPreferencesSync(gender: p.gender, heightCm: p.heightCm),
            settings: SettingsSync(
                measureUnit: p.weightUnitStr,
                defaultRestTimes: RestTimesSync(
                    normal: p.restNormal,
                    warmup: p.restWarmup,
                    drop: p.restDrop,
                    timed: p.restTimed,
                    effort: p.restEffort,
                    failure: p.restFailure
                ),
                useLocalizedExerciseNames: p.localizedExerciseNames,
                keepScreenAwake: ScreenWakeManager.shared.isAwake,
                enableNotifications: p.notificationsEnabled,
                selectedVoiceURI: p.selectedVoiceURI,
                fontSize: p.fontSize
            ),
            weightEntries: weightEntries.map { WeightEntrySync(weight: $0.weight, date: $0.date.timeIntervalSince1970) }
        )
    }
    
    private func applySyncData(_ data: SyncData) {
        guard let p = prefs else { return }
        
        if let profile = data.profile {
            p.gender = profile.gender
            p.heightCm = profile.heightCm
        }
        
        if let settings = data.settings {
            p.weightUnitStr = settings.measureUnit
            p.fontSize = settings.fontSize
            p.localizedExerciseNames = settings.useLocalizedExerciseNames
            p.notificationsEnabled = settings.enableNotifications
            p.selectedVoiceURI = settings.selectedVoiceURI
            ScreenWakeManager.shared.toggle(settings.keepScreenAwake)
            
            if let restTimes = settings.defaultRestTimes {
                p.restNormal = restTimes.normal
                p.restWarmup = restTimes.warmup
                p.restDrop = restTimes.drop
                p.restTimed = restTimes.timed
                p.restEffort = restTimes.effort
                p.restFailure = restTimes.failure
            }
        }
        
        if let weightEntries = data.weightEntries {
            for entry in weightEntries {
                let date = Date(timeIntervalSince1970: entry.date)
                let existing = self.weightEntries.first { $0.weight == entry.weight && abs($0.date.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate) < 1 }
                if existing == nil {
                    let newEntry = WeightEntryM(weight: entry.weight, date: date)
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
}

// MARK: - Auth Form View

struct AuthFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoginMode: Bool
    @ObservedObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                } header: {
                    Text(isLoginMode ? "Sign In" : "Create Account")
                }
                
                if let error = authService.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isLoginMode ? "Sign In" : "Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isLoginMode ? "Sign In" : "Register") {
                        Task {
                            if isLoginMode {
                                let success = await authService.login(email: email, password: password)
                                if success { dismiss() }
                            } else {
                                let success = await authService.register(email: email, password: password)
                                if success { dismiss() }
                            }
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                }
            }
        }
    }
}

#Preview {
    AccountView()
}