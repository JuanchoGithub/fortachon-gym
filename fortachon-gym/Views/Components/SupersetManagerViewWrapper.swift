import SwiftUI
import SwiftData
import FortachonCore

/// Wrapper for SupersetManagerView that allows modifying session exercises/supersets
struct SupersetManagerViewWrapper: View {
    let session: WorkoutSessionM
    
    var body: some View {
        SupersetManagerView(session: session)
    }
}
