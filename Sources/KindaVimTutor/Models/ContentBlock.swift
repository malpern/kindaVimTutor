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
    /// Displays an image from the bundle at a given size (points).
    case image(assetName: String, size: CGFloat)
    /// Renders either a green "installed" confirmation or a primary CTA
    /// button that opens kindavim.app, depending on live install state.
    case kindaVimInstallStatus
    /// Hand-crafted prose paragraph describing the typical mode-flip flow,
    /// with inline mode chips rendered directly inside the text.
    case modeFlowNarrative
    /// Animated show-rather-than-tell demonstration of Insert vs Normal
    /// mode. Plays a scripted sequence with a caret, a pressed-key chip,
    /// a mode chip, and a caption. Loops until the student advances.
    case modesDemo
    /// External link rendered in a tip-style container. Opens in the
    /// user's default browser.
    case linkTip(sfSymbol: String, accent: LinkAccent, label: String, url: String)
    case spacer
}

enum LinkAccent: Sendable {
    case youtube
    case neutral
}
