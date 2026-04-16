import Testing
@testable import KindaVimTutor

@Suite("Exercise variations")
struct ExerciseTests {
    @Test("rep 0 uses the base exercise, regardless of variations")
    func repZeroUsesBase() {
        let ex = Exercise(
            id: "t.base",
            instruction: "delete word",
            initialText: "hello world",
            initialCursorPosition: 0,
            expectedText: "hello",
            expectedCursorPosition: 5,
            hints: [],
            difficulty: .learn,
            drillCount: 3,
            variations: [
                .init(initialText: "a", initialCursorPosition: 0, expectedText: "", expectedCursorPosition: 0)
            ]
        )

        let v = ex.variation(for: 0)
        #expect(v.initialText == "hello world")
        #expect(v.expectedText == "hello")
        #expect(v.expectedCursorPosition == 5)
    }

    @Test("rep >= 1 cycles through variations")
    func variationsCycle() {
        let v1 = Exercise.Variation(initialText: "one", initialCursorPosition: 0, expectedText: "1", expectedCursorPosition: 0)
        let v2 = Exercise.Variation(initialText: "two", initialCursorPosition: 0, expectedText: "2", expectedCursorPosition: 0)
        let ex = Exercise(
            id: "t.cycle",
            instruction: "",
            initialText: "base",
            initialCursorPosition: 0,
            expectedText: "b",
            expectedCursorPosition: nil,
            hints: [],
            difficulty: .learn,
            drillCount: 5,
            variations: [v1, v2]
        )

        #expect(ex.variation(for: 1) == v1)
        #expect(ex.variation(for: 2) == v2)
        #expect(ex.variation(for: 3) == v1)
        #expect(ex.variation(for: 4) == v2)
    }

    @Test("no variations falls back to base for every rep")
    func noVariationsFallsBack() {
        let ex = Exercise(
            id: "t.novar",
            instruction: "",
            initialText: "x",
            initialCursorPosition: 0,
            expectedText: "y",
            expectedCursorPosition: nil,
            hints: [],
            difficulty: .learn
        )
        #expect(ex.variation(for: 0).initialText == "x")
        #expect(ex.variation(for: 7).initialText == "x")
    }
}
