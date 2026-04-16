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

    // Editor font — try iA Writer Mono, Menlo, then fall back to system mono
    @MainActor static let editorFont: NSFont = {
        // Try distinctive monospaced fonts in order of preference
        let candidates = ["iA Writer Mono S", "Menlo", "SF Mono"]
        for name in candidates {
            if let font = NSFont(name: name, size: 15) {
                return font
            }
        }
        return NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
    }()

    static let headingTracking: CGFloat = -0.5
    static let titleTracking: CGFloat = -0.3
    static let chapterTracking: CGFloat = 1.2
}
