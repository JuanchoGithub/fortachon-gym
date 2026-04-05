import SwiftUI
import Charts
import SwiftData
import FortachonCore

// MARK: - Analytics Dashboard View

struct AnalyticsDashboardView: View {
    let sessions: [WorkoutSessionM]
    let exercises: [ExerciseM]
    @State private var selectedTab: AnalyticsTab = .overview
    @State private var oneRMTracker = OneRMTracker()
    @State private var streakCalculator = StreakCalculator()
    
    enum AnalyticsTab: String, CaseIterable {
        case overview = "Overview"
        case volume = "Volume"
        case consistency = "Consistency"
        case prs = "PRs"
    }
    
    // Calculate key metrics
    private var totalWorkouts: Int { sessions.count }
    private var totalVolume: Double {
        sessions.reduce(0) { total, session in
            total + session.exercises.reduce(0) { exTotal, ex in
                exTotal + ex.sets.filter { $0.isComplete }.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
            }
        }
    }
    private var averageDuration: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        var totalTime: TimeInterval = 0
        for session in sessions {
            totalTime += session.endTime.timeIntervalSince(session.startTime)
        }
        return totalTime / TimeInterval(sessions.count)
    }
    private var streakResult: StreakCalculator.StreakResult {
        streakCalculator.calculate(from: sessions.map { $0.startTime })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Tab picker
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    switch selectedTab {
                    case .overview:
                        overviewTab
                    case .volume:
                        volumeTab
                    case .consistency:
                        consistencyTab
                    case .prs:
                        prsTab
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        VStack(spacing: 16) {
            // Key metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(title: "Total Workouts", value: "\(totalWorkouts)", icon: "dumbbell", color: .blue)
                MetricCard(title: "Total Volume", value: "\(Int(totalVolume)) kg", icon: "chart.bar", color: .purple)
                MetricCard(title: "Avg Duration", value: formatDuration(averageDuration), icon: "clock", color: .green)
                MetricCard(title: "Current Streak", value: "\(streakResult.currentStreak) days", icon: "flame", color: .orange)
            }
            .padding(.horizontal)
            
            // Weekly consistency
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Consistency")
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack(spacing: 4) {
                    ForEach(0..<12, id: \.self) { week in
                        let met = week < Int(streakResult.monthlyConsistency / 100 * 12)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(met ? .green : .gray.opacity(0.3))
                            .frame(height: 30)
                    }
                }
                .padding(.horizontal)
                
                HStack {
                    Text("\(Int(streakResult.monthlyConsistency))% of weeks met goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Recent activity
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Workouts")
                    .font(.headline)
                    .padding(.horizontal)
                
                if sessions.isEmpty {
                    Text("No workouts yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                } else {
                    ForEach(sessions.prefix(5)) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(session.startTime.formatted())")
                                    .font(.subheadline)
                                Text("\(session.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(formatDuration(session.endTime.timeIntervalSince(session.startTime)))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // MARK: - Volume Tab
    
    private var volumeTab: some View {
        VolumeChartView(sessions: sessions)
            .padding(.horizontal)
    }
    
    // MARK: - Consistency Tab
    
    private var consistencyTab: some View {
        VStack(spacing: 16) {
            // Streak cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(title: "Current Streak", value: "\(streakResult.currentStreak) days", icon: "flame", color: .orange)
                MetricCard(title: "Longest Streak", value: "\(streakResult.longestStreak) days", icon: "trophy", color: .purple)
            }
            .padding(.horizontal)
            
            // Weekly consistency
            VStack(alignment: .leading, spacing: 8) {
                Text("Last 4 Weeks")
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack {
                    Text("\(Int(streakResult.weeklyConsistency))%")
                        .font(.title.bold())
                        .foregroundStyle(streakResult.weeklyConsistency >= 75 ? .green : .orange)
                    Spacer()
                    Text("of weeks met 3+ workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                ProgressView(value: streakResult.weeklyConsistency / 100)
                    .tint(streakResult.weeklyConsistency >= 75 ? .green : .orange)
                    .padding(.horizontal)
            }
            
            // Monthly consistency
            VStack(alignment: .leading, spacing: 8) {
                Text("Last 12 Weeks")
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack {
                    Text("\(Int(streakResult.monthlyConsistency))%")
                        .font(.title.bold())
                        .foregroundStyle(streakResult.monthlyConsistency >= 75 ? .green : .orange)
                    Spacer()
                    Text("of weeks met 3+ workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                ProgressView(value: streakResult.monthlyConsistency / 100)
                    .tint(streakResult.monthlyConsistency >= 75 ? .green : .orange)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - PRs Tab
    
    private var prsTab: some View {
        VStack(spacing: 16) {
            let latest1RMs = oneRMTracker.getLatest1RMs()
            
            if latest1RMs.isEmpty {
                ContentUnavailableView(
                    "No PRs Yet",
                    systemImage: "trophy",
                    description: Text("Complete workouts with progressive overload to set new PRs.")
                )
            } else {
                ForEach(Array(latest1RMs.values.sorted { $0.estimated1RM > $1.estimated1RM }), id: \.id) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.exerciseName)
                                .font(.headline)
                            Text("\(Int(record.weight)) kg × \(record.reps) reps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(record.estimated1RM)) kg")
                                .font(.title3.bold())
                                .foregroundStyle(.green)
                            Text("est. 1RM")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
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
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    AnalyticsDashboardView(sessions: [], exercises: [])
}