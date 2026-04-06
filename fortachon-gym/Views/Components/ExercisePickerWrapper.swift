import SwiftUI
import SwiftData
import FortachonCore

/// Wrapper for ExPicker that provides the Query context
struct ExPickerWrapper: View {
    @Query var exercises: [ExerciseM]
    @Environment(\.dismiss) var dismiss
    let onSelect: (String) -> Void
    
    init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ExerciseSearchView(
                    exercises: exercises,
                    onSelect: { id in
                        onSelect(id)
                        dismiss()
                    }
                )
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// Searchable exercise list (no @Query needed)
struct ExerciseSearchView: View {
    let exercises: [ExerciseM]
    let onSelect: (String) -> Void
    @State private var search = ""
    
    var filtered: [ExerciseM] {
        search.isEmpty ? exercises.sorted { $0.name < $1.name } : exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search...", text: $search)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
            
            List(filtered) { ex in
                Button {
                    onSelect(ex.id)
                } label: {
                    VStack(alignment: .leading) {
                        Text(ex.name).font(.headline)
                        Text(ex.bodyPartStr).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}