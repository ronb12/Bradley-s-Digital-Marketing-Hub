import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case blue = "Blue"
    case pink = "Pink"
    case green = "Green"
    case purple = "Purple"
    case orange = "Orange"
    case teal = "Teal"
    case indigo = "Indigo"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .blue: return "paintbrush.fill"
        case .pink: return "heart.fill"
        case .green: return "leaf.fill"
        case .purple: return "sparkles"
        case .orange: return "flame.fill"
        case .teal: return "waveform.path"
        case .indigo: return "moon.stars.fill"
        }
    }
}

struct ThemeColors {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let surface: Color
    
    static func colors(for theme: AppTheme, colorScheme: ColorScheme) -> ThemeColors {
        switch (theme, colorScheme) {
        // Blue Theme
        case (.blue, .light):
            return ThemeColors(
                primary: Color(red: 0.22, green: 0.50, blue: 0.94), // #387EF0
                secondary: Color(red: 0.36, green: 0.55, blue: 0.94), // #5B8DEF
                accent: Color(red: 0.09, green: 0.32, blue: 0.73), // #1752BA
                background: Color(red: 0.96, green: 0.97, blue: 1.0), // #F5F7FF
                surface: Color(red: 1.0, green: 1.0, blue: 1.0) // White
            )
        case (.blue, .dark):
            return ThemeColors(
                primary: Color(red: 0.36, green: 0.55, blue: 0.94), // #5B8DEF
                secondary: Color(red: 0.49, green: 0.65, blue: 0.95), // #7DA5F2
                accent: Color(red: 0.22, green: 0.50, blue: 0.94), // #387EF0
                background: Color(red: 0.05, green: 0.07, blue: 0.12), // #0D121F
                surface: Color(red: 0.10, green: 0.13, blue: 0.20) // #1A2133
            )
            
        // Pink Theme
        case (.pink, .light):
            return ThemeColors(
                primary: Color(red: 0.94, green: 0.31, blue: 0.44), // #F04F70
                secondary: Color(red: 0.95, green: 0.42, blue: 0.58), // #F26B94
                accent: Color(red: 0.78, green: 0.18, blue: 0.33), // #C72E54
                background: Color(red: 1.0, green: 0.96, blue: 0.97), // #FFF5F7
                surface: Color(red: 1.0, green: 1.0, blue: 1.0) // White
            )
        case (.pink, .dark):
            return ThemeColors(
                primary: Color(red: 0.95, green: 0.42, blue: 0.58), // #F26B94
                secondary: Color(red: 0.97, green: 0.55, blue: 0.68), // #F78CAE
                accent: Color(red: 0.94, green: 0.31, blue: 0.44), // #F04F70
                background: Color(red: 0.12, green: 0.05, blue: 0.07), // #1F0D12
                surface: Color(red: 0.20, green: 0.10, blue: 0.13) // #331A1F
            )
            
        // Green Theme
        case (.green, .light):
            return ThemeColors(
                primary: Color(red: 0.16, green: 0.66, blue: 0.46), // #2AA876
                secondary: Color(red: 0.29, green: 0.75, blue: 0.54), // #4ABF8A
                accent: Color(red: 0.10, green: 0.51, blue: 0.35), // #1A8259
                background: Color(red: 0.96, green: 1.0, blue: 0.97), // #F5FFF7
                surface: Color(red: 1.0, green: 1.0, blue: 1.0) // White
            )
        case (.green, .dark):
            return ThemeColors(
                primary: Color(red: 0.29, green: 0.75, blue: 0.54), // #4ABF8A
                secondary: Color(red: 0.41, green: 0.82, blue: 0.63), // #69D1A1
                accent: Color(red: 0.16, green: 0.66, blue: 0.46), // #2AA876
                background: Color(red: 0.05, green: 0.12, blue: 0.07), // #0D1F12
                surface: Color(red: 0.10, green: 0.20, blue: 0.13) // #1A331F
            )
            
        // Purple Theme
        case (.purple, .light):
            return ThemeColors(
                primary: Color(red: 0.50, green: 0.32, blue: 1.0), // #7F52FF
                secondary: Color(red: 0.62, green: 0.47, blue: 1.0), // #9E78FF
                accent: Color(red: 0.38, green: 0.18, blue: 0.85), // #612ED9
                background: Color(red: 0.98, green: 0.97, blue: 1.0), // #FAF7FF
                surface: Color(red: 1.0, green: 1.0, blue: 1.0) // White
            )
        case (.purple, .dark):
            return ThemeColors(
                primary: Color(red: 0.62, green: 0.47, blue: 1.0), // #9E78FF
                secondary: Color(red: 0.74, green: 0.62, blue: 1.0), // #BD9EFF
                accent: Color(red: 0.50, green: 0.32, blue: 1.0), // #7F52FF
                background: Color(red: 0.07, green: 0.05, blue: 0.12), // #120D1F
                surface: Color(red: 0.13, green: 0.10, blue: 0.20) // #211A33
            )
            
        // Orange Theme
        case (.orange, .light):
            return ThemeColors(
                primary: Color(red: 1.0, green: 0.58, blue: 0.0), // #FF9500
                secondary: Color(red: 1.0, green: 0.71, blue: 0.26), // #FFB542
                accent: Color(red: 0.85, green: 0.45, blue: 0.0), // #D97300
                background: Color(red: 1.0, green: 0.98, blue: 0.96), // #FFF9F5
                surface: Color(red: 1.0, green: 1.0, blue: 1.0) // White
            )
        case (.orange, .dark):
            return ThemeColors(
                primary: Color(red: 1.0, green: 0.71, blue: 0.26), // #FFB542
                secondary: Color(red: 1.0, green: 0.80, blue: 0.50), // #FFCC80
                accent: Color(red: 1.0, green: 0.58, blue: 0.0), // #FF9500
                background: Color(red: 0.12, green: 0.08, blue: 0.05), // #1F140D
                surface: Color(red: 0.20, green: 0.13, blue: 0.08) // #332114
            )
            
        // Teal Theme
        case (.teal, .light):
            return ThemeColors(
                primary: Color(red: 0.0, green: 0.78, blue: 0.80), // #00C7CC
                secondary: Color(red: 0.22, green: 0.84, blue: 0.86), // #38D7DB
                accent: Color(red: 0.0, green: 0.62, blue: 0.64), // #009EA3
                background: Color(red: 0.96, green: 1.0, blue: 1.0), // #F5FFFF
                surface: Color(red: 1.0, green: 1.0, blue: 1.0) // White
            )
        case (.teal, .dark):
            return ThemeColors(
                primary: Color(red: 0.22, green: 0.84, blue: 0.86), // #38D7DB
                secondary: Color(red: 0.44, green: 0.90, blue: 0.92), // #70E6EB
                accent: Color(red: 0.0, green: 0.78, blue: 0.80), // #00C7CC
                background: Color(red: 0.05, green: 0.12, blue: 0.12), // #0D1F1F
                surface: Color(red: 0.10, green: 0.20, blue: 0.20) // #1A3333
            )
            
        // Indigo Theme
        case (.indigo, .light):
            return ThemeColors(
                primary: Color(red: 0.35, green: 0.34, blue: 0.84), // #5856D6
                secondary: Color(red: 0.50, green: 0.49, blue: 0.90), // #7F7DE6
                accent: Color(red: 0.25, green: 0.24, blue: 0.70), // #403DB3
                background: Color(red: 0.97, green: 0.97, blue: 1.0), // #F7F7FF
                surface: Color(red: 1.0, green: 1.0, blue: 1.0) // White
            )
        case (.indigo, .dark):
            return ThemeColors(
                primary: Color(red: 0.50, green: 0.49, blue: 0.90), // #7F7DE6
                secondary: Color(red: 0.65, green: 0.64, blue: 0.95), // #A5A3F2
                accent: Color(red: 0.35, green: 0.34, blue: 0.84), // #5856D6
                background: Color(red: 0.07, green: 0.07, blue: 0.12), // #12121F
                surface: Color(red: 0.13, green: 0.13, blue: 0.20) // #212133
            )
        @unknown default:
            // Fallback to blue theme if new cases are added
            return colors(for: .blue, colorScheme: .light)
        }
    }
}

enum AppColorScheme: String, Codable {
    case light
    case dark
    case system
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedAppTheme")
            applyTheme()
        }
    }
    
    @Published var selectedColorScheme: AppColorScheme {
        didSet {
            UserDefaults.standard.set(selectedColorScheme.rawValue, forKey: "selectedAppColorScheme")
            applyColorScheme()
        }
    }
    
    @Published var overrideColorScheme: ColorScheme?
    
    static let shared = ThemeManager()
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedAppTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.selectedTheme = theme
        } else {
            self.selectedTheme = .blue // Default theme
        }
        
        if let savedScheme = UserDefaults.standard.string(forKey: "selectedAppColorScheme"),
           let scheme = AppColorScheme(rawValue: savedScheme) {
            self.selectedColorScheme = scheme
        } else {
            self.selectedColorScheme = .system
        }
        
        applyColorScheme()
    }
    
    func colors(for colorScheme: ColorScheme) -> ThemeColors {
        let effectiveScheme = overrideColorScheme ?? colorScheme
        return ThemeColors.colors(for: selectedTheme, colorScheme: effectiveScheme)
    }
    
    private func applyTheme() {
        // Trigger UI update
        objectWillChange.send()
    }
    
    private func applyColorScheme() {
        switch selectedColorScheme {
        case .light:
            overrideColorScheme = .light
        case .dark:
            overrideColorScheme = .dark
        case .system:
            overrideColorScheme = nil
        }
        objectWillChange.send()
    }
}

// Extension to make ThemeColors easily accessible
extension Color {
    static func themePrimary(for theme: AppTheme, colorScheme: ColorScheme) -> Color {
        ThemeColors.colors(for: theme, colorScheme: colorScheme).primary
    }
    
    static func themeSecondary(for theme: AppTheme, colorScheme: ColorScheme) -> Color {
        ThemeColors.colors(for: theme, colorScheme: colorScheme).secondary
    }
    
    static func themeAccent(for theme: AppTheme, colorScheme: ColorScheme) -> Color {
        ThemeColors.colors(for: theme, colorScheme: colorScheme).accent
    }
}

