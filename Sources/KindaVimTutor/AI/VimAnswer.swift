#if canImport(FoundationModels)
import FoundationModels

/// Structured response schema for the chat. Forces the on-device
/// model to separate the answer from the "related motions" list and
/// the optional "faster way" tip, which lets us render each part in
/// its own lesson-style card instead of free-form prose.
///
/// The `webSearchQuery` field gives the model a way to request
/// supplementary web results. The host fires `WebSearchService`
/// only when this is non-empty, so the model decides when related
/// reading is worth showing.
@available(macOS 26.0, *)
@Generable
struct VimAnswer: Equatable {
    @Guide(description: """
        A direct 1–3 sentence answer. Use backtick-wrapped tokens \
        for keys (e.g. `dw`, `Esc`) and double-brace tokens for Vim \
        modes (e.g. {{normal}}, {{insert}}, {{visual}}). Prefer \
        concrete examples to abstract explanations.
        """)
    var answer: String

    @Guide(description: """
        Two to four related commands a student might want next. \
        CRITICAL: do NOT include any command that already appears \
        in the `answer` field — pick legitimately different \
        follow-up motions (e.g. if the answer teaches `dw`, \
        suggest `diw`, `daw`, `cw`, `db`). Return an empty array \
        if no genuinely different commands fit.
        """)
    var relatedCommands: [RelatedCommand]

    @Guide(description: """
        Optional. If there's a noticeably faster or more idiomatic \
        way to accomplish what the user asked, describe it in one \
        sentence using the same token conventions. Omit entirely \
        if there isn't a better way.
        """)
    var fasterAlternative: String?

    @Guide(description: """
        Set to true when the user's question is about a feature \
        kindaVim does NOT implement (macros, Ex commands, named \
        registers, splits, marks, folds, etc.). When true, the \
        host renders a "Not Supported in kindaVim" card. The \
        `answer` field MUST stay short and definitive in this \
        case — just state that kindaVim doesn't support it and \
        point to the closest supported alternative if one exists. \
        Put any "how it works in stock Vim" content into \
        `terminalVimExplanation` instead.
        """)
    var isUnsupported: Bool

    @Guide(description: """
        Optional. Populate ONLY when `isUnsupported` is true. 2–4 \
        sentences describing how the feature works in stock \
        (terminal) Vim, using the same `backtick` and \
        `{{{{mode}}}}` token conventions. This renders as a \
        separate "Terminal VIM" card below the unsupported \
        statement.
        """)
    var terminalVimExplanation: String?

    @Guide(description: """
        Optional. If the answer would benefit from web articles or \
        cheat sheets, provide a short search query (e.g. \
        "vim word motions tutorial"). Omit when the answer is \
        self-contained.
        """)
    var webSearchQuery: String?

    @Guide(description: """
        Optional. If a video walkthrough would help the user, \
        provide a short YouTube search query (e.g. "dw vim", \
        "vim text objects"). Keep it 2–4 words, always include \
        "vim". Omit when the question is a quick reference lookup.
        """)
    var videoSearchQuery: String?
}

@available(macOS 26.0, *)
@Generable
struct RelatedCommand: Equatable {
    @Guide(description: """
        The bare key sequence without backticks, e.g. "diw", "cw".
        """)
    var command: String

    @Guide(description: """
        A short 4–8 word description of what the command does, \
        like "delete inside the word under cursor" or "change \
        until end of line". Do not restate the command name.
        """)
    var summary: String
}
#endif
