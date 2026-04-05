import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Supplement Log Calendar View
// Matches web version's SupplementLog.tsx

struct SupplementLogCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [SupplementLogM]
    
    @State private var displayDate = Date()
    @State private var selectedDate: Date?
    @State private var showSelectedDateDetail = false
    
    private let calendar = Calendar.current
    
    var activeSupplements: [SupplementLogM] {
        let today = calendar.startOfDay(for: Date())
        return supplements.filter {
            !$0.isSnoozed || ($0.snoozedUntil ?? today) < today
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Month Navigation
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                Text(monthYearString)
                    .font(.headline.bold())
                Spacer()
                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            
            // Day Headers
            HStack(spacing: 0) {
                ForEach(shortDayNames, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(calendarDays, id: \.key) { day in
                    if day.isPadding {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    } else if let date = day.date {
                        CalendarDayCell(
                            date: date,
                            isToday: day.isToday,
                            isFuture: date > calendar.startOfDay(for: Date()),
                            adherence: day.adherence,
                            onTap: canTap(day) ? { selectedDate = date; showSelectedDateDetail = true } : nil
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .sheet(isPresented: $showSelectedDateDetail) {
            if let date = selectedDate {
                SupplementDayDetailView(date: date)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var shortDayNames: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return (0..<7).map {
            let dayOfWeek = calendar.date(from: DateComponents(weekday: $0 + 1)) ?? Date()
            return formatter.string(from: dayOfWeek)
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayDate)
    }
    
    private var calendarDays: [CalendarDayData] {
        let year = calendar.component(.year, from: displayDate)
        let month = calendar.component(.month, from: displayDate)
        let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count
        
        var days: [CalendarDayData] = []
        
        // Padding
        for i in 0..<(firstWeekday - 1) {
            days.append(CalendarDayData(key: "prev-\(i)", isPadding: true))
        }
        
        let today = calendar.startOfDay(for: Date())
        
        // Days
        for day in 1...daysInMonth {
            let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
            let dateStr = dateISO(date)
            
            let takenCount = activeSupplements.filter { sup in
                sup.takenHistory.contains { calendar.isDate($0, inSameDayAs: date) }
            }.count
            
            let scheduledCount = activeSupplements.filter { sup in
                if sup.trainingDayOnly { return true } // Simplified
                if sup.restDayOnly { return true }
                return true
            }.count
            
            let adherence = scheduledCount > 0 ? Double(takenCount) / Double(scheduledCount) : -1
            
            days.append(CalendarDayData(
                key: dateStr,
                date: date,
                isToday: calendar.isDate(date, inSameDayAs: today),
                adherence: adherence
            ))
        }
        
        return days
    }
    
    private func canTap(_ day: CalendarDayData) -> Bool {
        guard let date = day.date else { return false }
        return date <= calendar.startOfDay(for: Date())
    }
    
    private func dateISO(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func changeMonth(_ amount: Int) {
        displayDate = calendar.date(byAdding: .month, value: amount, to: displayDate) ?? displayDate
    }
}

// MARK: - Calendar Day Data

struct CalendarDayData: Identifiable {
    let key: String
    var id: String { key }
    let date: Date?
    let isPadding: Bool
    let isToday: Bool
    let adherence: Double
    let dayOfWeek: String?
    
    init(key: String, date: Date? = nil, isPadding: Bool = false, isToday: Bool = false, adherence: Double = -1) {
        self.key = key
        self.date = date
        self.isPadding = isPadding
        self.isToday = isToday
        self.adherence = adherence
        self.dayOfWeek = nil
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isToday: Bool
    let isFuture: Bool
    let adherence: Double
    let onTap: (() -> Void)?
    
    var body: some View {
        Button(action: onTap ?? {}) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.caption.bold())
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isToday ? Color.cyan.opacity(0.2) : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .stroke(isToday ? Color.cyan : Color.clear, lineWidth: 2)
                    )
                
                if adherence != -1 && !isFuture {
                    Circle()
                        .fill(adherenceColor)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .opacity(isFuture ? 0.4 : 1)
        .buttonStyle(.plain)
    }
    
    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }
    
    private var adherenceColor: Color {
        if adherence >= 1.0 { return .green }
        if adherence > 0 { return .yellow }
        return .red
    }
}

// MARK: - Supplement Day Detail View

struct SupplementDayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    
    var body: some View {
        NavigationStack {
            List {
                Section("Date") {
                    Text(date, style: .date)
                        .font(.headline)
                }
                
                Section {
                    ContentUnavailableView(
                        "Supplement history for this date",
                        systemImage: "pill",
                        description: Text("Tap items from Today's Schedule to mark them as taken")
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
// Preview disabled due to @Query requirement
