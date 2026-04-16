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
         difficulty: Difficulty, drillCount: Int = 5, variations: [Variation] = []) {
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
