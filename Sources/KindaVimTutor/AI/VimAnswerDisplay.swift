import Foundation

/// Display-friendly mirror of `VimAnswer`. Streaming snapshots
/// arrive as `.PartiallyGenerated` with optional fields — we
/// accumulate them here so the view doesn't have to care whether a
/// value was "never set" or "set to nil".
struct VimAnswerDisplay: Equatable {
    struct RelatedCommandDisplay: Equatable {
        var command: String
        var summary: String
    }

    var answer: String = ""
    var relatedCommands: [RelatedCommandDisplay] = []
    var fasterAlternative: String?
    var webSearchQuery: String?
    var videoSearchQuery: String?
    /// True when the question is about a feature kindaVim doesn't
    /// implement. Drives the "Not Supported in kindaVim" card
    /// styling + optional paired Terminal VIM explainer.
    var isUnsupported: Bool = false
    /// Populated alongside `isUnsupported`. Describes how the
    /// feature works in stock terminal Vim.
    var terminalVimExplanation: String?
    /// Set when the answer came from the pre-authored canonical
    /// corpus rather than the on-device model. The bubble shows a
    /// small "From reference" badge so users know the source.
    var isCanonical: Bool = false

    /// A rough "is any part populated" flag — used to decide whether
    /// to render the structured bubble yet or show typing dots.
    var hasContent: Bool {
        !answer.isEmpty || !relatedCommands.isEmpty || fasterAlternative != nil
    }
}
