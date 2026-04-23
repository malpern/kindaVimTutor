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
    /// A one-beat content step that draws an animated arrow gesturing
    /// up toward the live mode chip in the toolbar. Anchors the abstract
    /// mode concept to the concrete UI element the learner will
    /// reference forever.
    case modeIndicatorSpotlight
    /// Renders the QWERTY home row with specified keys highlighted as
    /// active. Used to anchor "the keys are right under your hand"
    /// claims to actual key placement.
    case homeRow(highlighted: [String])
    /// Visualizes the operator × motion grammar as a 2D grid so the
    /// compositional nature of Vim commands becomes concrete.
    case grammarGrid
    /// Side-by-side comparison of `f` and `t` on identical text to
    /// show that f lands ON the target while t stops just BEFORE it.
    case findVsTill
    /// External link rendered in a tip-style container. Opens in the
    /// user's default browser.
    case linkTip(sfSymbol: String, accent: LinkAccent, label: String, url: String)
    case spacer
}

enum LinkAccent: Sendable {
    case youtube
    case neutral
}
