import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

extension Color {
    static let appBackgroundPink = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.08, blue: 0.12, alpha: 1.0) // Dark pink-ish shade
            : UIColor(red: 1.0, green: 0.94, blue: 0.96, alpha: 1.0)  // Light pink-ish shade
    })
}
