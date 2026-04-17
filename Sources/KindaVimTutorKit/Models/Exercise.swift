import Foundation

/// A single drillable exercise: starting text/cursor → expected text/cursor,
/// repeated `drillCount` times. Variations rotate across reps so the user can't
/// succeed by muscle memory alone. Consumed by `ExerciseEngine` for validation
/// and by drill views for rendering.
public struct Exercise: Identifiable, Equatable, Sendable {
    public let id: String
    public let instruction: String
    public let initialText: String
    public let initialCursorPosition: Int
    public let expectedText: String
    public let expectedCursorPosition: Int?
    public let hints: [String]
    public let difficulty: Difficulty
    public let drillCount: Int
    public let variations: [Variation]

    /// One alternate starting state / expected state pair used for a drill rep.
    public struct Variation: Equatable, Sendable {
        public let initialText: String
        public let initialCursorPosition: Int
        public let expectedText: String
        public let expectedCursorPosition: Int?

        public init(initialText: String, initialCursorPosition: Int, expectedText: String, expectedCursorPosition: Int?) {
            self.initialText = initialText
            self.initialCursorPosition = initialCursorPosition
            self.expectedText = expectedText
            self.expectedCursorPosition = expectedCursorPosition
        }
    }

    /// Pedagogical tier of the exercise. Currently advisory only.
    public enum Difficulty: String, Sendable, Codable {
        case learn
        case practice
        case master
    }

    public init(id: String, instruction: String, initialText: String, initialCursorPosition: Int,
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
    public func variation(for rep: Int) -> Variation {
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
