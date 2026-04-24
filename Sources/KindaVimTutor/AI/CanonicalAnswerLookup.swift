import Foundation

/// Matches a free-form user question against the pre-authored
/// `CanonicalQA` entries in the help corpus. When a match clears
/// the confidence threshold the chat can serve the stored answer
/// directly and skip the on-device model entirely.
///
/// Scoring is a simple token-overlap ratio — cheap, deterministic,
/// no embeddings at runtime. Good enough for the "paraphrase of a
/// known question" case; drops through to live generation for
/// anything else.
enum CanonicalAnswerLookup {
    struct Match {
        let topic: HelpTopic
        let qa: CanonicalQA
        let score: Double
    }

    /// Confidence below which we fall through to the on-device
    /// model. Tuned against the sample canonical set — lower values
    /// cause "how do I delete a line" to match "how do I delete a
    /// word" which is the wrong answer.
    private static let matchThreshold: Double = 0.55

    static func match(
        for question: String,
        in topics: [HelpTopic],
        preferredTopicID: String? = nil
    ) -> Match? {
        let questionTokens = tokens(in: question)
        guard !questionTokens.isEmpty else { return nil }

        var best: Match?
        for topic in topics {
            for qa in topic.canonicalQA {
                let canonicalTokens = tokens(in: qa.question)
                guard !canonicalTokens.isEmpty else { continue }
                let overlap = Double(questionTokens.intersection(canonicalTokens).count)
                let union = Double(questionTokens.union(canonicalTokens).count)
                var score = overlap / max(union, 1)

                // Nudge scores up on the user's current topic so
                // ambiguous questions prefer the page they're on.
                if topic.id == preferredTopicID {
                    score += 0.08
                }

                if score >= matchThreshold, (best?.score ?? 0) < score {
                    best = Match(topic: topic, qa: qa, score: score)
                }
            }
        }
        return best
    }

    /// Mirrors the `CurriculumLookup` tokenizer: lowercase alphanumerics
    /// only, minimum length 3, strip a small stopword list so common
    /// words like "the" and "how" don't dominate the overlap.
    private static let stopwords: Set<String> = [
        "the", "and", "you", "your", "for", "with", "from", "that",
        "this", "are", "can", "use", "how", "what", "when", "where",
        "will", "would", "should", "could", "vim", "kindavim", "key",
        "does", "did", "it's", "they", "these", "those", "about",
        "into", "onto", "also", "some", "then"
    ]

    private static func tokens(in text: String) -> Set<String> {
        let normalizedText = HelpQueryNormalizer.standardized(text)
        var tokens: Set<String> = []

        // Pull backtick-wrapped commands (`dw`, `ci"`, `Esc`) first
        // and always keep them, regardless of length.
        var cursor = normalizedText.startIndex
        while cursor < normalizedText.endIndex {
            if normalizedText[cursor] == "`" {
                let after = normalizedText.index(after: cursor)
                if let close = normalizedText[after...].firstIndex(of: "`") {
                    let cmd = String(normalizedText[after..<close]).lowercased()
                    if !cmd.isEmpty { tokens.insert(cmd) }
                    cursor = normalizedText.index(after: close)
                    continue
                }
            }
            cursor = normalizedText.index(after: cursor)
        }

        // Regular word tokens from surrounding prose.
        let lowered = HelpQueryNormalizer.normalizedComparable(normalizedText)
        let separators = CharacterSet.alphanumerics.inverted
        let parts = lowered.components(separatedBy: separators)
            .filter { !$0.isEmpty }

        // Keep any part that's either (a) a known kindaVim command
        // regardless of length — so "explain u" matches the undo
        // canonical — or (b) a normal-length, non-stopword prose
        // word.
        for part in parts {
            if KindaVimSupportCorpus.shared.isExplicitlyUnsupported(part)
                || KindaVimSupportCorpus.shared.isKnownCommand(part)
            {
                tokens.insert(part)
            } else if part.count >= 3, !stopwords.contains(part) {
                tokens.insert(part)
            }
        }

        for candidate in HelpQueryNormalizer.normalizedLookupCandidates(for: normalizedText) {
            if let decomposition = HelpQueryNormalizer.decomposeCommandToken(candidate) {
                tokens.insert(decomposition.core)
                if let op = decomposition.operatorPrefix {
                    tokens.insert(op + decomposition.core)
                }
            }
            if candidate.count >= 3, !stopwords.contains(candidate) {
                tokens.insert(candidate)
            }
        }
        return tokens
    }
}
