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
            lesson1_6,
            lesson1_7,
        ]
    )

    // MARK: - Lesson 1.1: Moving the Cursor

    private static let lesson1_1 = Lesson(
        id: "ch1.l1",
        number: 1,
        title: "Moving the Cursor",
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
        ],
        exercises: [
            // Exercise 1: Move down with j — navigate to the * and delete it
            Exercise(
                id: "ch1.l1.e1",
                instruction: "Move down to the * using j, then delete it with x",
                initialText: "\n\n\n\n* <-- move here with j, delete with x\n\n",
                initialCursorPosition: 0,
                expectedText: "\n\n\n\n <-- move here with j, delete with x\n\n",
                expectedCursorPosition: nil,
                hints: ["Press j repeatedly to move down, then x to delete the *"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n* <-- delete me\n\n\n\n", initialCursorPosition: 0,
                          expectedText: "\n\n <-- delete me\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n* <-- delete me\n", initialCursorPosition: 0,
                          expectedText: "\n\n\n\n\n\n <-- delete me\n", expectedCursorPosition: nil),
                    .init(initialText: "\n* <-- delete me\n\n\n\n\n\n", initialCursorPosition: 0,
                          expectedText: "\n <-- delete me\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n* <-- delete me\n\n\n", initialCursorPosition: 0,
                          expectedText: "\n\n\n <-- delete me\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n* <-- delete me\n\n\n", initialCursorPosition: 0,
                          expectedText: "\n\n\n\n\n <-- delete me\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n* <-- delete me", initialCursorPosition: 0,
                          expectedText: "\n\n\n\n\n\n\n <-- delete me", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n* <-- delete me\n\n\n\n", initialCursorPosition: 0,
                          expectedText: "\n\n\n\n <-- delete me\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n* <-- delete me\n\n\n", initialCursorPosition: 0,
                          expectedText: "\n <-- delete me\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n* <-- delete me\n\n\n", initialCursorPosition: 0,
                          expectedText: "\n\n\n\n\n\n <-- delete me\n\n\n", expectedCursorPosition: nil),
                ]
            ),
            // Exercise 2: Move up with k — navigate to the * and delete it
            Exercise(
                id: "ch1.l1.e2",
                instruction: "Move up to the * using k, then delete it with x",
                initialText: "\n\n* <-- move here with k, delete with x\n\n\n\n",
                initialCursorPosition: 43,
                expectedText: "\n\n <-- move here with k, delete with x\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Press k repeatedly to move up, then x to delete the *"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n* <-- delete me\n\n\n\n\n", initialCursorPosition: 22,
                          expectedText: "\n <-- delete me\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "* <-- delete me\n\n\n\n\n\n\n", initialCursorPosition: 23,
                          expectedText: " <-- delete me\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n* <-- delete me\n\n\n\n", initialCursorPosition: 25,
                          expectedText: "\n\n\n <-- delete me\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n* <-- delete me\n\n", initialCursorPosition: 25,
                          expectedText: "\n\n\n\n <-- delete me\n\n", expectedCursorPosition: nil),
                    .init(initialText: "* <-- delete me\n\n\n\n", initialCursorPosition: 19,
                          expectedText: " <-- delete me\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n* <-- delete me\n\n\n\n\n\n\n", initialCursorPosition: 26,
                          expectedText: "\n <-- delete me\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n* <-- delete me\n\n\n\n\n", initialCursorPosition: 24,
                          expectedText: "\n\n <-- delete me\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n* <-- delete me\n\n", initialCursorPosition: 27,
                          expectedText: "\n\n\n\n\n <-- delete me\n\n", expectedCursorPosition: nil),
                    .init(initialText: "* <-- delete me\n\n\n\n\n\n", initialCursorPosition: 21,
                          expectedText: " <-- delete me\n\n\n\n\n\n", expectedCursorPosition: nil),
                ]
            ),
            // Exercise 3: Move right with l — navigate to the * and delete it
            Exercise(
                id: "ch1.l1.e3",
                instruction: "Move right to the * using l, then delete it with x",
                initialText: "          * <-- delete with x",
                initialCursorPosition: 0,
                expectedText: "           <-- delete with x",
                expectedCursorPosition: nil,
                hints: ["Press l repeatedly to move right, then x to delete the *"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "    * <-- delete me", initialCursorPosition: 0,
                          expectedText: "     <-- delete me", expectedCursorPosition: nil),
                    .init(initialText: "              * <-- delete me", initialCursorPosition: 0,
                          expectedText: "               <-- delete me", expectedCursorPosition: nil),
                    .init(initialText: "      * <-- delete me", initialCursorPosition: 0,
                          expectedText: "       <-- delete me", expectedCursorPosition: nil),
                    .init(initialText: "                  * <-- delete me", initialCursorPosition: 0,
                          expectedText: "                   <-- delete me", expectedCursorPosition: nil),
                    .init(initialText: "   * <-- delete me", initialCursorPosition: 0,
                          expectedText: "    <-- delete me", expectedCursorPosition: nil),
                    .init(initialText: "        * <-- delete me", initialCursorPosition: 0,
                          expectedText: "         <-- delete me", expectedCursorPosition: nil),
                    .init(initialText: "            * <-- delete me", initialCursorPosition: 0,
                          expectedText: "             <-- delete me", expectedCursorPosition: nil),
                    .init(initialText: "  * <-- delete me", initialCursorPosition: 0,
                          expectedText: "   <-- delete me", expectedCursorPosition: nil),
                    .init(initialText: "                * <-- delete me", initialCursorPosition: 0,
                          expectedText: "                 <-- delete me", expectedCursorPosition: nil),
                ]
            ),
            // Exercise 4: Combined hjkl — navigate to the * anywhere on the grid
            Exercise(
                id: "ch1.l1.e4",
                instruction: "Navigate to the * using h, j, k, l and delete it with x",
                initialText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . * . . . .\n. . . . . . . .\n. . . . . . . .",
                initialCursorPosition: 0,
                expectedText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . .   . . . .\n. . . . . . . .\n. . . . . . . .",
                expectedCursorPosition: nil,
                hints: ["Use j/k to move vertically, h/l to move horizontally"],
                difficulty: .practice,
                drillCount: 10,
                variations: [
                    .init(initialText: ". . . . . . . .\n. . . . . . . .\n. . . . . * . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", initialCursorPosition: 0,
                          expectedText: ". . . . . . . .\n. . . . . . . .\n. . . . .   . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", expectedCursorPosition: nil),
                    .init(initialText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. * . . . . . .\n. . . . . . . .", initialCursorPosition: 0,
                          expectedText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n.   . . . . . .\n. . . . . . . .", expectedCursorPosition: nil),
                    .init(initialText: ". . . . . . . .\n. . . . . . * .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", initialCursorPosition: 80,
                          expectedText: ". . . . . . . .\n. . . . . .   .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", expectedCursorPosition: nil),
                    .init(initialText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . * . . .", initialCursorPosition: 0,
                          expectedText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . .   . . .", expectedCursorPosition: nil),
                    .init(initialText: "* . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", initialCursorPosition: 80,
                          expectedText: "  . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", expectedCursorPosition: nil),
                    .init(initialText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . *", initialCursorPosition: 0,
                          expectedText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . .  ", expectedCursorPosition: nil),
                    .init(initialText: ". . . . . . . .\n. . . . . . . .\n. * . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", initialCursorPosition: 80,
                          expectedText: ". . . . . . . .\n. . . . . . . .\n.   . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", expectedCursorPosition: nil),
                    .init(initialText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . * .\n. . . . . . . .", initialCursorPosition: 0,
                          expectedText: ". . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . .   .\n. . . . . . . .", expectedCursorPosition: nil),
                    .init(initialText: ". . . . . . . .\n. . . * . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", initialCursorPosition: 80,
                          expectedText: ". . . . . . . .\n. . .   . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["h", "j", "k", "l"]
    )

    // MARK: - Lesson 1.2: Deleting Characters

    private static let lesson1_2 = Lesson(
        id: "ch1.l2",
        number: 2,
        title: "Deleting Characters",
        subtitle: "Fix mistakes with x",
        explanation: [
            .heading("Delete What's Under the Cursor"),
            .text("In Normal mode, press x to delete the character under the cursor. This is how you fix typos without entering Insert mode."),
            .spacer,
            .keyCommand(keys: ["x"], description: "Delete character under cursor"),
            .spacer,
            .tip("Move to the bad character with h/l, then press x to remove it. Like using a single-character eraser."),
        ],
        exercises: [
            Exercise(
                id: "ch1.l2.e1",
                instruction: "Fix the sentence by deleting the extra characters with x",
                initialText: "The ccow jumped",
                initialCursorPosition: 4,
                expectedText: "The cow jumped",
                expectedCursorPosition: nil,
                hints: ["Move to the extra 'c' and press x"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "The cow jumpedd", initialCursorPosition: 14, expectedText: "The cow jumped", expectedCursorPosition: nil),
                    .init(initialText: "Thee quick fox", initialCursorPosition: 3, expectedText: "The quick fox", expectedCursorPosition: nil),
                    .init(initialText: "Hello wworld", initialCursorPosition: 6, expectedText: "Hello world", expectedCursorPosition: nil),
                    .init(initialText: "Good mmorning", initialCursorPosition: 5, expectedText: "Good morning", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["x"]
    )

    // MARK: - Lesson 1.3: Inserting Text

    private static let lesson1_3 = Lesson(
        id: "ch1.l3",
        number: 3,
        title: "Inserting Text",
        subtitle: "Enter Insert mode with i",
        explanation: [
            .heading("Two Ways of Being"),
            .text("Vim has modes. In Normal mode, keys are commands — h moves left, not types \"h\". In Insert mode, keys type text like you'd expect."),
            .spacer,
            .keyCommand(keys: ["i"], description: "Enter Insert mode before the cursor"),
            .keyCommand(keys: ["Esc"], description: "Return to Normal mode"),
            .spacer,
            .text("You'll spend most of your time in Normal mode, dipping into Insert mode only to type new text, then pressing Esc to come back."),
            .tip("If you're ever lost, press Esc. It always brings you back to Normal mode."),
        ],
        exercises: [
            Exercise(
                id: "ch1.l3.e1",
                instruction: "Press i to enter Insert mode, type \"Hello\", then press Esc",
                initialText: "",
                initialCursorPosition: 0,
                expectedText: "Hello",
                expectedCursorPosition: nil,
                hints: ["Press i, type Hello, then press Esc"],
                difficulty: .learn
            ),
            Exercise(
                id: "ch1.l3.e2",
                instruction: "Insert the missing word. The line should read \"There is some text missing\"",
                initialText: "There is text missing",
                initialCursorPosition: 8,
                expectedText: "There is some text missing",
                expectedCursorPosition: nil,
                hints: ["Move to position 9, press i, type \"some \", press Esc"],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["i", "Esc"]
    )

    // MARK: - Lesson 1.4: Appending Text

    private static let lesson1_4 = Lesson(
        id: "ch1.l4",
        number: 4,
        title: "Appending Text",
        subtitle: "Add text at the end with A",
        explanation: [
            .heading("Append to the End of a Line"),
            .text("Sometimes you need to add text at the end of a line. Instead of moving all the way to the end with l, you can use A to jump there and enter Insert mode in one step."),
            .spacer,
            .keyCommand(keys: ["A"], description: "Append text at end of line"),
            .keyCommand(keys: ["a"], description: "Append text after the cursor"),
            .spacer,
            .tip("A (uppercase) goes to the end of the line. a (lowercase) inserts right after the cursor position."),
        ],
        exercises: [
            Exercise(
                id: "ch1.l4.e1",
                instruction: "Complete the line using A. It should read \"This line is complete.\"",
                initialText: "This line is",
                initialCursorPosition: 0,
                expectedText: "This line is complete.",
                expectedCursorPosition: nil,
                hints: ["Press A to jump to end and enter Insert mode, type \" complete.\", press Esc"],
                difficulty: .learn
            ),
            Exercise(
                id: "ch1.l4.e2",
                instruction: "Complete the line. It should read \"Vim is powerful.\"",
                initialText: "Vim is",
                initialCursorPosition: 0,
                expectedText: "Vim is powerful.",
                expectedCursorPosition: nil,
                hints: ["Press A, type \" powerful.\", press Esc"],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["A", "a"]
    )

    // MARK: - Lesson 1.5: Undoing Mistakes

    private static let lesson1_5 = Lesson(
        id: "ch1.l5",
        number: 5,
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
                id: "ch1.l5.e1",
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

    // MARK: - Lesson 1.6: Word Hopping

    private static let lesson1_6 = Lesson(
        id: "ch1.l6",
        number: 6,
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
                id: "ch1.l6.e1",
                instruction: "Jump from the beginning to the word \"fox\" using w",
                initialText: "The quick brown fox jumps",
                initialCursorPosition: 0,
                expectedText: "The quick brown fox jumps",
                expectedCursorPosition: 16,
                hints: ["Press w three times: The → quick → brown → fox"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "One two three four five", initialCursorPosition: 0, expectedText: "One two three four five", expectedCursorPosition: 14),
                    .init(initialText: "She sells sea shells", initialCursorPosition: 0, expectedText: "She sells sea shells", expectedCursorPosition: 14),
                    .init(initialText: "Move to this word here", initialCursorPosition: 0, expectedText: "Move to this word here", expectedCursorPosition: 13),
                    .init(initialText: "Find the target now", initialCursorPosition: 0, expectedText: "Find the target now", expectedCursorPosition: 9),
                ]
            ),
            Exercise(
                id: "ch1.l6.e2",
                instruction: "Jump backward from the end to \"quick\" using b",
                initialText: "The quick brown fox jumps",
                initialCursorPosition: 20,
                expectedText: "The quick brown fox jumps",
                expectedCursorPosition: 4,
                hints: ["Press b three times to go back three words"],
                difficulty: .learn
            ),
            Exercise(
                id: "ch1.l6.e3",
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

    // MARK: - Lesson 1.7: Line Jumps

    private static let lesson1_7 = Lesson(
        id: "ch1.l7",
        number: 7,
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
                id: "ch1.l7.e1",
                instruction: "Jump to the end of the line using $",
                initialText: "Jump to the very end of this line",
                initialCursorPosition: 0,
                expectedText: "Jump to the very end of this line",
                expectedCursorPosition: 32,
                hints: ["Press $ to jump to the last character"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "A shorter line", initialCursorPosition: 0, expectedText: "A shorter line", expectedCursorPosition: 13),
                    .init(initialText: "This one is a bit longer than before", initialCursorPosition: 0, expectedText: "This one is a bit longer than before", expectedCursorPosition: 35),
                    .init(initialText: "Go to the end", initialCursorPosition: 0, expectedText: "Go to the end", expectedCursorPosition: 12),
                    .init(initialText: "Practice makes perfect", initialCursorPosition: 0, expectedText: "Practice makes perfect", expectedCursorPosition: 21),
                ]
            ),
            Exercise(
                id: "ch1.l7.e2",
                instruction: "Jump to the beginning of the line using 0",
                initialText: "Get back to the start",
                initialCursorPosition: 16,
                expectedText: "Get back to the start",
                expectedCursorPosition: 0,
                hints: ["Press 0 to jump to the first character"],
                difficulty: .learn
            ),
            Exercise(
                id: "ch1.l7.e3",
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
