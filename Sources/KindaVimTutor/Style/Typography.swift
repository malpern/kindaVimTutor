import SwiftUI

enum Typography {
    // Lesson content hierarchy — tight tracking like vimified
    static let chapterLabel = Font.system(size: 13, weight: .bold, design: .default)
    static let lessonTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let lessonSubtitle = Font.system(size: 18, weight: .regular, design: .default)
    static let sectionHeading = Font.system(size: 22, weight: .bold, design: .default)
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySecondary = Font.system(size: 14, weight: .regular, design: .default)
    static let code = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    // Keycap
    static let keyCap = Font.system(size: 14, weight: .bold, design: .monospaced)
    static let keyCapLarge = Font.system(size: 18, weight: .bold, design: .monospaced)

    // Editor
    @MainActor static let editorFont = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)

    // Tracking (letter-spacing) values
    static let headingTracking: CGFloat = -0.8
    static let titleTracking: CGFloat = -0.5
    static let chapterTracking: CGFloat = 1.5
}
