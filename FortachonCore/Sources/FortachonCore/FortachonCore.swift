/// FortachonCore — Pure Swift business logic for the Fortachon fitness app.
///
/// This package contains all domain types, utility functions, and analytics
/// ported from the original React/TypeScript codebase. It has **no UIKit or
/// SwiftUI dependencies** so it can be tested entirely from the command line
/// with `swift test`.
public enum FortachonCore {
    public static func version() -> String {
        return "0.1.0"
    }
}