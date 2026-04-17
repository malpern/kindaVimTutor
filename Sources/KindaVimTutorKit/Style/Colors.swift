import SwiftUI

/// Design-token palette. Colors adapt to light/dark mode via the
/// `Color(light:dark:)` initializer defined below.
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

}

extension Color {
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
    }
}
