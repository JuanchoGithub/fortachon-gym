import SwiftUI
import FortachonCore

// MARK: - Exercise Filter Options

struct ExerciseFilterOptions: Equatable {
    var bodyPart: BodyPart?
    var category: ExerciseCategory?
    var searchQuery: String = ""
    var sortBy: ExerciseSortOption = .name
    
    enum ExerciseSortOption: String, CaseIterable, Equatable {
        case name = "Name"
        case bodyPart = "Body Part"
        case category = "Equipment"
    }
}

// MARK: - Exercise Filter View

struct ExerciseFilterView: View {
    @Binding var filters: ExerciseFilterOptions
    let exercises: [ExerciseM]
    let onFilterChange: (ExerciseFilterOptions) -> Void
    
    @State private var showFilters = false
    
    var filteredExercises: [ExerciseM] {
        var result = exercises
        
        // Filter by body part
        if let bodyPart = filters.bodyPart {
            result = result.filter { $0.bodyPartStr == bodyPart.rawValue }
        }
        
        // Filter by category
        if let category = filters.category {
            result = result.filter { $0.categoryStr == category.rawValue }
        }
        
        // Filter by search
        if !filters.searchQuery.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(filters.searchQuery) }
        }
        
        // Sort
        switch filters.sortBy {
        case .name:
            result.sort { $0.name < $1.name }
        case .bodyPart:
            result.sort { $0.bodyPartStr < $1.bodyPartStr }
        case .category:
            result.sort { $0.categoryStr < $1.categoryStr }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search exercises...", text: $filters.searchQuery)
                    .onChange(of: filters.searchQuery) { _, _ in onFilterChange(filters) }
                if !filters.searchQuery.isEmpty {
                    Button {
                        filters.searchQuery = ""
                        onFilterChange(filters)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Body part filter
                    Menu {
                        Button("All Body Parts") {
                            filters.bodyPart = nil
                            onFilterChange(filters)
                        }
                        ForEach(BodyPart.allCases, id: \.self) { part in
                            Button(part.rawValue) {
                                filters.bodyPart = part
                                onFilterChange(filters)
                            }
                        }
                    } label: {
                        Label(filters.bodyPart?.rawValue ?? "Body Part", systemImage: "chevron.down")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    
                    // Category filter
                    Menu {
                        Button("All Equipment") {
                            filters.category = nil
                            onFilterChange(filters)
                        }
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            Button(cat.rawValue) {
                                filters.category = cat
                                onFilterChange(filters)
                            }
                        }
                    } label: {
                        Label(filters.category?.rawValue ?? "Equipment", systemImage: "chevron.down")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    
                    // Sort menu
                    Menu {
                        ForEach(ExerciseFilterOptions.ExerciseSortOption.allCases, id: \.self) { sort in
                            Button(sort.rawValue) {
                                filters.sortBy = sort
                                onFilterChange(filters)
                            }
                        }
                    } label: {
                        Label("Sort: \(filters.sortBy.rawValue)", systemImage: "arrow.up.arrow.down")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    
                    // Reset button
                    if filters.bodyPart != nil || filters.category != nil || !filters.searchQuery.isEmpty {
                        Button {
                            filters = ExerciseFilterOptions()
                            onFilterChange(filters)
                        } label: {
                            Label("Reset", systemImage: "xmark")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(.red)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
            }
            
            // Results count
            HStack {
                Text("\(filteredExercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var filters = ExerciseFilterOptions()
        
        var body: some View {
            ExerciseFilterView(
                filters: $filters,
                exercises: [],
                onFilterChange: { _ in }
            )
            .padding()
        }
    }
    return PreviewWrapper()
}