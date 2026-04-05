import SwiftUI
import FortachonCore

// MARK: - History Filter Options

struct HistoryFilterOptions: Equatable {
    var dateRange: DateRange = .all
    var bodyPart: BodyPart?
    var exerciseCategory: ExerciseCategory?
    var minVolume: Double = 0
    var sortBy: SortOption = .dateDesc
    
    enum DateRange: String, CaseIterable, Equatable {
        case week = "Last 7 Days"
        case month = "Last 30 Days"
        case threeMonths = "Last 3 Months"
        case sixMonths = "Last 6 Months"
        case year = "Last Year"
        case all = "All Time"
    }
    
    enum SortOption: String, CaseIterable, Equatable {
        case dateDesc = "Newest First"
        case dateAsc = "Oldest First"
        case volumeDesc = "Highest Volume"
        case durationDesc = "Longest First"
    }
}

// MARK: - History Filter Sheet

struct HistoryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: HistoryFilterOptions
    let onApply: (HistoryFilterOptions) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // Date Range
                Section("Date Range") {
                    Picker("Period", selection: $filters.dateRange) {
                        ForEach(HistoryFilterOptions.DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }
                
                // Body Part Filter
                Section("Body Part") {
                    Picker("Filter", selection: $filters.bodyPart) {
                        Text("All").tag(nil as BodyPart?)
                        ForEach(BodyPart.allCases, id: \.self) { part in
                            Text(part.rawValue).tag(part as BodyPart?)
                        }
                    }
                }
                
                // Exercise Category Filter
                Section("Equipment") {
                    Picker("Filter", selection: $filters.exerciseCategory) {
                        Text("All").tag(nil as ExerciseCategory?)
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat as ExerciseCategory?)
                        }
                    }
                }
                
                // Sort Options
                Section("Sort By") {
                    Picker("Order", selection: $filters.sortBy) {
                        ForEach(HistoryFilterOptions.SortOption.allCases, id: \.self) { sort in
                            Text(sort.rawValue).tag(sort)
                        }
                    }
                }
                
                // Reset
                Section {
                    Button("Reset All Filters") {
                        filters = HistoryFilterOptions()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(filters)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var filters = HistoryFilterOptions()
        
        var body: some View {
            HistoryFilterSheet(
                filters: $filters,
                onApply: { _ in }
            )
        }
    }
    return PreviewWrapper()
}