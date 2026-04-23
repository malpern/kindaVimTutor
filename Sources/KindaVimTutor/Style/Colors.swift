import SwiftUI

enum AppColors {
    // Editor — clearly distinct from body text, recessed code field
    static let editorBackground = Color(light: .init(white: 0.94),
                                        dark: .init(white: 0.13))

    // Content callouts — background tint only, no borders
    static let tipBackground = Color(light: .init(red: 0.95, green: 0.96, blue: 1.0),
                                     dark: .init(white: 0.14))
    static let importantBackground = Color(light: .init(red: 1.0, green: 0.97, blue: 0.94),
                                           dark: .init(white: 0.14))

    // Code examples
    static let codeBackground = Color(light: .init(white: 0.965),
                                      dark: .init(white: 0.14))

    // Manual / reference surface — cleaner, flatter, more archival than lessons.
    static let manualRailBackground = Color(light: .init(red: 0.93, green: 0.94, blue: 0.95),
                                            dark: .init(red: 0.13, green: 0.14, blue: 0.15))
    static let manualCanvasBackground = Color(light: .init(red: 0.965, green: 0.968, blue: 0.972),
                                              dark: .init(red: 0.10, green: 0.11, blue: 0.12))
    static let manualPanelBackground = Color(light: .init(red: 0.98, green: 0.982, blue: 0.985),
                                             dark: .init(red: 0.16, green: 0.17, blue: 0.18))
    static let manualPanelBorder = Color(light: .init(red: 0.82, green: 0.84, blue: 0.86),
                                         dark: .init(red: 0.26, green: 0.27, blue: 0.29))
    static let manualHeroBackground = Color(light: .init(red: 0.95, green: 0.96, blue: 0.98),
                                            dark: .init(red: 0.14, green: 0.16, blue: 0.18))
    static let manualHeroBorder = Color(light: .init(red: 0.74, green: 0.78, blue: 0.84),
                                        dark: .init(red: 0.34, green: 0.39, blue: 0.45))
    static let manualAccent = Color(light: .init(red: 0.10, green: 0.34, blue: 0.52),
                                    dark: .init(red: 0.53, green: 0.75, blue: 0.90))
    static let manualMutedText = Color(light: .init(red: 0.34, green: 0.38, blue: 0.42),
                                       dark: .init(red: 0.62, green: 0.66, blue: 0.70))

    // Mode indicator
    static let normalMode = Color.green
    static let insertMode = Color.blue
    static let visualMode = Color.purple
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
    }
}
