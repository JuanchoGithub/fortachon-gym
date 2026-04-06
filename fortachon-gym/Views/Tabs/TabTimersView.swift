import SwiftUI

// MARK: - Timers Tab View

struct TabTimersView: View {
    @State private var selectedTimer: TimerType?
    
    enum TimerType: String, CaseIterable, Identifiable {
        case emom = "EMOM"
        case amrap = "AMRAP"
        case tabata = "Tabata"
        case hiit = "HIIT"
        case custom = "Custom"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .emom: "timer"
            case .amrap: "repeat"
            case .tabata: "flame.fill"
            case .hiit: "bolt.fill"
            case .custom: "slider.horizontal.3"
            }
        }
        
        var description: String {
            switch self {
            case .emom: "Every Minute On the Minute"
            case .amrap: "As Many Rounds As Possible"
            case .tabata: "20s work / 10s rest intervals"
            case .hiit: "High Intensity Interval Training"
            case .custom: "Create your own timer"
            }
        }
        
        var color: Color {
            switch self {
            case .emom: .blue
            case .amrap: .green
            case .tabata: .orange
            case .hiit: .red
            case .custom: .purple
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timers")
                            .font(.largeTitle.bold())
                        Text("Choose a timer type to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Timer Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(TimerType.allCases) { timer in
                            TimerCard(
                                timer: timer,
                                onTap: { selectedTimer = timer }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Timers Section
                    RecentTimersSection()
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Timers")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedTimer) { timer in
                switch timer {
                case .emom:
                    EMOMTimerView()
                        .presentationDetents([.large])
                case .amrap:
                    AMRAPTimerView()
                        .presentationDetents([.large])
                case .tabata:
                    TabataTimerView()
                        .presentationDetents([.large])
                case .hiit:
                    HIITTimerView()
                        .presentationDetents([.large])
                case .custom:
                    CustomTimerView()
                        .presentationDetents([.large])
                }
            }
        }
    }
}

// MARK: - Timer Card

struct TimerCard: View {
    let timer: TabTimersView.TimerType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(timer.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: timer.icon)
                        .font(.title2)
                        .foregroundStyle(timer.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(timer.rawValue)
                        .font(.headline)
                    Text(timer.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack {
                    Text("Start")
                        .font(.caption.bold())
                        .foregroundStyle(timer.color)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(timer.color)
                }
            }
            .padding()
            .frame(height: 160)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Recent Timers Section

struct RecentTimersSection: View {
    // Placeholder for recent timers history
    @State private var recentTimers: [String] = []
    
    var body: some View {
        if recentTimers.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary.opacity(0.5))
                Text("No Recent Timers")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Your recent timer sessions will appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

// MARK: - EMOM Timer View

struct EMOMTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var minutes: Int = 10
    @State private var isRunning = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var currentMinute: Int = 0
    @State private var timerTask: Task<Void, Never>?
    @State private var soundEffects = SoundEffectsService()
    @State private var countdownHapticPhase = 0
    @State private var minuteEndHapticPhase = 0
    @State private var completionHapticPhase = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Minute display
                Text("\(currentMinute + 1)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(isRunning ? .blue : .primary)
                
                Text("of \(minutes) minutes")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                // Time remaining in current minute
                if isRunning {
                    Text(timeRemaining.formattedAsTimer)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(timeRemaining <= 3 ? .red : .primary)
                }
                
                // Minute selector
                if !isRunning {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.headline)
                        
                        Stepper("\(minutes) minutes", value: $minutes, in: 1...60)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 24) {
                    if isRunning {
                        Button {
                            toggleTimer()
                        } label: {
                            VStack {
                                Image(systemName: "pause.fill")
                                    .font(.title)
                                Text("Pause")
                                    .font(.caption)
                            }
                            .frame(width: 100)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button {
                            stopTimer()
                        } label: {
                            VStack {
                                Image(systemName: "stop.fill")
                                    .font(.title)
                                Text("Stop")
                                    .font(.caption)
                            }
                            .frame(width: 100)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        Button {
                            startTimer()
                        } label: {
                            VStack {
                                Image(systemName: "play.fill")
                                    .font(.title)
                                Text("Start")
                                    .font(.caption)
                            }
                            .frame(width: 120)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("EMOM Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear { timerTask?.cancel() }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: countdownHapticPhase)
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: minuteEndHapticPhase)
            .sensoryFeedback(.success, trigger: completionHapticPhase)
        }
    }
    
    private func startTimer() {
        isRunning = true
        currentMinute = 0
        timeRemaining = 60
        soundEffects.playTimedSetStart()
        
        timerTask = Task {
            while !Task.isCancelled && currentMinute < minutes {
                let end = Date().addingTimeInterval(timeRemaining)
                while !Task.isCancelled && timeRemaining > 0 {
                    do {
                        try await Task.sleep(for: .milliseconds(100))
                    } catch { break }
                    timeRemaining = max(0, end.timeIntervalSinceNow)
                    
                    if timeRemaining <= 3 && timeRemaining > 0 && Int(timeRemaining) != Int(timeRemaining + 0.1) {
                        soundEffects.playCountdownBeep()
                        if !reduceMotion { countdownHapticPhase += 1 }
                    }
                }
                
                if !Task.isCancelled && currentMinute < minutes - 1 {
                    soundEffects.playRestTimerEnd()
                    if !reduceMotion { minuteEndHapticPhase += 1 }
                    currentMinute += 1
                    timeRemaining = 60
                } else {
                    break
                }
            }
            
            if !Task.isCancelled {
                soundEffects.playPRCelebration()
                if !reduceMotion { completionHapticPhase += 1 }
                isRunning = false
            }
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            timerTask?.cancel()
            isRunning = false
        } else {
            startTimer()
        }
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        isRunning = false
        currentMinute = 0
        timeRemaining = 0
    }
}

// MARK: - AMRAP Timer View

struct AMRAPTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var durationMinutes: Int = 10
    @State private var isRunning = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var rounds: Int = 0
    @State private var timerTask: Task<Void, Never>?
    @State private var soundEffects = SoundEffectsService()
    @State private var countdownHapticPhase = 0
    @State private var roundLogHapticPhase = 0
    @State private var completionHapticPhase = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Time display
                Text(timeRemaining.formattedAsTimer)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundStyle(isRunning ? (timeRemaining <= 30 ? .red : .blue) : .primary)
                
                // Rounds counter
                if isRunning {
                    VStack(spacing: 8) {
                        Text("Rounds")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("\(rounds)")
                            .font(.system(size: 64, weight: .bold))
                    }
                    
                    Button {
                        rounds += 1
                        soundEffects.playBlip()
                        if !reduceMotion { roundLogHapticPhase += 1 }
                    } label: {
                        Label("Log Round", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Duration selector
                if !isRunning {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.headline)
                        
                        Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 1...60)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 24) {
                    if isRunning {
                        Button {
                            timerTask?.cancel()
                            isRunning = false
                        } label: {
                            VStack {
                                Image(systemName: "pause.fill")
                                    .font(.title)
                                Text("Pause")
                                    .font(.caption)
                            }
                            .frame(width: 100)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        Button {
                            startTimer()
                        } label: {
                            VStack {
                                Image(systemName: "play.fill")
                                    .font(.title)
                                Text("Start")
                                    .font(.caption)
                            }
                            .frame(width: 120)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("AMRAP Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear { timerTask?.cancel() }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: countdownHapticPhase)
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: roundLogHapticPhase)
            .sensoryFeedback(.success, trigger: completionHapticPhase)
        }
    }
    
    private func startTimer() {
        isRunning = true
        timeRemaining = TimeInterval(durationMinutes * 60)
        rounds = 0
        soundEffects.playTimedSetStart()
        
        let end = Date().addingTimeInterval(timeRemaining)
        timerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch { break }
                timeRemaining = max(0, end.timeIntervalSinceNow)
                
                if timeRemaining <= 3 && timeRemaining > 0 && Int(timeRemaining) != Int(timeRemaining + 0.1) {
                    soundEffects.playCountdownBeep()
                    if !reduceMotion { countdownHapticPhase += 1 }
                }
            }
            
            if !Task.isCancelled {
                soundEffects.playPRCelebration()
                if !reduceMotion { completionHapticPhase += 1 }
                isRunning = false
            }
        }
    }
}

// MARK: - Tabata Timer View

struct TabataTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rounds: Int = 8
    @State private var workTime: Int = 20
    @State private var restTime: Int = 10
    @State private var isRunning = false
    @State private var currentRound: Int = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var isWorkPhase: Bool = true
    @State private var timerTask: Task<Void, Never>?
    @State private var soundEffects = SoundEffectsService()
    @State private var countdownHapticPhase = 0
    @State private var phaseChangeHapticPhase = 0
    @State private var completionHapticPhase = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Phase indicator
                Text(isWorkPhase ? "WORK" : "REST")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(isWorkPhase ? .red : .green)
                
                // Time display
                Text(timeRemaining.formattedAsTimer)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundStyle(isWorkPhase ? .red : .green)
                
                // Round counter
                Text("Round \(currentRound + 1) of \(rounds)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<rounds, id: \.self) { i in
                        Circle()
                            .fill(i < currentRound ? .green : (i == currentRound ? .blue : .gray.opacity(0.3)))
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Settings
                if !isRunning {
                    VStack(spacing: 12) {
                        Stepper("Rounds: \(rounds)", value: $rounds, in: 1...20)
                        Stepper("Work: \(workTime)s", value: $workTime, in: 5...60)
                        Stepper("Rest: \(restTime)s", value: $restTime, in: 5...60)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                Spacer()
                
                // Controls
                if !isRunning {
                    Button {
                        startTimer()
                    } label: {
                        VStack {
                            Image(systemName: "play.fill")
                                .font(.title)
                            Text("Start")
                                .font(.caption)
                        }
                        .frame(width: 120)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Button {
                        timerTask?.cancel()
                        isRunning = false
                    } label: {
                        VStack {
                            Image(systemName: "stop.fill")
                                .font(.title)
                            Text("Stop")
                                .font(.caption)
                        }
                        .frame(width: 120)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding()
            .navigationTitle("Tabata Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear { timerTask?.cancel() }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: countdownHapticPhase)
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: phaseChangeHapticPhase)
            .sensoryFeedback(.success, trigger: completionHapticPhase)
        }
    }
    
    private func startTimer() {
        isRunning = true
        currentRound = 0
        isWorkPhase = true
        timeRemaining = TimeInterval(workTime)
        soundEffects.playTimedSetStart()
        
        timerTask = Task {
            while !Task.isCancelled && currentRound < rounds {
                let phaseTime = isWorkPhase ? workTime : restTime
                let end = Date().addingTimeInterval(timeRemaining)
                
                while !Task.isCancelled && timeRemaining > 0 {
                    do {
                        try await Task.sleep(for: .milliseconds(100))
                    } catch { break }
                    timeRemaining = max(0, end.timeIntervalSinceNow)
                    
                    if timeRemaining <= 3 && timeRemaining > 0 && Int(timeRemaining) != Int(timeRemaining + 0.1) {
                        soundEffects.playCountdownBeep()
                        if !reduceMotion { countdownHapticPhase += 1 }
                    }
                }
                
                if !Task.isCancelled {
                    if isWorkPhase {
                        // Switch to rest
                        isWorkPhase = false
                        timeRemaining = TimeInterval(restTime)
                        soundEffects.playRestTimerEnd()
                        if !reduceMotion { phaseChangeHapticPhase += 1 }
                    } else {
                        // Next round
                        currentRound += 1
                        if currentRound < rounds {
                            isWorkPhase = true
                            timeRemaining = TimeInterval(workTime)
                            soundEffects.playRestTimerEnd()
                            if !reduceMotion { phaseChangeHapticPhase += 1 }
                        }
                    }
                }
            }
            
            if !Task.isCancelled {
                soundEffects.playPRCelebration()
                if !reduceMotion { completionHapticPhase += 1 }
                isRunning = false
            }
        }
    }
}

// MARK: - HIIT Timer View

struct HIITTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var workTime: Int = 30
    @State private var restTime: Int = 15
    @State private var prepTime: Int = 5
    @State private var rounds: Int = 8
    @State private var isRunning = false
    @State private var currentRound: Int = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var phase: HIITPhase = .prep
    @State private var timerTask: Task<Void, Never>?
    @State private var soundEffects = SoundEffectsService()
    @State private var countdownHapticPhase = 0
    @State private var phaseChangeHapticPhase = 0
    @State private var completionHapticPhase = 0
    
    enum HIITPhase {
        case prep, work, rest, done
        
        var label: String {
            switch self {
            case .prep: "Get Ready"
            case .work: "WORK"
            case .rest: "REST"
            case .done: "Done!"
            }
        }
        
        var color: Color {
            switch self {
            case .prep: .orange
            case .work: .red
            case .rest: .green
            case .done: .blue
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Phase indicator
                Text(phase.label)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(phase.color)
                
                // Time display
                Text(timeRemaining.formattedAsTimer)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundStyle(phase.color)
                
                // Round counter
                if phase != .prep && phase != .done {
                    Text("Round \(currentRound + 1) of \(rounds)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Settings
                if !isRunning {
                    VStack(spacing: 12) {
                        Stepper("Prep: \(prepTime)s", value: $prepTime, in: 0...30)
                        Stepper("Work: \(workTime)s", value: $workTime, in: 5...120)
                        Stepper("Rest: \(restTime)s", value: $restTime, in: 5...60)
                        Stepper("Rounds: \(rounds)", value: $rounds, in: 1...30)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                Spacer()
                
                // Controls
                if !isRunning {
                    Button {
                        startTimer()
                    } label: {
                        VStack {
                            Image(systemName: "play.fill")
                                .font(.title)
                            Text("Start")
                                .font(.caption)
                        }
                        .frame(width: 120)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Button {
                        timerTask?.cancel()
                        isRunning = false
                        phase = .done
                    } label: {
                        VStack {
                            Image(systemName: "stop.fill")
                                .font(.title)
                            Text("Stop")
                                .font(.caption)
                        }
                        .frame(width: 120)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding()
            .navigationTitle("HIIT Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear { timerTask?.cancel() }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: countdownHapticPhase)
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: phaseChangeHapticPhase)
            .sensoryFeedback(.success, trigger: completionHapticPhase)
        }
    }
    
    private func startTimer() {
        isRunning = true
        phase = .prep
        currentRound = 0
        timeRemaining = TimeInterval(prepTime)
        soundEffects.playTimedSetStart()
        
        timerTask = Task {
            // Prep phase
            if prepTime > 0 {
                await runPhase(duration: prepTime)
            }
            
            // Work/Rest rounds
            while !Task.isCancelled && currentRound < rounds {
                // Work
                phase = .work
                timeRemaining = TimeInterval(workTime)
                soundEffects.playTimedSetStart()
                await runPhase(duration: workTime)
                
                if !Task.isCancelled && currentRound < rounds - 1 {
                    // Rest
                    phase = .rest
                    timeRemaining = TimeInterval(restTime)
                    soundEffects.playRestTimerEnd()
                    await runPhase(duration: restTime)
                    currentRound += 1
                } else {
                    currentRound += 1
                }
            }
            
            if !Task.isCancelled {
                phase = .done
                soundEffects.playPRCelebration()
                isRunning = false
            }
        }
    }
    
    private func runPhase(duration: Int) async {
        timeRemaining = TimeInterval(duration)
        let end = Date().addingTimeInterval(timeRemaining)
        
        while !Task.isCancelled && timeRemaining > 0 {
            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch { break }
            timeRemaining = max(0, end.timeIntervalSinceNow)
            
            if timeRemaining <= 3 && timeRemaining > 0 && Int(timeRemaining) != Int(timeRemaining + 0.1) {
                soundEffects.playCountdownBeep()
                if !reduceMotion { countdownHapticPhase += 1 }
            }
        }
    }
}

// MARK: - Custom Timer View

struct CustomTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hours: Int = 0
    @State private var minutes: Int = 5
    @State private var seconds: Int = 0
    @State private var isRunning = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timerTask: Task<Void, Never>?
    @State private var soundEffects = SoundEffectsService()
    @State private var countdownHapticPhase = 0
    @State private var completionHapticPhase = 0
    
    var totalTime: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Time display
                Text(timeRemaining > 0 ? timeRemaining.formattedAsTimer : "00:00")
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundStyle(isRunning ? (timeRemaining <= 10 ? .red : .blue) : .primary)
                
                // Time pickers
                if !isRunning {
                    HStack(spacing: 16) {
                        TimePicker(label: "Hours", value: $hours, range: 0...23)
                        TimePicker(label: "Minutes", value: $minutes, range: 0...59)
                        TimePicker(label: "Seconds", value: $seconds, range: 0...59)
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 24) {
                    if isRunning {
                        Button {
                            timerTask?.cancel()
                            isRunning = false
                        } label: {
                            VStack {
                                Image(systemName: "pause.fill")
                                    .font(.title)
                                Text("Pause")
                                    .font(.caption)
                            }
                            .frame(width: 100)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button {
                            timeRemaining = 0
                            timerTask?.cancel()
                            isRunning = false
                        } label: {
                            VStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title)
                                Text("Reset")
                                    .font(.caption)
                            }
                            .frame(width: 100)
                            .padding(.vertical, 16)
                            .background(Color.gray)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        Button {
                            startTimer()
                        } label: {
                            VStack {
                                Image(systemName: "play.fill")
                                    .font(.title)
                                Text("Start")
                                    .font(.caption)
                            }
                            .frame(width: 120)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Custom Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear { timerTask?.cancel() }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: countdownHapticPhase)
            .sensoryFeedback(.success, trigger: completionHapticPhase)
        }
    }
    
    private func startTimer() {
        timeRemaining = totalTime
        guard timeRemaining > 0 else { return }
        
        isRunning = true
        soundEffects.playTimedSetStart()
        
        let end = Date().addingTimeInterval(timeRemaining)
        timerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch { break }
                timeRemaining = max(0, end.timeIntervalSinceNow)
                
                if timeRemaining <= 3 && timeRemaining > 0 && Int(timeRemaining) != Int(timeRemaining + 0.1) {
                    soundEffects.playCountdownBeep()
                    if !reduceMotion { countdownHapticPhase += 1 }
                }
            }
            
            if !Task.isCancelled {
                soundEffects.playRestTimerEnd()
                if !reduceMotion { completionHapticPhase += 1 }
                isRunning = false
            }
        }
    }
}

// MARK: - Time Picker Component

struct TimePicker: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Stepper(value: $value, in: range) {
                Text("\(value)")
                    .font(.title2.monospacedDigit())
                    .frame(width: 50)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    TabTimersView()
}