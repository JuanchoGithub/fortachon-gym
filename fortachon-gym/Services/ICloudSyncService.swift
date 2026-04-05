import Foundation
import Observation
import SwiftUI

// MARK: - iCloud Sync Status

public enum ICloudSyncStatus: String, CaseIterable, Codable, Sendable {
    case notSynced, syncing, synced, error, unavailable
    
    public var displayName: String {
        switch self {
        case .notSynced: return "Not Synced"
        case .syncing: return "Syncing…"
        case .synced: return "Synced"
        case .error: return "Sync Error"
        case .unavailable: return "iCloud Unavailable"
        }
    }
    
    public var iconSymbol: String {
        switch self {
        case .notSynced: return "clock.arrow.circlepath"
        case .syncing: return "arrow.clockwise"
        case .synced: return "checkmark.icloud"
        case .error: return "exclamationmark.icloud"
        case .unavailable: return "icloud.slash"
        }
    }
    
    public var iconColor: Color {
        switch self {
        case .notSynced: return .secondary
        case .syncing: return .blue
        case .synced: return .green
        case .error: return .red
        case .unavailable: return .gray
        }
    }
}

// MARK: - iCloud Sync Service

@Observable
@MainActor
final class ICloudSyncService {
    
    // MARK: - State
    
    var syncStatus: ICloudSyncStatus = .notSynced
    var lastSyncDate: Date?
    var errorMessage: String?
    var autoSyncEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(autoSyncEnabled, forKey: "fortachon_auto_sync_enabled")
        }
    }
    
    // MARK: - Constants
    
    private static let lastSyncKey = "fortachon_icloud_last_sync"
    private static let autoSyncKey = "fortachon_auto_sync_enabled"
    private static let syncErrorKey = "fortachon_icloud_error"
    
    // MARK: - Init
    
    init() {
        // Load saved preferences
        if let timestamp = UserDefaults.standard.double(forKey: Self.lastSyncKey) as Double?, timestamp > 0 {
            lastSyncDate = Date(timeIntervalSince1970: timestamp)
        }
        autoSyncEnabled = UserDefaults.standard.object(forKey: Self.autoSyncKey) as? Bool ?? true
        
        // Check initial availability
        if !Self.isICloudAvailable {
            syncStatus = .unavailable
        } else if lastSyncDate != nil {
            syncStatus = .synced
        }
        
        // Listen for iCloud key changes
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.handleExternalChange()
            }
        }
    }
    
    // MARK: - Public API
    
    /// Check if iCloud is available on this device.
    static var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
    
    /// Get the iCloud container URL.
    static var containerURL: URL? {
        FileManager.default.url(
            forUbiquityContainerIdentifier: nil
        )?.appendingPathComponent("Documents")
    }
    
    /// Trigger a manual sync.
    func triggerSync() async {
        guard Self.isICloudAvailable else {
            syncStatus = .unavailable
            errorMessage = "iCloud is not available on this device."
            return
        }
        
        guard autoSyncEnabled else {
            syncStatus = .notSynced
            return
        }
        
        syncStatus = .syncing
        errorMessage = nil
        
        do {
            // Sync settings via NSUbiquitousKeyValueStore
            try await syncSettings()
            
            // Sync data files via iCloud Drive
            try await syncDataFiles()
            
            // Update sync status
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate?.timeIntervalSince1970 ?? 0, forKey: Self.lastSyncKey)
            syncStatus = .synced
            
        } catch {
            syncStatus = .error
            errorMessage = error.localizedDescription
        }
    }
    
    /// Save data to iCloud Drive.
    func saveToICloudDrive(data: Data, fileName: String) async throws {
        guard let containerURL = Self.containerURL else {
            throw ICloudSyncError.containerNotFound
        }
        
        let fileURL = containerURL.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
    }
    
    /// Load data from iCloud Drive.
    func loadFromICloudDrive(fileName: String) async throws -> Data {
        guard let containerURL = Self.containerURL else {
            throw ICloudSyncError.containerNotFound
        }
        
        let fileURL = containerURL.appendingPathComponent(fileName)
        return try Data(contentsOf: fileURL)
    }
    
    /// List files in iCloud Drive.
    func listICloudDriveFiles() async throws -> [String] {
        guard let containerURL = Self.containerURL else {
            throw ICloudSyncError.containerNotFound
        }
        
        return try FileManager.default.contentsOfDirectory(atPath: containerURL.path)
    }
    
    /// Delete file from iCloud Drive.
    func deleteFromICloudDrive(fileName: String) async throws {
        guard let containerURL = Self.containerURL else {
            throw ICloudSyncError.containerNotFound
        }
        
        let fileURL = containerURL.appendingPathComponent(fileName)
        try FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Private
    
    private func syncSettings() async throws {
        let store = NSUbiquitousKeyValueStore.default
        
        // Save settings to iCloud
        store.synchronize()
    }
    
    private func syncDataFiles() async throws {
        // Ensure container exists
        guard let containerURL = Self.containerURL else {
            throw ICloudSyncError.containerNotFound
        }
        
        // Create Documents directory if needed
        if !FileManager.default.fileExists(atPath: containerURL.path) {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        }
    }
    
    private func handleExternalChange() async {
        // iCloud keys changed externally, refresh
        if let timestamp = UserDefaults.standard.double(forKey: Self.lastSyncKey) as Double?, timestamp > 0 {
            lastSyncDate = Date(timeIntervalSince1970: timestamp)
            syncStatus = .synced
        }
    }
}

// MARK: - Errors

enum ICloudSyncError: LocalizedError {
    case containerNotFound
    case fileNotFound(String)
    case writeFailed(String)
    case readFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .containerNotFound: return "iCloud container not found. Check your entitlements."
        case .fileNotFound(let name): return "File not found: \(name)"
        case .writeFailed(let name): return "Failed to write: \(name)"
        case .readFailed(let name): return "Failed to read: \(name)"
        }
    }
}