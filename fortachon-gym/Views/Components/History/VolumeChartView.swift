import SwiftUI
import Charts
import SwiftData
import FortachonCore

// MARK: - Volume Chart View

struct VolumeChartView: View {
    let sessions: [WorkoutSessionM]
    @State private var selectedTimeRange: TimeRange = .month
    
    enum TimeRange: String, CaseIterable {
        case week = "1W", month = "1M", threeMonths = "3M", sixMonths = "6M", all = "All"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .all: return Int.max
            }
        }
    }
    
    // Calculate volume data
    private var volumeData: [(date: Date, volume: Double)] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date.distantPast
        
        return sessions
            .filter { $0.startTime >= cutoffDate }
            .sorted { $0.startTime < $1.startTime }
            .map { session in
                var totalVolume: Double = 0
                for ex in session.exercises {
                    for set in ex.sets where set.isComplete {
                        totalVolume += set.weight * Double(set.reps)
                    }
                }
                return (date: session.startTime, volume: totalVolume)
            }
    }
    
    private var averageVolume: Double {
        guard !volumeData.isEmpty else { return 0 }
        return volumeData.reduce(0) { $0 + $1.volume } / Double(volumeData.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Volume Over Time")
                    .font(.headline)
                Spacer()
                
                // Time range picker
                Picker("Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }
            
            if volumeData.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Complete some workouts to see your volume progress.")
                )
                .frame(height: 200)
            } else {
                // Chart
                Chart {
                    // Average line
                    RuleMark(y: .value("Average", averageVolume))
                        .foregroundStyle(.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Avg: \(Int(averageVolume)) kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    
                    // Volume line
                    ForEach(volumeData, id: \.date) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Volume", data.volume)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    
                    // Data points
                    ForEach(volumeData, id: \.date) { data in
                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("Volume", data.volume)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: Date.FormatStyle().month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                            }
                        }
                    }
                }
                
                // Summary
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workouts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(volumeData.count)")
                            .font(.title3.bold())
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Volume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(volumeData.reduce(0) { $0 + $1.volume })) kg")
                            .font(.title3.bold())
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avg/Session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(averageVolume)) kg")
                            .font(.title3.bold())
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    VolumeChartView(sessions: [])
        .padding()
}