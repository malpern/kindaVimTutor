import SwiftUI

enum Typography {
    // Lesson content hierarchy
    static let chapterLabel = Font.system(.subheadline, design: .default, weight: .semibold)
    static let lessonTitle = Font.system(.largeTitle, design: .default, weight: .bold)
    static let lessonSubtitle = Font.system(.title3, design: .default, weight: .regular)
    static let sectionHeading = Font.system(.title3, design: .default, weight: .semibold)
    static let body = Font.system(.body, design: .default, weight: .regular)
    static let bodySecondary = Font.system(.callout, design: .default, weight: .regular)
    static let code = Font.system(.body, design: .monospaced, weight: .regular)
    static let caption = Font.system(.caption, design: .default, weight: .regular)

    // Keycap
    static let keyCap = Font.system(size: 14, weight: .semibold, design: .monospaced)
    static let keyCapLarge = Font.system(size: 16, weight: .semibold, design: .monospaced)

    // Editor
    @MainActor static let editorFont = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
}
