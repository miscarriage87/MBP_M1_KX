import SwiftUI

// MARK: - Design System

/// Centralized color palette for the DocumentOrganizer app
struct AppColors {
    // Primary colors
    static let primary = Color.accentColor
    static let primaryLight = Color.accentColor.opacity(0.1)
    static let primaryDark = Color.accentColor.opacity(0.8)
    
    // Text colors
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.primary.opacity(0.6)
    
    // Background colors
    static let background = Color(NSColor.controlBackgroundColor)
    static let backgroundSecondary = Color(NSColor.textBackgroundColor)
    static let backgroundTertiary = Color(NSColor.unemphasizedSelectedContentBackgroundColor)
    
    // Surface colors
    static let surface = Color(NSColor.controlBackgroundColor)
    static let surfaceSecondary = Color(NSColor.windowBackgroundColor)
    
    // Border and separator colors
    static let separator = Color(NSColor.separatorColor)
    static let border = Color(NSColor.tertiaryLabelColor)
    
    // Status colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // SAP-specific colors
    static let sapBlue = Color(red: 0.0, green: 0.36, blue: 0.56)
    static let sapGreen = Color(red: 0.16, green: 0.49, blue: 0.11)
    static let sapGold = Color(red: 0.89, green: 0.75, blue: 0.0)
}

/// Typography system with semantic font styles
struct AppFonts {
    // Display fonts
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.medium)
    
    // Body fonts
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let bodyEmphasized = Font.body.weight(.medium)
    static let callout = Font.callout
    
    // Small fonts
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2
    
    // Monospace fonts (for file paths, technical info)
    static let monospace = Font.system(.body, design: .monospaced)
    static let monospaceSmall = Font.system(.caption, design: .monospaced)
}

/// Spacing and padding system
struct Insets {
    // Basic spacing units
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
    static let jumbo: CGFloat = 48
    
    // Semantic spacing
    static let cardPadding: CGFloat = medium
    static let sectionSpacing: CGFloat = large
    static let buttonSpacing: CGFloat = small
    static let listRowSpacing: CGFloat = small
    static let contentMargin: CGFloat = medium
}

/// Border radius and corner styles
struct CornerRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let extraLarge: CGFloat = 16
    
    // Semantic corner radius
    static let card: CGFloat = medium
    static let button: CGFloat = small
    static let tag: CGFloat = extraSmall
    
    private static let extraSmall: CGFloat = 2
}

/// Shadow styles
struct AppShadows {
    static let subtle = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    static let card = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    static let elevated = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

/// Icon sizes
struct IconSizes {
    static let small: CGFloat = 16
    static let medium: CGFloat = 24
    static let large: CGFloat = 32
    static let extraLarge: CGFloat = 48
}

/// Animation durations
struct AnimationDurations {
    static let fast = 0.2
    static let medium = 0.3
    static let slow = 0.5
}

