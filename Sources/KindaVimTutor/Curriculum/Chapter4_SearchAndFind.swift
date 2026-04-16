import Foundation

extension Curriculum {
    static let chapter4 = Chapter(
        id: "ch4",
        number: 4,
        title: "Search & Find",
        subtitle: "Jump to any character on the line",
        systemImage: "magnifyingglass",
        lessons: [
            lesson4_1, lesson4_2, lesson4_3, lesson4_4,
        ]
    )

    // MARK: - Lesson 4.1: Find Character

    private static let lesson4_1 = Lesson(
        id: "ch4.l1",
        number: 1,
        title: "Find Character",
        subtitle: "Jump to a character with f and F",
        explanation: [
            .heading("Jump to Any Character on the Line"),
            .text("Press f followed by a character to jump forward to the next occurrence of that character on the current line. F jumps backward."),
            .spacer,
            .keyCommand(keys: ["f", "x"], description: "Find 'x' forward on this line"),
            .keyCommand(keys: ["F", "x"], description: "Find 'x' backward on this line"),
            .spacer,
            .text("This is one of the fastest ways to move horizontally. Instead of pressing l many times, find the character you want."),
            .tip("f puts the cursor ON the character. This is different from t, which stops just before it."),
        ],
        exercises: [
            Exercise(
                id: "ch4.l1.e1",
                instruction: "Use f to jump to the * and delete it with x",
                initialText: "Jump to the * in this line.",
                initialCursorPosition: 0,
                expectedText: "Jump to the  in this line.",
                expectedCursorPosition: nil,
                hints: ["Type f* to jump to the asterisk, then x to delete it"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "Find the * here now.", initialCursorPosition: 0,
                          expectedText: "Find the  here now.", expectedCursorPosition: nil),
                    .init(initialText: "Go to * quickly.", initialCursorPosition: 0,
                          expectedText: "Go to  quickly.", expectedCursorPosition: nil),
                    .init(initialText: "The target * is here.", initialCursorPosition: 0,
                          expectedText: "The target  is here.", expectedCursorPosition: nil),
                    .init(initialText: "Search for the * mark.", initialCursorPosition: 0,
                          expectedText: "Search for the  mark.", expectedCursorPosition: nil),
                    .init(initialText: "Find * in this text.", initialCursorPosition: 0,
                          expectedText: "Find  in this text.", expectedCursorPosition: nil),
                    .init(initialText: "Navigate here to * now.", initialCursorPosition: 0,
                          expectedText: "Navigate here to  now.", expectedCursorPosition: nil),
                    .init(initialText: "Move right to * please.", initialCursorPosition: 0,
                          expectedText: "Move right to  please.", expectedCursorPosition: nil),
                    .init(initialText: "Spot the * character.", initialCursorPosition: 0,
                          expectedText: "Spot the  character.", expectedCursorPosition: nil),
                    .init(initialText: "Where is * hiding?", initialCursorPosition: 0,
                          expectedText: "Where is  hiding?", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["f", "F"]
    )

    // MARK: - Lesson 4.2: Till Character

    private static let lesson4_2 = Lesson(
        id: "ch4.l2",
        number: 2,
        title: "Till Character",
        subtitle: "Stop just before with t and T",
        explanation: [
            .heading("Jump to Just Before a Character"),
            .text("t works like f, but stops one character before the target. T does the same backward."),
            .spacer,
            .keyCommand(keys: ["t", "x"], description: "Move to just before 'x' (forward)"),
            .keyCommand(keys: ["T", "x"], description: "Move to just after 'x' (backward)"),
            .spacer,
            .text("t is especially useful with operators: dt) deletes everything up to (but not including) the closing parenthesis."),
            .tip("Think: f = find (land on it), t = till (stop just before it)."),
        ],
        exercises: [
            Exercise(
                id: "ch4.l2.e1",
                instruction: "Use dt) to delete everything before the closing parenthesis",
                initialText: "(remove this text)",
                initialCursorPosition: 1,
                expectedText: "()",
                expectedCursorPosition: nil,
                hints: ["Position inside the parens, then type dt)"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "(delete me)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(extra words here)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(clean this up)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(junk inside)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["t", "T"]
    )

    // MARK: - Lesson 4.3: Repeat Find

    private static let lesson4_3 = Lesson(
        id: "ch4.l3",
        number: 3,
        title: "Repeat Find",
        subtitle: "Jump again with ; and ,",
        explanation: [
            .heading("Repeat Your Last f or t"),
            .text("After using f or t, press ; to repeat the same search forward, or , to repeat it backward."),
            .spacer,
            .keyCommand(keys: [";"], description: "Repeat last f/t search (same direction)"),
            .keyCommand(keys: [","], description: "Repeat last f/t search (opposite direction)"),
            .spacer,
            .text("This lets you hop between multiple occurrences of the same character without retyping the search."),
        ],
        exercises: [
            Exercise(
                id: "ch4.l3.e1",
                instruction: "Use f. to find the first period, then ; to jump to the next one",
                initialText: "First. Second. Third.",
                initialCursorPosition: 0,
                expectedText: "First. Second. Third.",
                expectedCursorPosition: 14,
                hints: ["Type f. to jump to first period, then ; to jump to the second"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: [";", ","]
    )

    // MARK: - Lesson 4.4: Search Next/Previous

    private static let lesson4_4 = Lesson(
        id: "ch4.l4",
        number: 4,
        title: "Search Navigation",
        subtitle: "Jump between matches with n and N",
        explanation: [
            .heading("Navigate Between Search Matches"),
            .text("After searching (in your macOS app with Cmd+F), use n to jump to the next match and N for the previous match."),
            .spacer,
            .keyCommand(keys: ["n"], description: "Jump to next search match"),
            .keyCommand(keys: ["N"], description: "Jump to previous search match"),
            .spacer,
            .text("kindaVim uses the application's own search feature. Press Cmd+F to search, then use n and N in Normal mode to navigate between matches."),
        ],
        exercises: [
            Exercise(
                id: "ch4.l4.e1",
                instruction: "This exercise uses n/N with your app's search. Practice moving between matches.",
                initialText: "Find the word here. The word appears here. Another word here.",
                initialCursorPosition: 0,
                expectedText: "Find the word here. The word appears here. Another word here.",
                expectedCursorPosition: 53,
                hints: ["Use Cmd+F to search for 'word', then press Esc, then n to jump to each match"],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["n", "N"]
    )
}
