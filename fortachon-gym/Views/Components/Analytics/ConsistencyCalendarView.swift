import SwiftUI
import FortachonCore

// MARK: - Consistency Calendar View

struct ConsistencyCalendarView: View {
    let sessions: [WorkoutSessionM]
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Get workout dates for current month
    private var workoutDates: Set<Date> {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        let startOfMonth = calendar.date(from: components)!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return Set(sessions.compactMap { session in
            let sessionDate = calendar.startOfDay(for: session.startTime)
            if sessionDate >= startOfMonth && sessionDate <= endOfMonth {
                return sessionDate
            }
            return nil
        })
    }
    
    // Get all days in current month
    private var daysInMonth: [Date] {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        let startOfMonth = calendar.date(from: components)!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    // Get first weekday of month (0=Sun, 1=Mon, etc.)
    private var firstWeekday: Int {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        let startOfMonth = calendar.date(from: components)!
        return calendar.component(.weekday, from: startOfMonth) - 1
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Text(currentMonth.formatted(date: .complete, time: .omitted))
                    .font(.headline)
                
                Button {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                // Empty cells for days before first of month
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
                
                // Days of month
                ForEach(daysInMonth, id: \.self) { date in
                    let isWorkoutDay = workoutDates.contains(calendar.startOfDay(for: date))
                    let isToday = calendar.isDateInToday(date)
                    
                    ZStack {
                        if isWorkoutDay {
                            Circle()
                                .fill(Color.green)
                        } else if isToday {
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                        }
                        
                        Text("\(calendar.component(.day, from: date))")
                            .font(.caption)
                            .foregroundStyle(isWorkoutDay ? .white : (isToday ? .blue : .primary))
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                    Text("Workout")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Circle()
                        .stroke(.blue, lineWidth: 2)
                        .frame(width: 12, height: 12)
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Monthly stats
            let workoutDaysThisMonth = workoutDates.count
            let daysInMonthCount = daysInMonth.count
            let consistency = daysInMonthCount > 0 ? Double(workoutDaysThisMonth) / Double(daysInMonthCount) * 100 : 0
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workout Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(workoutDaysThisMonth)")
                        .font(.title3.bold())
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Consistency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(consistency))%")
                        .font(.title3.bold())
                        .foregroundStyle(consistency >= 50 ? .green : .orange)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    ConsistencyCalendarView(sessions: [])
        .padding()
}