import SwiftUI

/// Shared design tokens for consistent UI across the Fortachon Gym app.
/// Use these constants instead of hardcoded values to maintain visual consistency.
enum DesignTokens {
    // MARK: - Corner Radii
    
    /// Large card corners (main workout cards, stat cards)
    static let cardCornerRadius: CGFloat = 16
    
    /// Medium corners (input fields, smaller cards)
    static let smallCornerRadius: CGFloat = 12
    
    /// Small corners (filter pills, badges)
    static let pillCornerRadius: CGFloat = 8
    
    // MARK: - Spacing
    
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacingXXL: CGFloat = 24
    
    // MARK: - Padding
    
    /// Standard screen edge padding
    static let screenPadding: CGFloat = 16
    
    /// Card internal padding
    static let cardPadding: CGFloat = 16
    
    // MARK: - Animation
    
    /// Fast transitions (state changes, small movements)
    static let animationFast = Animation.easeInOut(duration: 0.15)
    
    /// Medium transitions (card expansions, section reveals)
    static let animationMedium = Animation.easeInOut(duration: 0.3)
    
    /// Spring animations (bouncy interactions)
    static let animationSpring = Animation.spring(duration: 0.3)
    
    // MARK: - Accessibility
    
    /// Apple's recommended minimum tap target size
    static let minimumTapSize: CGFloat = 44
    
    // MARK: - Shapes
    
    static func cardBackground() -> some Shape {
        RoundedRectangle(cornerRadius: cardCornerRadius)
    }
    
    static func smallCardBackground() -> some Shape {
        RoundedRectangle(cornerRadius: smallCornerRadius)
    }
    
    static func pillBackground() -> some Shape {
        RoundedRectangle(cornerRadius: pillCornerRadius)
    }
}