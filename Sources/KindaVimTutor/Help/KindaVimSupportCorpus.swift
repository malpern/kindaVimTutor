import Foundation

/// Source of truth for which Vim commands kindaVim implements.
/// Parses the bundled `kindavim-support.txt` once at launch. Views
/// call `isSupported(_:)` when rendering a key token so the UI can
/// stamp a visible "not in kindaVim" marker next to unsupported
/// commands wherever they appear (chat, manual, lesson prose).
enum KindaVimSupportCorpus {
    /// Public docs page that lists which Vim commands kindaVim
    /// supports. Unsupported-command badges and the "Not Supported
    /// by kindaVim" banner deep-link here so users can see the full
    /// compatibility matrix.
    static let docsURL = URL(string: "https://docs.kindavim.app/kindavim-features/supported-vim-commands")!

    struct Entry: Equatable, Sendable {
        let command: String
        let note: String
    }

    static let shared = load()

    struct Corpus: Sendable {
        let supported: [Entry]
        let unsupported: [Entry]
        /// Concept keywords extracted from `# keywords: ...` lines
        /// in the unsupported section. Used by `ContentRelevanceFilter`
        /// to drop video/web results whose titles clearly advertise
        /// features kindaVim doesn't implement (e.g. "macros",
        /// "window split", "folding").
        let unsupportedKeywords: [String]
        private let supportedSet: Set<String>
        private let unsupportedSet: Set<String>

        /// Returns `true` when the given token is explicitly listed
        /// as supported. Strips leading counts (`3dw` → `dw`) and
        /// register prefixes (`"ay` → `y`) before matching.
        func isSupported(_ token: String) -> Bool {
            let normalized = normalize(token)
            if supportedSet.contains(normalized) { return true }
            if unsupportedSet.contains(normalized) { return false }
            // Unknown tokens: treat as supported to avoid peppering
            // the UI with badges on common motions we simply didn't
            // bother listing (e.g. standalone punctuation like `)`).
            return true
        }

        /// Explicit unsupported match. Used by the UI to only badge
        /// commands we've affirmatively flagged — "unknown" stays
        /// neutral.
        func isExplicitlyUnsupported(_ token: String) -> Bool {
            unsupportedSet.contains(normalize(token))
        }

        /// Returns true when the token appears in either list — i.e.
        /// we know what it is. Lets the chat treat short unwrapped
        /// Vim commands (`u`, `w`, `e`) as real tokens instead of
        /// dropping them as 1-char prose noise.
        func isKnownCommand(_ token: String) -> Bool {
            let n = normalize(token)
            return supportedSet.contains(n) || unsupportedSet.contains(n)
        }

        func note(for token: String) -> String? {
            let normalized = normalize(token)
            return unsupported.first(where: { $0.command == normalized })?.note
                ?? supported.first(where: { $0.command == normalized })?.note
        }

        fileprivate init(
            supported: [Entry],
            unsupported: [Entry],
            unsupportedKeywords: [String] = []
        ) {
            self.supported = supported
            self.unsupported = unsupported
            self.unsupportedKeywords = unsupportedKeywords
            self.supportedSet = Set(supported.map(\.command))
            self.unsupportedSet = Set(unsupported.map(\.command))
        }

        private func normalize(_ token: String) -> String {
            var t = token.trimmingCharacters(in: .whitespacesAndNewlines)
            // Strip leading count digits (3dw → dw, 10G → G).
            while let first = t.first, first.isNumber { t.removeFirst() }
            // Strip register prefix ("ay → y). Keep the bare `"` on
            // its own since that's the register prefix itself.
            if t.count > 1, t.hasPrefix("\"") {
                let afterQuote = t.dropFirst()
                if !afterQuote.isEmpty {
                    t = String(afterQuote.dropFirst())
                }
            }
            return t
        }
    }

    private static func load() -> Corpus {
        let url = Bundle.module.url(
            forResource: "kindavim-support",
            withExtension: "txt"
        ) ?? Bundle.main.url(
            forResource: "kindavim-support",
            withExtension: "txt"
        )
        guard let url,
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return Corpus(supported: [], unsupported: [])
        }
        return parse(text)
    }

    private static func parse(_ text: String) -> Corpus {
        var supported: [Entry] = []
        var unsupported: [Entry] = []
        var unsupportedKeywords: [String] = []
        var current: Bucket = .none

        enum Bucket { case none, supported, unsupported }

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            // `# keywords: foo, bar` lines inside the unsupported
            // section contribute to the video/web result filter.
            // All other `#` lines are plain comments.
            if line.hasPrefix("#") {
                if current == .unsupported {
                    let stripped = line.dropFirst().trimmingCharacters(in: .whitespaces)
                    if stripped.lowercased().hasPrefix("keywords:") {
                        let list = stripped.dropFirst("keywords:".count)
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        unsupportedKeywords.append(contentsOf: list)
                    }
                }
                continue
            }
            if line.lowercased().hasPrefix("supported:") {
                current = .supported; continue
            }
            if line.lowercased().hasPrefix("unsupported:") {
                current = .unsupported; continue
            }
            // `command — note` (em-dash) or `command - note` (hyphen).
            let parts = line.split(
                maxSplits: 1,
                omittingEmptySubsequences: false,
                whereSeparator: { $0 == "—" || $0 == "-" }
            )
            guard !parts.isEmpty else { continue }
            let command = parts[0].trimmingCharacters(in: .whitespaces)
            let note = parts.count > 1
                ? parts[1].trimmingCharacters(in: .whitespaces)
                : ""
            guard !command.isEmpty else { continue }
            let entry = Entry(command: command, note: note)
            switch current {
            case .supported:   supported.append(entry)
            case .unsupported: unsupported.append(entry)
            case .none:        continue
            }
        }
        return Corpus(
            supported: supported,
            unsupported: unsupported,
            unsupportedKeywords: unsupportedKeywords
        )
    }

    /// Compact comma-separated command list for inclusion in a
    /// system prompt. The on-device 3B model has a 4096-token
    /// context window — the per-entry `- \`cmd\` — note` format
    /// consumed ~1400 tokens and forced generation failures, so
    /// prompt-grounding uses just the tokens.
    static func asPromptBlock() -> String {
        let supportedList = shared.supported
            .map { "`\($0.command)`" }
            .joined(separator: ", ")
        let unsupportedList = shared.unsupported
            .map { "`\($0.command)`" }
            .joined(separator: ", ")
        return """
        ### Supported kindaVim commands
        \(supportedList)

        ### Unsupported (kindaVim does NOT implement these)
        \(unsupportedList)
        """
    }
}
