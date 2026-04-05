import SwiftUI
import Charts
import SwiftData
import FortachonCore

// MARK: - Exercise History View

struct ExerciseHistoryView: View {
    let exerciseId: String
    let exerciseName: String
    let sessions: [WorkoutSessionM]
    @State private var selectedMetric: HistoryMetric = .volume
    @State private var oneRMTracker = OneRMTracker()
    
    enum HistoryMetric: String, CaseIterable {
        case volume = "Volume"
        case oneRM = "1RM Estimate"
        case maxWeight = "Max Weight"
        case totalReps = "Total Reps"
    }
    
    // Calculate history data
    private var historyData: [(date: Date, value: Double)] {
        let exerciseSessions = sessions.filter { session in
            session.exercises.contains { $0.exerciseId == exerciseId }
        }
        
        return exerciseSessions
            .sorted { $0.startTime < $1.startTime }
            .compactMap { session in
                let exercise = session.exercises.first { $0.exerciseId == exerciseId }
                guard let exercise = exercise else { return nil }
                
                let completedSets = exercise.sets.filter { $0.isComplete }
                guard !completedSets.isEmpty else { return nil }
                
                switch selectedMetric {
                case .volume:
                    let volume = completedSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                    return (date: session.startTime, value: volume)
                case .oneRM:
                    let max1RM = completedSets.compactMap { set -> Double? in
                        guard set.reps > 0 && set.weight > 0 else { return nil }
                        return set.weight * (1.0 + Double(set.reps) / 30.0)
                    }.max() ?? 0
                    return (date: session.startTime, value: max1RM)
                case .maxWeight:
                    let maxWeight = completedSets.map { $0.weight }.max() ?? 0
                    return (date: session.startTime, value: maxWeight)
                case .totalReps:
                    let totalReps = Double(completedSets.reduce(0) { $0 + $1.reps })
                    return (date: session.startTime, value: totalReps)
                }
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseName)
                        .font(.title3.bold())
                    Text("\(historyData.count) sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                // Metric picker
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(HistoryMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.menu)
            }
            
            if historyData.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Complete some sets for this exercise to see your progress.")
                )
                .frame(height: 200)
            } else {
                // Chart
                Chart {
                    ForEach(historyData, id: \.date) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value(selectedMetric.rawValue, data.value)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    
                    ForEach(historyData, id: \.date) { data in
                        PointMark(
                            x: .value("Date", data.date),
                            y: .value(selectedMetric.rawValue, data.value)
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
                
                // Stats
                if let max = historyData.map({ $0.value }).max(),
                   let min = historyData.map({ $0.value }).min() {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatValue(historyData.last?.value ?? 0))
                                .font(.title3.bold())
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Best")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatValue(max))
                                .font(.title3.bold())
                                .foregroundStyle(.green)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("First")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatValue(min))
                                .font(.title3.bold())
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatValue(_ value: Double) -> String {
        switch selectedMetric {
        case .volume, .totalReps:
            return "\(Int(value))"
        case .oneRM, .maxWeight:
            return "\(Int(value)) kg"
        }
    }
}

// MARK: - Preview

#Preview {
    ExerciseHistoryView(
        exerciseId: "ex-1",
        exerciseName: "Bench Press",
        sessions: []
    )
    .padding()
}