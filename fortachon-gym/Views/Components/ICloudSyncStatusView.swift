import SwiftUI

// MARK: - iCloud Sync Status View

struct ICloudSyncStatusView: View {
    @State private var syncService: ICloudSyncService
    @State private var isSyncing = false
    
    init(syncService: ICloudSyncService) {
        _syncService = State(initialValue: syncService)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: syncService.syncStatus.iconSymbol)
                    .font(.title2)
                    .foregroundStyle(syncService.syncStatus.iconColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(syncService.syncStatus.displayName)
                        .font(.headline)
                    
                    if let lastSync = syncService.lastSyncDate {
                        Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never synced")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if syncService.syncStatus == .error {
                    Button {
                        Task { await syncService.triggerSync() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(.red)
                    }
                } else if syncService.syncStatus != .syncing {
                    Button {
                        Task { await syncService.triggerSync() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Auto-sync toggle
            Toggle("Auto-sync when app opens", isOn: $syncService.autoSyncEnabled)
                .font(.caption)
            
            // Error message
            if syncService.syncStatus == .error, let error = syncService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    ICloudSyncStatusView(syncService: ICloudSyncService())
}