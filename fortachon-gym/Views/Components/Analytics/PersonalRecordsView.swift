import SwiftUI
import Charts
import FortachonCore

// MARK: - Personal Records View

struct PersonalRecordsView: View {
    @State private var oneRMTracker = OneRMTracker()
    @State private var selectedCategory: PRCategory = .all
    
    enum PRCategory: String, CaseIterable {
        case all = "All"
        case strength = "Strength"
        case volume = "Volume"
        case consistency = "Consistency"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(PRCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                switch selectedCategory {
                case .all:
                    allRecordsSection
                case .strength:
                    strengthRecordsSection
                case .volume:
                    volumeRecordsSection
                case .consistency:
                    consistencyRecordsSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Personal Records")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - All Records Section
    
    private var allRecordsSection: some View {
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
                    PersonalRecordCard(record: record)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Strength Records Section
    
    private var strengthRecordsSection: some View {
        VStack(spacing: 16) {
            let latest1RMs = oneRMTracker.getLatest1RMs()
            let strengthRecords = latest1RMs.values.sorted { $0.estimated1RM > $1.estimated1RM }
            
            if strengthRecords.isEmpty {
                ContentUnavailableView(
                    "No Strength PRs",
                    systemImage: "dumbbell",
                    description: Text("Lift heavier weights to set strength records.")
                )
            } else {
                ForEach(Array(strengthRecords.prefix(10)), id: \.id) { record in
                    PersonalRecordCard(record: record)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Volume Records Section
    
    private var volumeRecordsSection: some View {
        VStack(spacing: 16) {
            let allRecords = oneRMTracker.getAllRecords()
            let volumeRecords = allRecords.sorted { ($0.weight * Double($0.reps)) > ($1.weight * Double($1.reps)) }
            
            if volumeRecords.isEmpty {
                ContentUnavailableView(
                    "No Volume PRs",
                    systemImage: "chart.bar",
                    description: Text("Complete high-volume workouts to set volume records.")
                )
            } else {
                ForEach(Array(volumeRecords.prefix(10)), id: \.id) { record in
                    VolumePRCard(record: record)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Consistency Records Section
    
    private var consistencyRecordsSection: some View {
        VStack(spacing: 16) {
            ConsistencyPRCard(title: "Longest Streak", value: "30 days", icon: "flame", color: .orange)
                .padding(.horizontal)
            ConsistencyPRCard(title: "Most Workouts in a Week", value: "6", icon: "calendar", color: .blue)
                .padding(.horizontal)
            ConsistencyPRCard(title: "Most Workouts in a Month", value: "22", icon: "calendar.badge.clock", color: .green)
                .padding(.horizontal)
            ConsistencyPRCard(title: "Longest Rest Day Streak", value: "3 days", icon: "bed.double", color: .purple)
                .padding(.horizontal)
        }
    }
}

// MARK: - PR Card

struct PersonalRecordCard: View {
    let record: OneRMRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.exerciseName)
                    .font(.headline)
                Text("\(Int(record.weight)) kg × \(record.reps) reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(record.estimated1RM)) kg")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                Text("est. 1RM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Volume PR Card

struct VolumePRCard: View {
    let record: OneRMRecord
    
    var volume: Double {
        record.weight * Double(record.reps)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.exerciseName)
                    .font(.headline)
                Text("\(Int(record.weight)) kg × \(record.reps) reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(volume)) kg")
                    .font(.title2.bold())
                    .foregroundStyle(.purple)
                Text("volume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Consistency PR Card

struct ConsistencyPRCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PersonalRecordsView()
    }
}