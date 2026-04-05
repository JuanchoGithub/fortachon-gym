import SwiftUI
import SwiftData
import FortachonCore

struct TabHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSessionM.startTime, order: .reverse) private var sessions: [WorkoutSessionM]
    @State private var selectedSession: WorkoutSessionM?
    @State private var searchQuery = ""
    
    var filteredSessions: [WorkoutSessionM] {
        if searchQuery.isEmpty {
            return sessions
        }
        return sessions.filter { $0.routineName.localizedCaseInsensitiveContains(searchQuery) }
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
                }
                
                // Search
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
                .padding(.horizontal)
                .padding(.bottom, 8)
                
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