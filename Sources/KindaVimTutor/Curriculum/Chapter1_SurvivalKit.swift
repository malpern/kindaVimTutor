import Foundation

extension Curriculum {
    static let chapter1 = Chapter(
        id: "ch1",
        number: 1,
        title: "Survival Kit",
        subtitle: "The essential motions to start moving",
        systemImage: "figure.walk",
        lessons: [
            lesson1_1,
            lesson1_2,
            lesson1_3,
            lesson1_4,
            lesson1_5,
        ]
    )

    // MARK: - Lesson 1: Moving Around

    private static let lesson1_1 = Lesson(
        id: "ch1.l1",
        number: 1,
        title: "Moving Around",
        subtitle: "Navigate with h, j, k, l",
        explanation: [
            .heading("Your Hands Stay on Home Row"),
            .text("In Vim, you navigate without arrow keys. Instead you use four keys right under your right hand:"),
            .spacer,
            .keyCommand(keys: ["h"], description: "Move left"),
            .keyCommand(keys: ["j"], description: "Move down"),
            .keyCommand(keys: ["k"], description: "Move up"),
            .keyCommand(keys: ["l"], description: "Move right"),
            .spacer,
            .tip("Think of j as having a little hook at the bottom pointing downward. That's how you remember j goes down."),
            .important("Make sure kindaVim shows NORMAL mode before trying these. If you're in INSERT mode, press Esc first."),
        ],
        exercises: [
            Exercise(
                id: "ch1.l1.e1",
                instruction: "Move the cursor down to the target line using j",
                initialText: "Start here\n\n\ntarget",
                initialCursorPosition: 0,
                expectedText: "Start here\n\n\ntarget",
                expectedCursorPosition: 13,
                hints: ["Press j to move down one line at a time"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Begin\n\ntarget", initialCursorPosition: 0, expectedText: "Begin\n\ntarget", expectedCursorPosition: 7),
                    .init(initialText: "Top\n\n\n\ntarget", initialCursorPosition: 0, expectedText: "Top\n\n\n\ntarget", expectedCursorPosition: 8),
                    .init(initialText: "Here\n\ntarget\nbelow", initialCursorPosition: 0, expectedText: "Here\n\ntarget\nbelow", expectedCursorPosition: 6),
                    .init(initialText: "Line one\nLine two\ntarget", initialCursorPosition: 0, expectedText: "Line one\nLine two\ntarget", expectedCursorPosition: 19),
                ]
            ),
            Exercise(
                id: "ch1.l1.e2",
                instruction: "Move the cursor right to the X using l",
                initialText: "Find the X here",
                initialCursorPosition: 0,
                expectedText: "Find the X here",
                expectedCursorPosition: 9,
                hints: ["Press l to move right one character at a time"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Go to X now", initialCursorPosition: 0, expectedText: "Go to X now", expectedCursorPosition: 6),
                    .init(initialText: "The X is here", initialCursorPosition: 0, expectedText: "The X is here", expectedCursorPosition: 4),
                    .init(initialText: "Spot the X mark", initialCursorPosition: 0, expectedText: "Spot the X mark", expectedCursorPosition: 9),
                    .init(initialText: "Here X", initialCursorPosition: 0, expectedText: "Here X", expectedCursorPosition: 5),
                ]
            ),
            Exercise(
                id: "ch1.l1.e3",
                instruction: "Move the cursor up to the first line using k",
                initialText: "Get up here\nMiddle line\nYou start here",
                initialCursorPosition: 23,
                expectedText: "Get up here\nMiddle line\nYou start here",
                expectedCursorPosition: 0,
                hints: ["Press k to move up one line at a time"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Target\nStart here", initialCursorPosition: 7, expectedText: "Target\nStart here", expectedCursorPosition: 0),
                    .init(initialText: "Go here\n\nYou are here", initialCursorPosition: 9, expectedText: "Go here\n\nYou are here", expectedCursorPosition: 0),
                    .init(initialText: "Top\nMiddle\nBottom", initialCursorPosition: 11, expectedText: "Top\nMiddle\nBottom", expectedCursorPosition: 0),
                    .init(initialText: "Up\n\n\nDown here", initialCursorPosition: 5, expectedText: "Up\n\n\nDown here", expectedCursorPosition: 0),
                ]
            ),
            Exercise(
                id: "ch1.l1.e4",
                instruction: "Navigate to the word \"goal\" using j and l",
                initialText: ". . . . .\n. . . . .\n. . goal .",
                initialCursorPosition: 0,
                expectedText: ". . . . .\n. . . . .\n. . goal .",
                expectedCursorPosition: 24,
                hints: ["Use j to go down, then l to move right to the target"],
                difficulty: .practice,
                drillCount: 5,
                variations: [
                    .init(initialText: ". . . . .\n. goal . .\n. . . . .", initialCursorPosition: 0, expectedText: ". . . . .\n. goal . .\n. . . . .", expectedCursorPosition: 12),
                    .init(initialText: ". . goal .\n. . . . .\n. . . . .", initialCursorPosition: 20, expectedText: ". . goal .\n. . . . .\n. . . . .", expectedCursorPosition: 4),
                    .init(initialText: ". . . . .\n. . . . .\n. . . goal", initialCursorPosition: 0, expectedText: ". . . . .\n. . . . .\n. . . goal", expectedCursorPosition: 26),
                    .init(initialText: "goal . . .\n. . . . .\n. . . . .", initialCursorPosition: 22, expectedText: "goal . . .\n. . . . .\n. . . . .", expectedCursorPosition: 0),
                ]
            ),
        ],
        motionsIntroduced: ["h", "j", "k", "l"]
    )

    // MARK: - Lesson 2: Normal and Insert Mode

    private static let lesson1_2 = Lesson(
        id: "ch1.l2",
        number: 2,
        title: "Normal and Insert Mode",
        subtitle: "The two modes you'll use most",
        explanation: [
            .heading("Two Ways of Being"),
            .text("Vim has modes. In Normal mode, keys are commands — h moves left, not types \"h\". In Insert mode, keys type text like you'd expect."),
            .spacer,
            .keyCommand(keys: ["i"], description: "Enter Insert mode (before cursor)"),
            .keyCommand(keys: ["Esc"], description: "Return to Normal mode"),
            .spacer,
            .text("You'll spend most of your time in Normal mode, dipping into Insert mode only to type new text, then pressing Esc to come back."),
            .tip("If you're ever lost, press Esc. It always brings you back to Normal mode."),
        ],
        exercises: [
            Exercise(
                id: "ch1.l2.e1",
                instruction: "Press i to enter Insert mode, type \"Hello\", then press Esc to return to Normal mode",
                initialText: "",
                initialCursorPosition: 0,
                expectedText: "Hello",
                expectedCursorPosition: nil,
                hints: ["Press i, type Hello, then press Esc"],
                difficulty: .learn
            ),
            Exercise(
                id: "ch1.l2.e2",
                instruction: "Move to the blank and type the missing word. The sentence should read \"The quick brown fox\"",
                initialText: "The quick  fox",
                initialCursorPosition: 0,
                expectedText: "The quick brown fox",
                expectedCursorPosition: nil,
                hints: ["Use l to move to position 10, press i, type \"brown\", press Esc"],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["i", "Esc"]
    )

    // MARK: - Lesson 3: Undoing Mistakes

    private static let lesson1_3 = Lesson(
        id: "ch1.l3",
        number: 3,
        title: "Undoing Mistakes",
        subtitle: "Everyone makes them",
        explanation: [
            .heading("Your Safety Net"),
            .text("Made a mistake? No problem. Vim has powerful undo and redo."),
            .spacer,
            .keyCommand(keys: ["u"], description: "Undo the last change"),
            .keyCommand(keys: ["Ctrl", "r"], description: "Redo (undo the undo)"),
            .spacer,
            .text("In kindaVim, undo sends Cmd+Z to the application, so it works just like the native macOS undo. You can press u multiple times to keep undoing."),
        ],
        exercises: [
            Exercise(
                id: "ch1.l3.e1",
                instruction: "The word \"world\" was deleted by mistake. Press u to undo and restore it.",
                initialText: "Hello ",
                initialCursorPosition: 5,
                expectedText: "Hello world",
                expectedCursorPosition: nil,
                hints: ["Press u to undo the last change"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["u", "Ctrl+r"]
    )

    // MARK: - Lesson 4: Word Hopping

    private static let lesson1_4 = Lesson(
        id: "ch1.l4",
        number: 4,
        title: "Word Hopping",
        subtitle: "Move faster with w, b, e",
        explanation: [
            .heading("Moving One Character Is Slow"),
            .text("Pressing l twenty times to cross a line is tedious. Instead, jump by words:"),
            .spacer,
            .keyCommand(keys: ["w"], description: "Jump to the start of the next word"),
            .keyCommand(keys: ["b"], description: "Jump to the start of the previous word"),
            .keyCommand(keys: ["e"], description: "Jump to the end of the current word"),
            .spacer,
            .tip("Think: w = word forward, b = back, e = end of word."),
            .text("These work on punctuation boundaries too. \"hello-world\" is three words to w/b/e (hello, -, world)."),
        ],
        exercises: [
            Exercise(
                id: "ch1.l4.e1",
                instruction: "Jump from the beginning to the word \"fox\" using w",
                initialText: "The quick brown fox jumps",
                initialCursorPosition: 0,
                expectedText: "The quick brown fox jumps",
                expectedCursorPosition: 16,
                hints: ["Press w three times: The → quick → brown → fox"],
                difficulty: .learn
            ),
            Exercise(
                id: "ch1.l4.e2",
                instruction: "Jump backward from \"jumps\" to \"quick\" using b",
                initialText: "The quick brown fox jumps",
                initialCursorPosition: 20,
                expectedText: "The quick brown fox jumps",
                expectedCursorPosition: 4,
                hints: ["Press b three times to go back three words"],
                difficulty: .learn
            ),
            Exercise(
                id: "ch1.l4.e3",
                instruction: "Move to the end of \"brown\" using e",
                initialText: "The quick brown fox",
                initialCursorPosition: 10,
                expectedText: "The quick brown fox",
                expectedCursorPosition: 14,
                hints: ["Press e to jump to the end of the current/next word"],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["w", "b", "e"]
    )

    // MARK: - Lesson 5: Line Jumps

    private static let lesson1_5 = Lesson(
        id: "ch1.l5",
        number: 5,
        title: "Line Jumps",
        subtitle: "Get to the start and end fast",
        explanation: [
            .heading("Jump to the Edges"),
            .text("Sometimes you need to get to the very beginning or end of a line instantly:"),
            .spacer,
            .keyCommand(keys: ["0"], description: "Jump to the first character of the line"),
            .keyCommand(keys: ["$"], description: "Jump to the last character of the line"),
            .keyCommand(keys: ["^"], description: "Jump to the first non-blank character"),
            .spacer,
            .tip("0 and $ are the most common. Think of $ as \"the end\" — same symbol used in regular expressions."),
        ],
        exercises: [
            Exercise(
                id: "ch1.l5.e1",
                instruction: "Jump to the end of the line using $",
                initialText: "Jump to the very end of this line",
                initialCursorPosition: 0,
                expectedText: "Jump to the very end of this line",
                expectedCursorPosition: 32,
                hints: ["Press $ to jump to the last character"],
                difficulty: .learn
            ),
            Exercise(
                id: "ch1.l5.e2",
                instruction: "Jump to the beginning of the line using 0",
                initialText: "Get back to the start",
                initialCursorPosition: 16,
                expectedText: "Get back to the start",
                expectedCursorPosition: 0,
                hints: ["Press 0 to jump to the first character"],
                difficulty: .learn
            ),
            Exercise(
                id: "ch1.l5.e3",
                instruction: "Jump to the first non-space character using ^",
                initialText: "    indented text here",
                initialCursorPosition: 18,
                expectedText: "    indented text here",
                expectedCursorPosition: 4,
                hints: ["Press ^ to jump past the leading spaces to \"indented\""],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["0", "$", "^"]
    )
}
