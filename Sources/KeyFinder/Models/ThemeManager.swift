import SwiftUI

class ThemeManager: ObservableObject {
    enum Theme: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }

    @Published var currentTheme: Theme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.dark.rawValue
        self.currentTheme = Theme(rawValue: savedTheme) ?? .dark
    }

    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    // Theme colors
    var backgroundColor: Color {
        switch currentTheme {
        case .dark, .system:
            return Color.black
        case .light:
            return Color.white
        }
    }

    var textColor: Color {
        switch currentTheme {
        case .dark, .system:
            return Color.white
        case .light:
            return Color.black
        }
    }

    var secondaryTextColor: Color {
        switch currentTheme {
        case .dark, .system:
            return Color.white.opacity(0.7)
        case .light:
            return Color.black.opacity(0.7)
        }
    }

    var tertiaryTextColor: Color {
        switch currentTheme {
        case .dark, .system:
            return Color.white.opacity(0.5)
        case .light:
            return Color.black.opacity(0.5)
        }
    }

    var surfaceColor: Color {
        switch currentTheme {
        case .dark, .system:
            return Color.white.opacity(0.05)
        case .light:
            return Color.black.opacity(0.05)
        }
    }

    var borderColor: Color {
        switch currentTheme {
        case .dark, .system:
            return Color.white.opacity(0.2)
        case .light:
            return Color.black.opacity(0.2)
        }
    }

    // Purple accent for dark mode
    var accentColor: Color {
        switch currentTheme {
        case .dark, .system:
            return Color(red: 0.55, green: 0.35, blue: 0.85) // Darker purple
        case .light:
            return Color(red: 0.5, green: 0.3, blue: 0.8) // Darker purple for light mode
        }
    }

    var accentColorSubtle: Color {
        accentColor.opacity(0.3)
    }
}
