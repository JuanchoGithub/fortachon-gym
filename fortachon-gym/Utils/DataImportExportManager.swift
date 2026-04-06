import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import FortachonCore

/// Manages data import and export for the app
final class DataImportExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var showImportConfirm = false
    @Published var importSummary: ImportSummary?
    @Published var statusMessage: StatusMessage?
    
    struct ImportSummary: Identifiable {
        let id = UUID()
        let workouts: Int
        let routines: Int
        let exercises: Int
        let weightEntries: Int
        let hasSettings: Bool
        let hasProfile: Bool
    }
    
    struct StatusMessage: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let isError: Bool
    }
    
    private let modelContext: ModelContext
    private let prefs: UserPreferencesM?
    private let sessions: [WorkoutSessionM]
    private let routines: [RoutineM]
    private let exercises: [ExerciseM]
    private let weightEntries: [WeightEntryM]
    
    init(modelContext: ModelContext, prefs: UserPreferencesM?, sessions: [WorkoutSessionM], routines: [RoutineM], exercises: [ExerciseM], weightEntries: [WeightEntryM]) {
        self.modelContext = modelContext
        self.prefs = prefs
        self.sessions = sessions
        self.routines = routines
        self.exercises = exercises
        self.weightEntries = weightEntries
    }
    
    // MARK: - Export
    
    func exportData() -> URL? {
        do {
            let exportData = ExportData(
                history: sessions.map { sessionToDict($0) },
                routines: routines.map { routineToDict($0) },
                exercises: exercises.map { exerciseToDict($0) },
                profile: prefs.map { prefsToDict($0) },
                settings: prefs.map { settingsToDict($0) },
                weightHistory: weightEntries.map { weightEntryToDict($0) }
            )
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(exportData)
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "fortachon_backup_\(Date().formatted(date: .abbreviated, time: .shortened).replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            statusMessage = StatusMessage(
                title: "Export Error",
                message: "Failed to export data: \(error.localizedDescription)",
                isError: true
            )
            return nil
        }
    }
    
    // MARK: - Import
    
    func parseImportData(from url: URL) -> ExportData? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importData = try decoder.decode(ExportData.self, from: data)
            return importData
        } catch {
            statusMessage = StatusMessage(
                title: "Import Error",
                message: "Failed to parse import file: \(error.localizedDescription)",
                isError: true
            )
            return nil
        }
    }
    
    func previewImport(_ data: ExportData) -> ImportSummary? {
        return ImportSummary(
            workouts: data.historyDict?.count ?? 0,
            routines: data.routinesDict?.count ?? 0,
            exercises: data.exercisesDict?.count ?? 0,
            weightEntries: data.weightHistoryDict?.count ?? 0,
            hasSettings: data.settingsDict != nil,
            hasProfile: data.profileDict != nil
        )
    }
    
    @MainActor
    func executeImport(_ data: ExportData) {
        isImporting = true
        
        do {
            // Import exercises
            if let exerciseData = data.exercisesDict {
                for exDict in exerciseData {
                    if let id = exDict["id"] as? String,
                       let name = exDict["name"] as? String,
                       let bodyPart = exDict["bodyPart"] as? String,
                       let category = exDict["category"] as? String {
                        
                        // Check if exercise already exists
                        let existing = exercises.first { $0.id == id }
                        if existing == nil {
                            let newExercise = ExerciseM(
                                id: id,
                                name: name,
                                bodyPart: bodyPart,
                                category: category,
                                notes: exDict["notes"] as? String,
                                isTimed: exDict["isTimed"] as? Bool ?? false,
                                isUnilateral: exDict["isUnilateral"] as? Bool ?? false,
                                primaryMuscles: exDict["primaryMuscles"] as? [String] ?? [],
                                secondaryMuscles: exDict["secondaryMuscles"] as? [String] ?? []
                            )
                            modelContext.insert(newExercise)
                        }
                    }
                }
            }
            
            // Import weight history
            if let weightData = data.weightHistoryDict {
                for wDict in weightData {
                    if let weight = wDict["weight"] as? Double,
                       let dateMs = wDict["date"] as? Double {
                        let date = Date(timeIntervalSince1970: dateMs / 1000)
                        let entry = WeightEntryM(weight: weight, date: date)
                        modelContext.insert(entry)
                    }
                }
            }
            
            // Import settings and profile
            if let prefsDict = data.profileDict {
                if let gender = prefsDict["gender"] as? String {
                    prefs?.gender = gender
                }
                if let height = prefsDict["heightCm"] as? Double {
                    prefs?.heightCm = height
                }
            }
            
            if let settingsDict = data.settingsDict {
                if let unit = settingsDict["measureUnit"] as? String {
                    prefs?.weightUnitStr = unit
                }
                if let fontSize = settingsDict["fontSize"] as? String {
                    prefs?.fontSize = fontSize
                }
                if let localized = settingsDict["useLocalizedExerciseNames"] as? Bool {
                    prefs?.localizedExerciseNames = localized
                }
                if let notifications = settingsDict["enableNotifications"] as? Bool {
                    prefs?.notificationsEnabled = notifications
                }
                if let voiceURI = settingsDict["selectedVoiceURI"] as? String {
                    prefs?.selectedVoiceURI = voiceURI
                }
                if let screenAwake = settingsDict["keepScreenAwake"] as? Bool {
                    // Apply screen wake setting
                    ScreenWakeManager.shared.toggle(screenAwake)
                }
                
                // Rest timer settings
                if let restTimes = settingsDict["defaultRestTimes"] as? [String: Int] {
                    if let normal = restTimes["normal"] { prefs?.restNormal = normal }
                    if let warmup = restTimes["warmup"] { prefs?.restWarmup = warmup }
                    if let drop = restTimes["drop"] { prefs?.restDrop = drop }
                    if let timed = restTimes["timed"] { prefs?.restTimed = timed }
                    if let effort = restTimes["effort"] { prefs?.restEffort = effort }
                    if let failure = restTimes["failure"] { prefs?.restFailure = failure }
                }
            }
            
            try modelContext.save()
            
            statusMessage = StatusMessage(
                title: "Import Successful",
                message: "Successfully imported your data.",
                isError: false
            )
        } catch {
            statusMessage = StatusMessage(
                title: "Import Error",
                message: "Failed to import data: \(error.localizedDescription)",
                isError: true
            )
        }
        
        isImporting = false
    }
    
    // MARK: - Dictionary Conversion Helpers
    
    private func sessionToDict(_ session: WorkoutSessionM) -> [String: Any] {
        return [
            "id": session.wsId,
            "routineId": session.routineId,
            "routineName": session.routineName,
            "startTime": session.startTime.timeIntervalSince1970 * 1000,
            "endTime": session.endTime.timeIntervalSince1970 * 1000,
            "prCount": session.prCount
        ]
    }
    
    private func routineToDict(_ routine: RoutineM) -> [String: Any] {
        return [
            "id": routine.rtId,
            "name": routine.name,
            "desc": routine.desc,
            "isTemplate": routine.isTemplate,
            "type": routine.routineTypeStr
        ]
    }
    
    private func exerciseToDict(_ exercise: ExerciseM) -> [String: Any] {
        return [
            "id": exercise.id,
            "name": exercise.name,
            "bodyPart": exercise.bodyPartStr,
            "category": exercise.categoryStr,
            "notes": exercise.notes ?? "",
            "isTimed": exercise.isTimed,
            "isUnilateral": exercise.isUnilateral,
            "primaryMuscles": exercise.primaryMuscles,
            "secondaryMuscles": exercise.secondaryMuscles
        ]
    }
    
    private func prefsToDict(_ prefs: UserPreferencesM) -> [String: Any] {
        let dict: [String: Any] = [
            "gender": prefs.gender ?? "",
            "heightCm": prefs.heightCm ?? 0,
            "bioAdaptiveEngine": prefs.bioAdaptiveEngine
        ]
        return dict
    }
    
    private func settingsToDict(_ prefs: UserPreferencesM) -> [String: Any] {
        return [
            "measureUnit": prefs.weightUnitStr,
            "fontSize": prefs.fontSize,
            "smartGoalDetection": prefs.smartGoalDetection,
            "useLocalizedExerciseNames": prefs.localizedExerciseNames,
            "enableNotifications": prefs.notificationsEnabled,
            "selectedVoiceURI": prefs.selectedVoiceURI ?? NSNull(),
            "keepScreenAwake": false, // Not stored in prefs, manage via ScreenWakeManager
            "defaultRestTimes": [
                "normal": prefs.restNormal,
                "warmup": prefs.restWarmup,
                "drop": prefs.restDrop,
                "timed": prefs.restTimed,
                "effort": prefs.restEffort,
                "failure": prefs.restFailure
            ]
        ]
    }
    
    private func weightEntryToDict(_ entry: WeightEntryM) -> [String: Any] {
        return [
            "weight": entry.weight,
            "date": entry.date.timeIntervalSince1970 * 1000
        ]
    }
}

// MARK: - Export Data Model
// Uses JSONValue wrapper for Codable support of dynamic dictionaries

struct JSONValue: Codable {
    var value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([JSONValue].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: JSONValue].self) {
            value = dict.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode JSONValue")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { JSONValue($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { JSONValue($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            try container.encode("\(value)")
        }
    }
}

struct ExportData: Codable {
    // Export version for backward compatibility
    var exportVersion: String?
    var exportDate: String?
    var history: [JSONValue]?
    var routines: [JSONValue]?
    var exercises: [JSONValue]?
    var profile: JSONValue?
    var settings: JSONValue?
    var weightHistory: [JSONValue]?
    var supersets: [JSONValue]?
    
    enum CodingKeys: String, CodingKey {
        case exportVersion, exportDate, history, routines, exercises, profile, settings, weightHistory, supersets
    }
    
    init(history: [[String: Any]]? = nil, routines: [[String: Any]]? = nil, exercises: [[String: Any]]? = nil, profile: [String: Any]? = nil, settings: [String: Any]? = nil, weightHistory: [[String: Any]]? = nil, supersets: [[String: Any]]? = nil) {
        self.exportVersion = "2.0"
        self.exportDate = ISO8601DateFormatter().string(from: Date())
        self.history = history?.map { JSONValue($0) }
        self.routines = routines?.map { JSONValue($0) }
        self.exercises = exercises?.map { JSONValue($0) }
        self.profile = profile.map { JSONValue($0) }
        self.settings = settings.map { JSONValue($0) }
        self.weightHistory = weightHistory?.map { JSONValue($0) }
        self.supersets = supersets?.map { JSONValue($0) }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        history = try container.decodeIfPresent([JSONValue].self, forKey: .history)
        routines = try container.decodeIfPresent([JSONValue].self, forKey: .routines)
        exercises = try container.decodeIfPresent([JSONValue].self, forKey: .exercises)
        profile = try container.decodeIfPresent(JSONValue.self, forKey: .profile)
        settings = try container.decodeIfPresent(JSONValue.self, forKey: .settings)
        weightHistory = try container.decodeIfPresent([JSONValue].self, forKey: .weightHistory)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(history, forKey: .history)
        try container.encodeIfPresent(routines, forKey: .routines)
        try container.encodeIfPresent(exercises, forKey: .exercises)
        try container.encodeIfPresent(profile, forKey: .profile)
        try container.encodeIfPresent(settings, forKey: .settings)
        try container.encodeIfPresent(weightHistory, forKey: .weightHistory)
    }
    
    // Convenience accessors
    var historyDict: [[String: Any]]? { history?.compactMap { $0.value as? [String: Any] } }
    var routinesDict: [[String: Any]]? { routines?.compactMap { $0.value as? [String: Any] } }
    var exercisesDict: [[String: Any]]? { exercises?.compactMap { $0.value as? [String: Any] } }
    var profileDict: [String: Any]? { profile?.value as? [String: Any] }
    var settingsDict: [String: Any]? { settings?.value as? [String: Any] }
    var weightHistoryDict: [[String: Any]]? { weightHistory?.compactMap { $0.value as? [String: Any] } }
}

// MARK: - JSON Decoding Extension

extension KeyedDecodingContainer {
    func decodeIfPresent(_ type: [[String: Any]].Type, forKey key: KeyedDecodingContainer.Key) throws -> [[String: Any]]? {
        guard let data = try decodeIfPresent(Data.self, forKey: key) else { return nil }
        return try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
    }
    
    func decodeIfPresent(_ type: [String: Any].Type, forKey key: KeyedDecodingContainer.Key) throws -> [String: Any]? {
        guard let data = try decodeIfPresent(Data.self, forKey: key) else { return nil }
        return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}

extension KeyedEncodingContainer {
    // Simple encoding of dictionary values
}