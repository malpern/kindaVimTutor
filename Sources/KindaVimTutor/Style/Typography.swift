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

    // Manual / reference typography — denser and more technical than lessons.
    @MainActor static let manualRailTitle: Font = Font(serifFont(size: 20, weight: .bold))
    static let manualRailMeta = Font.system(size: 11, weight: .medium, design: .monospaced)
    @MainActor static let manualTopicTitle: Font = Font(serifFont(size: 30, weight: .bold))
    static let manualSummary = Font.system(size: 14, weight: .medium)
    static let manualSectionLabel = Font.system(size: 10, weight: .black, design: .monospaced)
    static let manualSectionTitle = Font.system(size: 17, weight: .bold, design: .rounded)
    static let manualBody = Font.system(size: 13, weight: .regular)
    static let manualMetaKey = Font.system(size: 10, weight: .black, design: .monospaced)
    static let manualMetaValue = Font.system(size: 12, weight: .semibold, design: .monospaced)
    static let manualCardTitle = Font.system(size: 12, weight: .bold, design: .rounded)
    static let manualCardBody = Font.system(size: 12, weight: .medium)
    static let manualCode = Font.system(size: 12, weight: .semibold, design: .monospaced)

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

    @MainActor private static func serifFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        // Prefer classic readable macOS serif faces for the manual titles.
        let candidates: [(String, CGFloat)] = [
            ("Iowan Old Style Bold", size),
            ("Iowan Old Style", size),
            ("Baskerville-Bold", size),
            ("Baskerville", size),
            ("Times New Roman Bold", size),
            ("Times New Roman", size)
        ]
        for (name, pointSize) in candidates {
            if let font = NSFont(name: name, size: pointSize) {
                return font
            }
        }
        return NSFont.systemFont(ofSize: size, weight: weight)
    }

    static let headingTracking: CGFloat = -0.5
    static let titleTracking: CGFloat = -0.3
    static let chapterTracking: CGFloat = 1.2
    static let manualTracking: CGFloat = 0.9
}
