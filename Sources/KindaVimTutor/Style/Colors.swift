import SwiftUI

enum AppColors {
    // Mode indicator
    static let normalMode = Color.green
    static let insertMode = Color.blue
    static let visualMode = Color.purple

    // Exercise
    static let completedGreen = Color.green

    // Content blocks — adaptive for light/dark
    static let tipBackground = Color(light: .init(red: 0.93, green: 0.95, blue: 1.0),
                                     dark: .init(white: 0.16))
    static let tipBorder = Color(light: .blue.opacity(0.15),
                                 dark: .blue.opacity(0.25))
    static let importantBackground = Color(light: .init(red: 1.0, green: 0.96, blue: 0.92),
                                           dark: .init(white: 0.16))
    static let importantBorder = Color(light: .orange.opacity(0.15),
                                       dark: .orange.opacity(0.25))
    static let codeBackground = Color(light: .init(white: 0.96),
                                      dark: .init(white: 0.14))

    // Cards and surfaces
    static let cardBackground = Color(light: .white,
                                      dark: .init(white: 0.13))
    static let cardBorder = Color(light: .primary.opacity(0.06),
                                  dark: .primary.opacity(0.1))
    static let subtleBackground = Color(light: .init(white: 0.97),
                                        dark: .init(white: 0.11))

    // Editor
    static let editorBackground = Color(light: .init(white: 0.14),
                                        dark: .init(white: 0.10))
    static let editorStatusBar = Color(light: .init(white: 0.11),
                                       dark: .init(white: 0.08))
}

// Adaptive color helper
extension Color {
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
    }
}
