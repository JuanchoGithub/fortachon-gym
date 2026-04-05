import Foundation

// MARK: - Cloud Sync Service

public struct CloudSyncConfig: Codable, Sendable {
    public let apiBase: String
    
    public init(apiBase: String = "https://fortachon.vercel.app") {
        self.apiBase = apiBase
    }
}

public struct SyncData: Codable, Sendable {
    public var history: [WorkoutSession]?
    public var routines: [Routine]?
    public var exercises: [Exercise]?
    public var profile: UserPreferencesSync?
    public var settings: SettingsSync?
    public var weightEntries: [WeightEntrySync]?
    public var supplements: SupplementSync?
    
    public init(
        history: [WorkoutSession]? = nil,
        routines: [Routine]? = nil,
        exercises: [Exercise]? = nil,
        profile: UserPreferencesSync? = nil,
        settings: SettingsSync? = nil,
        weightEntries: [WeightEntrySync]? = nil,
        supplements: SupplementSync? = nil
    ) {
        self.history = history
        self.routines = routines
        self.exercises = exercises
        self.profile = profile
        self.settings = settings
        self.weightEntries = weightEntries
        self.supplements = supplements
    }
}

public struct UserPreferencesSync: Codable, Sendable {
    public var gender: String?
    public var heightCm: Double?
    
    public init(gender: String? = nil, heightCm: Double? = nil) {
        self.gender = gender
        self.heightCm = heightCm
    }
}

public struct SettingsSync: Codable, Sendable {
    public var measureUnit: String
    public var defaultRestTimes: RestTimesSync?
    public var useLocalizedExerciseNames: Bool
    public var keepScreenAwake: Bool
    public var enableNotifications: Bool
    public var selectedVoiceURI: String?
    public var fontSize: String
    
    public init(
        measureUnit: String = "metric",
        defaultRestTimes: RestTimesSync? = nil,
        useLocalizedExerciseNames: Bool = false,
        keepScreenAwake: Bool = false,
        enableNotifications: Bool = false,
        selectedVoiceURI: String? = nil,
        fontSize: String = "normal"
    ) {
        self.measureUnit = measureUnit
        self.defaultRestTimes = defaultRestTimes
        self.useLocalizedExerciseNames = useLocalizedExerciseNames
        self.keepScreenAwake = keepScreenAwake
        self.enableNotifications = enableNotifications
        self.selectedVoiceURI = selectedVoiceURI
        self.fontSize = fontSize
    }
}

public struct RestTimesSync: Codable, Sendable {
    public var normal: Int
    public var warmup: Int
    public var drop: Int
    public var timed: Int
    public var effort: Int
    public var failure: Int
    
    public init(
        normal: Int = 90,
        warmup: Int = 60,
        drop: Int = 30,
        timed: Int = 10,
        effort: Int = 90,
        failure: Int = 300
    ) {
        self.normal = normal
        self.warmup = warmup
        self.drop = drop
        self.timed = timed
        self.effort = effort
        self.failure = failure
    }
}

public struct WeightEntrySync: Codable, Sendable {
    public var weight: Double
    public var date: Double
    
    public init(weight: Double, date: Double) {
        self.weight = weight
        self.date = date
    }
}

public struct SupplementSync: Codable, Sendable {
    public var supplementPlan: SupplementPlanSync?
    public var userSupplements: [String]?
    public var takenSupplements: [String]?
    public var supplementLogs: [String]?
    public var snoozedSupplements: [String]?
    public var dayOverrides: [String]?
    
    public init(
        supplementPlan: SupplementPlanSync? = nil,
        userSupplements: [String]? = nil,
        takenSupplements: [String]? = nil,
        supplementLogs: [String]? = nil,
        snoozedSupplements: [String]? = nil,
        dayOverrides: [String]? = nil
    ) {
        self.supplementPlan = supplementPlan
        self.userSupplements = userSupplements
        self.takenSupplements = takenSupplements
        self.supplementLogs = supplementLogs
        self.snoozedSupplements = snoozedSupplements
        self.dayOverrides = dayOverrides
    }
}

public struct SupplementPlanSync: Codable, Sendable {
    public var plan: [String]?
    
    public init(plan: [String]? = nil) {
        self.plan = plan
    }
}

public struct SyncResponse {
    public let success: Bool
    public let data: SyncData?
    public let syncedAt: Double?
    public let lastUpdated: Double?
    public let isEmpty: Bool
    public let error: String?
    
    public init(success: Bool, data: SyncData? = nil, syncedAt: Double? = nil, lastUpdated: Double? = nil, isEmpty: Bool = false, error: String? = nil) {
        self.success = success
        self.data = data
        self.syncedAt = syncedAt
        self.lastUpdated = lastUpdated
        self.isEmpty = isEmpty
        self.error = error
    }
}

// MARK: - Raw Sync Data (for JSON serialization)

struct RawSyncPayload: Codable {
    var data: SyncData
}

public struct RawSyncResponse: Codable {
    public var success: Bool?
    public var data: SyncData?
    public var syncedAt: Double?
    public var lastUpdated: Double?
    public var isEmpty: Bool?
    public var error: String?
    
    public init(success: Bool? = nil, data: SyncData? = nil, syncedAt: Double? = nil, lastUpdated: Double? = nil, isEmpty: Bool? = nil, error: String? = nil) {
        self.success = success
        self.data = data
        self.syncedAt = syncedAt
        self.lastUpdated = lastUpdated
        self.isEmpty = isEmpty
        self.error = error
    }
}

// MARK: - Sync Service

public final class CloudSyncService: @unchecked Sendable {
    private let config: CloudSyncConfig
    private let deviceId: String
    
    public init(config: CloudSyncConfig = CloudSyncConfig()) {
        self.config = config
        self.deviceId = CloudSyncService.getOrCreateDeviceId()
    }
    
    public func pushData(_ data: SyncData) async -> SyncResponse {
        let payload = RawSyncPayload(data: data)
        
        guard let url = URL(string: "\(config.apiBase)/api/sync/push"),
              let body = try? JSONEncoder().encode(payload) else {
            return SyncResponse(success: false, error: "Invalid request data")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return SyncResponse(success: false, error: "Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                return SyncResponse(success: false, error: "Server error: \(httpResponse.statusCode)")
            }
            
            let rawResponse = try JSONDecoder().decode(RawSyncResponse.self, from: data)
            let syncTime = Date().timeIntervalSince1970
            CloudSyncService.setLastSyncTime(syncTime)
            
            return SyncResponse(
                success: true,
                data: rawResponse.data,
                syncedAt: syncTime,
                isEmpty: rawResponse.isEmpty ?? false
            )
        } catch {
            return SyncResponse(success: false, error: "Network error: \(error.localizedDescription)")
        }
    }
    
    public func pullData(since: Double = 0) async -> SyncResponse {
        var urlString = "\(config.apiBase)/api/sync/pull"
        if since > 0 {
            urlString += "?since=\(since)"
        }
        
        guard let url = URL(string: urlString) else {
            return SyncResponse(success: false, error: "Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return SyncResponse(success: false, error: "Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                return SyncResponse(success: false, error: "Server error: \(httpResponse.statusCode)")
            }
            
            let rawResponse = try JSONDecoder().decode(RawSyncResponse.self, from: data)
            
            return SyncResponse(
                success: true,
                data: rawResponse.data,
                lastUpdated: rawResponse.lastUpdated
            )
        } catch {
            return SyncResponse(success: false, error: "Network error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Device ID Management
    
    private static let DEVICE_ID_KEY = "fortachon_device_id"
    private static let LAST_SYNC_KEY = "fortachon_last_sync_time"
    
    private static func getOrCreateDeviceId() -> String {
        if let existing = UserDefaults.standard.string(forKey: DEVICE_ID_KEY) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: DEVICE_ID_KEY)
        return newId
    }
    
    public static func getLastSyncTime() -> Double? {
        let value = UserDefaults.standard.double(forKey: LAST_SYNC_KEY)
        return value > 0 ? value : nil
    }
    
    public static func setLastSyncTime(_ time: Double) {
        UserDefaults.standard.set(time, forKey: LAST_SYNC_KEY)
    }
    
    public static func clearLastSyncTime() {
        UserDefaults.standard.removeObject(forKey: LAST_SYNC_KEY)
    }
    
    public static func getDeviceId() -> String {
        getOrCreateDeviceId()
    }
}