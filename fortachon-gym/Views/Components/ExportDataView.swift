import SwiftUI
import UniformTypeIdentifiers

// MARK: - Export Data View

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    let sessions: [WorkoutSessionM]
    @Binding var isPresented: Bool
    
    @State private var exportFormat: ExportFormat = .json
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case json = "JSON"
        case csv = "CSV"
        
        var id: String { rawValue }
        
        var mimeType: String {
            switch self {
            case .json: return "application/json"
            case .csv: return "text/csv"
            }
        }
        
        var utType: UTType {
            switch self {
            case .json: return .json
            case .csv: return .commaSeparatedText
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    Text("Export Workout Data")
                        .font(.title2.bold())
                    Text("\(sessions.count) workouts will be exported")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Format selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Format")
                        .font(.headline)
                    
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Export button
                Button {
                    exportData()
                } label: {
                    Label("Export \(exportFormat.rawValue)", systemImage: "arrow.right.doc.on.clipboard")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Share sheet
                if let url = exportedURL {
                    VStack(spacing: 12) {
                        Label("Export Complete!", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                        
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func exportData() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        
        switch exportFormat {
        case .json:
            let url = tempDir.appendingPathComponent("fortachon_workouts.json")
            exportJSON(to: url)
            
        case .csv:
            let url = tempDir.appendingPathComponent("fortachon_workouts.csv")
            exportCSV(to: url)
        }
    }
    
    private func exportJSON(to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            // Create export dictionary
            let exportData: [String: Any] = [
                "version": "1.0",
                "exportDate": ISO8601DateFormatter().string(from: Date()),
                "workouts": sessions.map { session in
                    [
                        "id": session.wsId,
                        "routineName": session.routineName,
                        "startTime": ISO8601DateFormatter().string(from: session.startTime),
                        "endTime": ISO8601DateFormatter().string(from: session.endTime),
                        "prCount": session.prCount,
                        "notes": session.notes,
                        "exercises": session.exercises.map { ex in
                            [
                                "exerciseId": ex.exerciseId,
                                "sets": ex.sets.map { set in
                                    [
                                        "reps": set.reps,
                                        "weight": set.weight,
                                        "type": set.setTypeStr,
                                        "isComplete": set.isComplete,
                                        "rpe": set.rpe as Any
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
            
            let data = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try data.write(to: url)
            exportedURL = url
        } catch {
            print("Export error: \(error)")
        }
    }
    
    private func exportCSV(to url: URL) {
        var csvText = "Date,Routine,Exercise,Set,Weight,Reps,Type,RPE,Completed\n"
        
        for session in sessions {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateStr = dateFormatter.string(from: session.startTime)
            
            for ex in session.exercises {
                for (index, set) in ex.sets.enumerated() {
                    let row = [
                        dateStr,
                        session.routineName,
                        ex.exerciseId,
                        "\(index + 1)",
                        "\(set.weight)",
                        "\(set.reps)",
                        set.setTypeStr,
                        set.rpe.map { "\($0)" } ?? "",
                        set.isComplete ? "Yes" : "No"
                    ].joined(separator: ",")
                    csvText += row + "\n"
                }
            }
        }
        
        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)
            exportedURL = url
        } catch {
            print("CSV export error: \(error)")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var isPresented = true
        @State var sessions: [WorkoutSessionM] = []
        
        var body: some View {
            ExportDataView(sessions: sessions, isPresented: $isPresented)
        }
    }
    return PreviewWrapper()
}