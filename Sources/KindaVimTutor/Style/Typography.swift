import SwiftUI

enum Typography {
    static let chapterLabel = Font.system(size: 13, weight: .semibold)
    static let lessonTitle = Font.system(size: 32, weight: .bold)
    static let lessonSubtitle = Font.system(size: 17, weight: .regular)
    static let sectionHeading = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let bodySecondary = Font.system(size: 14, weight: .regular)
    static let code = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let caption = Font.system(size: 12, weight: .regular)

    @MainActor static let editorFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    static let headingTracking: CGFloat = -0.5
    static let titleTracking: CGFloat = -0.3
    static let chapterTracking: CGFloat = 1.2
}
