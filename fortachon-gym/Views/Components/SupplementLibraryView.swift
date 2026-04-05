import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Supplement Library View
// Matches web version's SupplementPlanOverview library browsing feature

struct SupplementLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [SupplementLogM]
    
    let onAddToPlan: (String) -> Void
    
    @State private var searchTerm = ""
    
    var libraryItems: [SupplementLibraryItem] {
        let library = getSupplementLibrary()
        
        // Get names of already active supplements
        let activeNames = Set(supplements.map { $0.name.lowercased() })
        
        // Filter out items that are already active
        return library.filter { item in
            !activeNames.contains(item.key.lowercased())
        }
        .filter { item in
            if searchTerm.isEmpty { return true }
            return item.key.lowercased().contains(searchTerm.lowercased()) ||
                   item.category.lowercased().contains(searchTerm.lowercased()) ||
                   item.descriptionKey.lowercased().contains(searchTerm.lowercased())
        }
        .sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Search
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search supplements", text: $searchTerm)
                            .textInputAutocapitalization(.never)
                    }
                }
                
                // Library Items
                Section("Supplement Library") {
                    if libraryItems.isEmpty {
                        ContentUnavailableView(
                            searchTerm.isEmpty ? "No supplements available" : "No matches",
                            systemImage: searchTerm.isEmpty ? "pill" : "magnifyingglass",
                            description: Text(searchTerm.isEmpty ? "All library items are already in your plan" : "Try adjusting your search")
                        )
                    } else {
                        ForEach(libraryItems, id: \.key) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(displayName(for: item.key))
                                            .font(.subheadline.bold())
                                        
                                        Text(item.category)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(Color(.systemGray6), in: Capsule())
                                    }
                                    
                                    Text(item.descriptionKey)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    
                                    HStack(spacing: 8) {
                                        Label(item.defaultDose, systemImage: "scalemass")
                                        Label(item.defaultTime, systemImage: "clock")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.cyan)
                                }
                                
                                Spacer()
                                
                                Button {
                                    onAddToPlan(item.key)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.cyan)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func displayName(for key: String) -> String {
        let mapping: [String: String] = [
            "creatine": "Creatine Monohydrate",
            "whey": "Whey Protein",
            "caffeine": "Caffeine",
            "multivitamin": "Multivitamin",
            "omega": "Omega-3 Fish Oil",
            "vitd3": "Vitamin D3",
            "magnesium": "Magnesium Glycinate",
            "zma": "ZMA",
            "bcaa": "BCAAs",
            "beta": "Beta-Alanine",
            "citrulline": "Citrulline Malate",
            "glutamine": "L-Glutamine",
            "casein": "Casein Protein",
            "electrolytes": "Electrolytes",
            "ashwagandha": "Ashwagandha",
            "melatonin": "Melatonin",
            "l_carnitine": "L-Carnitine",
            "collagen": "Collagen",
            "iron": "Iron",
            "preworkout": "Pre-Workout Blend"
        ]
        return mapping[key] ?? key.capitalized
    }
}

// #Preview disabled - internal view
