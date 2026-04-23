import Foundation

/// Maps a free-form answer back to lessons in our curriculum by
/// keyword match. Keeps the model honest — instead of letting it
/// invent lesson IDs, the app is the source of truth for what's
/// actually available.
enum CurriculumLookup {
    /// Returns lessons whose title/subtitle tokens overlap the answer,
    /// ranked by overlap count. Caps at 3 so the chat card stays
    /// scannable. Threshold of 2 keeps us from surfacing lessons that
    /// coincidentally share one common word.
    static func matches(for text: String, chapters: [Chapter]) -> [Lesson] {
        let haystackTokens = Self.tokens(in: text)
        guard !haystackTokens.isEmpty else { return [] }

        var scored: [(Lesson, Int)] = []
        for chapter in chapters {
            for lesson in chapter.lessons {
                let lessonTokens = Self.tokens(in:
                    "\(lesson.title) \(lesson.subtitle)"
                )
                let overlap = haystackTokens.intersection(lessonTokens).count
                if overlap >= 2 {
                    scored.append((lesson, overlap))
                }
            }
        }
        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }
    }

    private static let stopwords: Set<String> = [
        "the", "and", "you", "your", "for", "with", "from", "that",
        "this", "are", "can", "use", "how", "what", "when", "where",
        "will", "would", "should", "could", "vim", "mode", "key",
        "keys", "press", "press"
    ]

    private static func tokens(in text: String) -> Set<String> {
        let lowered = text.lowercased()
        let separators = CharacterSet.alphanumerics.inverted
        let parts = lowered.components(separatedBy: separators)
            .filter { $0.count >= 3 }
            .filter { !stopwords.contains($0) }
        return Set(parts)
    }
}
