import SwiftUI

enum Typography {
    static let heading = Font.system(.title2, design: .default, weight: .bold)
    static let body = Font.system(.body, design: .default)
    static let code = Font.system(.body, design: .monospaced)
    static let caption = Font.system(.caption, design: .default)
    @MainActor static let editorFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
}
