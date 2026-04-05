import SwiftUI
import FortachonCore

// MARK: - Supplement History Modal

struct SupplementHistoryModal: View {
    @Environment(\.dismiss) private var dismiss
    let item: SupplementLogM
    
    @State private var selectedPeriod: HistoryPeriod = .month
    
    enum HistoryPeriod: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        
        var id: String { rawValue }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Stats Summary
                Section("Summary") {
                    HStack(spacing: 16) {
                        statCard(
                            title: "Taken",
                            value: String(takenCount(in: selectedPeriod.days)),
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        statCard(
                            title: "Missed",
                            value: String(missedCount(in: selectedPeriod.days)),
                            icon: "xmark.circle.fill",
                            color: .red
                        )
                        statCard(
                            title: "Rate",
                            value: adherenceRateString(in: selectedPeriod.days),
                            icon: "percent",
                            color: .cyan
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                // Period Selector
                Section("Time Period") {
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(HistoryPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Calendar Heatmap
                Section("History") {
                    CalendarHeatmapView(
                        item: item,
                        days: selectedPeriod.days
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // Detailed List
                Section("Recent Entries") {
                    let recentDates = recentTakenDates(in: selectedPeriod.days)
                    if recentDates.isEmpty {
                        ContentUnavailableView(
                            "No History",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("No entries in this period")
                        )
                    } else {
                        ForEach(recentDates, id: \.self) { date in
                            HStack {
                                Text(date, style: .date)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func takenCount(in days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return item.takenHistory.filter { $0 >= cutoff }.count
    }
    
    private func missedCount(in days: Int) -> Int {
        let taken = takenCount(in: days)
        return max(0, days - taken)
    }
    
    private func adherenceRateString(in days: Int) -> String {
        let taken = takenCount(in: days)
        let rate = days > 0 ? Double(taken) / Double(days) * 100 : 0
        return String(format: "%.0f%%", min(rate, 100))
    }
    
    private func recentTakenDates(in days: Int) -> [Date] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return item.takenHistory
            .filter { $0 >= cutoff }
            .sorted(by: >)
            .prefix(20)
            .map { $0 }
    }
    
    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Calendar Heatmap View

struct CalendarHeatmapView: View {
    let item: SupplementLogM
    let days: Int
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack(spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            
            // Week rows
            let weeks = buildWeeks()
            ForEach(weeks.indices, id: \.self) { weekIndex in
                HStack(spacing: 4) {
                    let week = weeks[weekIndex]
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if dayIndex < week.count {
                            let date = week[dayIndex]
                            let isTaken = item.takenHistory.contains { Calendar.current.isDate($0, inSameDayAs: date) }
                            let isFuture = date > Calendar.current.startOfDay(for: Date())
                            let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
                            
                            Circle()
                                .fill(heatColor(for: date, isTaken: isTaken))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(isToday ? Color.cyan : Color.clear, lineWidth: 2)
                                )
                                .opacity(isFuture ? 0.2 : 1)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Legend
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(Color.red.opacity(0.4))
                        .font(.caption2)
                    Text("Missed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(Color.green.opacity(0.7))
                        .font(.caption2)
                    Text("Taken")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
    
    private func buildWeeks() -> [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        
        // Find the start of the week (Sunday) for the start date
        let weekdayComponent = calendar.component(.weekday, from: startDate)
        let daysToSubtract = weekdayComponent - 1
        let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: startDate) ?? startDate
        
        var weeks: [[Date]] = []
        var currentDate = weekStart
        var currentWeek: [Date] = []
        
        while currentDate <= today {
            currentWeek.append(currentDate)
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }
        
        return weeks
    }
    
    private func heatColor(for date: Date, isTaken: Bool) -> Color {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: Date()) && !isTaken {
            return Color.orange.opacity(0.5) // Today, not yet taken
        }
        return isTaken ? Color.green.opacity(0.7) : Color.red.opacity(0.3)
    }
}

// MARK: - Preview

#Preview {
    let item = SupplementLogM(
        name: "Creatine Monohydrate",
        dosage: "5g",
        timing: "Post-workout",
        takenHistory: (0..<25).map { i in
            Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
        }
    )
    SupplementHistoryModal(item: item)
}