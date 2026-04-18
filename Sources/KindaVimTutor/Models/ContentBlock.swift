import Foundation

enum ContentBlock: Sendable {
    case text(String)
    case heading(String)
    case tip(String)
    case important(String)
    case keyCommand(keys: [String], description: String)
    case codeExample(before: String, after: String, motion: String)
    /// Inline mode-indicator preview so learners can see what a given
    /// kindaVim mode chip looks like without leaving the tutor.
    case modePreview(VimMode, caption: String)
    case spacer
}
