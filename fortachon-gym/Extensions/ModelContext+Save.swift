import SwiftData

extension ModelContext {
    /// Save context if there are pending changes, ignoring errors
    func saveContextIfNeeded() {
        try? save()
    }
}