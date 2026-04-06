import SwiftUI
import SwiftData
import FortachonCore

struct TabHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSessionM.startTime, order: .reverse) private var sessions: [WorkoutSessionM]
    @Query private var allExercises: [ExerciseM]
    @State private var selectedSession: WorkoutSessionM?
    @State private var searchQuery = ""
    @State private var showFilters = false
    @State private var showExportSheet = false
    @State private var selectedDateRange: DateRange = .all
    @State private var selectedMuscleGroup: String?
    @State private var showAnalytics = false
    
    enum DateRange: String, CaseIterable {
        case all = "All Time"
        case week = "This Week"
        case month = "This Month"
        case quarter = "Last 3 Months"
        
        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .all: return nil
            case .week: return calendar.date(byAdding: .day, value: -7, to: Date())
            case .month: return calendar.date(byAdding: .month, value: -1, to: Date())
            case .quarter: return calendar.date(byAdding: .month, value: -3, to: Date())
            }
        }
    }
    
    var filteredSessions: [WorkoutSessionM] {
        var result = sessions
        
        // Search filter
        if !searchQuery.isEmpty {
            result = result.filter { $0.routineName.localizedCaseInsensitiveContains(searchQuery) }
        }
        
        // Date range filter
        if let startDate = selectedDateRange.startDate {
            result = result.filter { $0.startTime >= startDate }
        }
        
        // Muscle group filter (basic - filters by exercise name containing muscle)
        if let muscle = selectedMuscleGroup {
            result = result.filter { session in
                session.exercises.contains { ex in
                    ex.exerciseId.localizedCaseInsensitiveContains(muscle)
                }
            }
        }
        
        return result
    }
    
    // Group by date
    var groupedSessions: [String: [WorkoutSessionM]] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        var grouped: [String: [WorkoutSessionM]] = [:]
        for session in filteredSessions {
            let key = formatter.string(from: session.startTime)
            if grouped[key] == nil {
                grouped[key] = []
            }
            grouped[key]?.append(session)
        }
        return grouped
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats Summary
                if !sessions.isEmpty {
                    HistorySummaryView(sessions: sessions)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    
                    // Volume Chart
                    VolumeChartView(sessions: sessions)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }
                
                // Search and Filters
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search workouts...", text: $searchQuery)
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
                    
                    // Filter buttons
                    HStack(spacing: 8) {
                        Menu {
                            Picker("Date Range", selection: $selectedDateRange) {
                                ForEach(DateRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(selectedDateRange.rawValue)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Button {
                            showFilters = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.caption)
                                Text("Filters")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Spacer()
                        
                        // Analytics button
                        Button {
                            showAnalytics = true
                        } label: {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                                .padding(8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Export button
                        Button {
                            showExportSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                                .padding(8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Active filters indicator
                if selectedDateRange != .all || selectedMuscleGroup != nil {
                    HStack {
                        Label("Filters Active", systemImage: "line.3.horizontal.decrease.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Spacer()
                        Button("Clear") {
                            selectedDateRange = .all
                            selectedMuscleGroup = nil
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
                
                // Sessions List
                List {
                    if sessions.isEmpty {
                        ContentUnavailableView(
                            "No Workouts Yet",
                            systemImage: "figure.strengthtraining.traditional",
                            description: Text("Start your first workout to see your training history here.")
                        )
                    } else {
                        ForEach(groupedSessions.sorted(by: { $0.key > $1.key }), id: \.key) { date, dateSessions in
                            Section(date) {
                                ForEach(dateSessions) { session in
                                    HistorySessionRow(session: session)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedSession = session
                                        }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .sheet(isPresented: $showFilters) {
                HistoryFilterSheet(
                    filters: .constant(HistoryFilterOptions()),
                    onApply: { _ in showFilters = false }
                )
            }
            .sheet(isPresented: $showAnalytics) {
                AnalyticsDashboardView(
                    sessions: sessions,
                    exercises: allExercises
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showExportSheet) {
                ExportDataView(
                    sessions: filteredSessions,
                    isPresented: $showExportSheet
                )
            }
        }
    }
}

// MARK: - History Summary

struct HistorySummaryView: View {
    let sessions: [WorkoutSessionM]
    
    var totalWorkouts: Int { sessions.count }
    
    var latestWeekWorkouts: Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startTime > oneWeekAgo }.count
    }
    
    var totalSets: Int {
        sessions.reduce(0) { sum, session in
            sum + session.exercises.reduce(0) { exSum, ex in
                exSum + ex.sets.count
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            SummaryStatCard(
                title: "Workouts",
                value: "\(totalWorkouts)",
                icon: "figure.strengthtraining.traditional",
                color: .blue
            )
            SummaryStatCard(
                title: "This Week",
                value: "\(latestWeekWorkouts)",
                icon: "calendar",
                color: .green
            )
            SummaryStatCard(
                title: "Total Sets",
                value: "\(totalSets)",
                icon: "list.number",
                color: .orange
            )
        }
    }
}

struct SummaryStatCard: View {
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

// MARK: - Session Row

struct HistorySessionRow: View {
    let session: WorkoutSessionM
    
    private var duration: String {
        let interval = session.endTime.timeIntervalSince(session.startTime)
        let minutes = Int(interval / 60)
        return "\(minutes)m"
    }
    
    private var exerciseCount: String {
        "\(session.exercises.count)"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.routineName)
                    .font(.headline)
                HStack(spacing: 12) {
                    Label(duration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label(exerciseCount + " exercises", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if session.prCount > 0 {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Session Detail

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSessionM
    
    private var duration: String {
        let interval = session.endTime.timeIntervalSince(session.startTime)
        let minutes = Int(interval / 60)
        return "\(minutes) min"
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Session Info") {
                    LabeledContent("Date", value: dateFormatter.string(from: session.startTime))
                    LabeledContent("Duration", value: duration)
                    LabeledContent("Routine", value: session.routineName)
                    if session.prCount > 0 {
                        LabeledContent("PRs", value: "\(session.prCount)")
                    }
                }
                
                Section("Exercises") {
                    ForEach(session.exercises) { ex in
                        HStack {
                            Text(ex.exerciseId)
                            Spacer()
                            Text("\(ex.sets.count) sets")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(session.routineName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TabHistoryView()
}