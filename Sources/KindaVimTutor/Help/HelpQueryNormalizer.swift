import Foundation

enum HelpQueryNormalizer {
    private static let operatorPrefixes = ["d", "c", "y", "v"]

    private static let objectPhraseMap: [(phrase: String, command: String)] = [
        ("inside double quotes", #"i""#),
        ("inside quotes", #"i""#),
        ("inside quoted string", #"i""#),
        ("inside string", #"i""#),
        ("around double quotes", #"a""#),
        ("around quotes", #"a""#),
        ("inside single quotes", "i'"),
        ("around single quotes", "a'"),
        ("inside parentheses", "ib"),
        ("inside parens", "ib"),
        ("around parentheses", "ab"),
        ("around parens", "ab"),
        ("inside braces", "iB"),
        ("around braces", "aB"),
        ("inside brackets", "i["),
        ("around brackets", "a["),
        ("inside word", "iw"),
        ("around word", "aw"),
        ("inner word", "iw"),
        ("outer word", "aw")
    ]

    private static let operatorPhraseMap: [(phrase: String, command: String)] = [
        ("change", "c"),
        ("delete", "d"),
        ("yank", "y"),
        ("copy", "y"),
        ("select", "v"),
        ("visual select", "v")
    ]

    static func standardized(_ text: String) -> String {
        text
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
    }

    static func normalizedComparable(_ text: String) -> String {
        standardized(text)
            .lowercased()
            .replacingOccurrences(
                of: #"\s+"#,
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedLookupCandidates(for query: String) -> [String] {
        let normalized = normalizedComparable(query)
        guard !normalized.isEmpty else { return [] }
        let phraseNormalized = normalized
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")

        var candidates: [String] = []
        func append(_ value: String?) {
            guard let value else { return }
            let cleaned = normalizedComparable(value)
            guard !cleaned.isEmpty, !candidates.contains(cleaned) else { return }
            candidates.append(cleaned)
        }

        append(normalized)

        for token in extractBacktickContents(from: normalized) {
            append(token)
        }

        let trimSet = CharacterSet(charactersIn: ".,?!:;()[]{}")
        for rawToken in standardized(query).split(whereSeparator: \.isWhitespace) {
            let part = normalizedComparable(
                String(rawToken).trimmingCharacters(in: trimSet)
            )
            if (KindaVimSupportCorpus.shared.isKnownCommand(part)
                || KindaVimSupportCorpus.shared.isExplicitlyUnsupported(part))
                && (part.count > 1 || normalized == part)
                && !part.isEmpty
            {
                append(part)
            }
        }

        for stripped in strippedPhrases(from: normalized) {
            append(stripped)
        }

        let matchedOperators = operatorPhraseMap.filter { phraseNormalized.contains($0.phrase) }
        if matchedOperators.isEmpty {
            for mapping in objectPhraseMap where phraseNormalized.contains(mapping.phrase) {
                append(mapping.command)
            }
        }

        for op in matchedOperators {
            for object in objectPhraseMap where phraseNormalized.contains(object.phrase) {
                append(op.command + object.command)
            }
        }

        return candidates
    }

    static func decomposeCommandToken(_ token: String) -> (operatorPrefix: String?, core: String)? {
        var cleaned = normalizedComparable(token)
            .replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return nil }

        while let first = cleaned.first, first.isNumber {
            cleaned.removeFirst()
        }

        if cleaned.count > 1, cleaned.hasPrefix("\"") {
            let afterQuote = cleaned.dropFirst()
            if !afterQuote.isEmpty {
                cleaned = String(afterQuote.dropFirst())
            }
        }

        guard !cleaned.isEmpty else { return nil }

        if let prefix = operatorPrefixes.first(where: { cleaned.hasPrefix($0) }),
           cleaned.count > prefix.count {
            return (prefix, String(cleaned.dropFirst(prefix.count)))
        }

        return (nil, cleaned)
    }

    private static func extractBacktickContents(from text: String) -> [String] {
        var out: [String] = []
        var cursor = text.startIndex
        while cursor < text.endIndex {
            if text[cursor] == "`" {
                let after = text.index(after: cursor)
                if let close = text[after...].firstIndex(of: "`") {
                    let value = String(text[after..<close])
                    if !value.isEmpty { out.append(value) }
                    cursor = text.index(after: close)
                    continue
                }
            }
            cursor = text.index(after: cursor)
        }
        return out
    }

    private static func strippedPhrases(from normalized: String) -> [String] {
        let prefixes = [
            "explain ",
            "what is ",
            "what's ",
            "tell me about ",
            "how do i ",
            "how to ",
            "can you explain ",
            "show me ",
            "teach me "
        ]

        var out: [String] = []
        for prefix in prefixes where normalized.hasPrefix(prefix) {
            let stripped = String(normalized.dropFirst(prefix.count))
            if !stripped.isEmpty {
                out.append(stripped)
            }
        }
        return out
    }
}
