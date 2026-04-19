import Foundation

struct Exercise: Identifiable, Equatable, Sendable {
    let id: String
    let instruction: String
    let initialText: String
    let initialCursorPosition: Int
    let expectedText: String
    let expectedCursorPosition: Int?
    let hints: [String]
    let difficulty: Difficulty
    let drillCount: Int
    let variations: [Variation]
    /// Minimum keystrokes to complete a single rep using only the
    /// techniques taught by the end of this chapter. Drives the
    /// "chapter target" row in the coaching panel. nil means
    /// untagged — coaching still runs but skips the target tier.
    let optimalKeystrokes: Int?
    /// Lesson-id pointer + short description of a future-chapter
    /// technique that would shave keystrokes off this drill. Drives
    /// the locked "⚡ A faster technique unlocks in…" teaser. nil
    /// means no future optimization to promise.
    let futureOptimization: FutureOptimization?

    struct FutureOptimization: Equatable, Sendable {
        let lessonId: String
        let summary: String
    }

    struct Variation: Equatable, Sendable {
        let initialText: String
        let initialCursorPosition: Int
        let expectedText: String
        let expectedCursorPosition: Int?
    }

    enum Difficulty: String, Sendable, Codable {
        case learn
        case practice
        case master
    }

    init(id: String, instruction: String, initialText: String, initialCursorPosition: Int,
         expectedText: String, expectedCursorPosition: Int?, hints: [String],
         difficulty: Difficulty, drillCount: Int = 5, variations: [Variation] = [],
         optimalKeystrokes: Int? = nil,
         futureOptimization: FutureOptimization? = nil) {
        self.id = id
        self.instruction = instruction
        self.initialText = initialText
        self.initialCursorPosition = initialCursorPosition
        self.expectedText = expectedText
        self.expectedCursorPosition = expectedCursorPosition
        self.hints = hints
        self.difficulty = difficulty
        self.drillCount = drillCount
        self.variations = variations
        self.optimalKeystrokes = optimalKeystrokes
        self.futureOptimization = futureOptimization
    }

    /// Returns the variation for a given rep index (0-based). Rep 0 uses the base exercise.
    func variation(for rep: Int) -> Variation {
        if rep == 0 || variations.isEmpty {
            return Variation(
                initialText: initialText,
                initialCursorPosition: initialCursorPosition,
                expectedText: expectedText,
                expectedCursorPosition: expectedCursorPosition
            )
        }
        let index = (rep - 1) % variations.count
        return variations[index]
    }
}
