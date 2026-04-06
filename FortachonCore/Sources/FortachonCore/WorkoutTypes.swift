// MARK: - UserGoal

public enum UserGoal: String, Codable, CaseIterable, Sendable {
    case strength = "strength"
    case muscle = "muscle"
    case endurance = "endurance"
    
    public var title: String {
        switch self {
        case .strength: return "Strength"
        case .muscle: return "Muscle Growth"
        case .endurance: return "Endurance"
        }
    }
    
    public var icon: String {
        switch self {
        case .strength: return "bolt.fill"
        case .muscle: return "brain.head.profile"
        case .endurance: return "figure.run"
        }
    }
    
    public var description: String {
        switch self {
        case .strength: return "Focus on lifting heavier and setting PRs"
        case .muscle: return "Build hypertrophy with progressive overload"
        case .endurance: return "Improve stamina and muscular endurance"
        }
    }
}
