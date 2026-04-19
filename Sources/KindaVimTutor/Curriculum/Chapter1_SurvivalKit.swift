import Foundation

extension Curriculum {
    static let chapter1 = Chapter(
        id: "ch1",
        number: 1,
        title: "Survival Kit",
        subtitle: "The essential motions to start moving",
        systemImage: "figure.walk",
        lessons: [
            lesson1_modes,
            lesson1_1,
            lesson1_2,
            lesson1_3,
            lesson1_4,
            lesson1_5,
            lesson1_6,
            lesson1_7,
        ]
    )

    // MARK: - Lesson 1.0: Meet the Modes

    private static let lesson1_modes = Lesson(
        id: "ch1.l0",
        number: 1,
        title: "Meet the Modes",
        subtitle: "Normal and Insert — the two keys that matter today",
        explanation: [
            .heading("Two Modes for Two Jobs"),
            .text("Every Mac text field works the same way out of the box: click in, type, letters appear. That's **Insert mode** — the only mode macOS gives you by default. You've been living in it your whole life."),
            .spacer,
            .text("kindaVim adds a second mode: **Normal mode**. In Normal mode the letters on your keyboard become commands instead of characters. `h` moves the cursor left. `w` jumps forward a word. `dd` deletes a line."),
            .spacer,
            .text("The mental model that helps most Mac users: it's like holding `⌘` — every key does something — except the letters don't get typed, and you don't have to keep a modifier held down. Normal mode stays on until you flip back."),
            .spacer,
            .keyCommand(keys: ["Esc"], description: "Switch to Normal mode — letters become commands"),
            .keyCommand(keys: ["i"], description: "Switch to Insert mode — letters type"),
            .spacer,
            .text("You'll spend most of your time in Normal mode, dipping into Insert only to add new text, then Esc back out. That rhythm is why Vim users feel fast — no reaching for a modifier, no mousing to a menu."),
            .spacer,
            .text("The chip in the top-right of this window shows your live mode — blue when you're in Insert, green when you're in Normal. Watch it as you practice."),
            .spacer,
            .tip("There's a third mode — Visual — for selecting text. You don't need it yet; it shows up properly in Chapter 5. A muted chip below lets you peek if you want."),
        ],
        exercises: [],
        motionsIntroduced: ["Esc", "i"],
        interactive: .modeSequence(
            expected: [.normal, .insert, .normal, .insert],
            instruction: "Press `Esc` — watch the chip turn green. Then `i` — blue again. Then `Esc` and `i` one more time to lock in the rhythm.",
            visualPreviewLessonId: "ch5.l1"
        )
    )

    // MARK: - Lesson 1.1: Moving the Cursor

    private static let lesson1_1 = Lesson(
        id: "ch1.l1",
        number: 2,
        title: "Moving the Cursor",
        subtitle: "Navigate with h, j, k, l",
        explanation: [
            .heading("Your Hands Stay on Home Row"),
            .text("In Normal mode, you navigate without arrow keys. Instead you use four keys right under your right hand:"),
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
                instruction: "Move down to the * using `j`, then delete it with `x`",
                initialText: "\n// Move down with j to reach *, then x to delete it\n\n\n*\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 53,
                expectedText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Press `j` repeatedly to move down, then `x` to delete the *"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n*\n\n\n\n\n\n\n\n", initialCursorPosition: 53, expectedText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n*\n\n\n\n\n\n", initialCursorPosition: 54, expectedText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n\n\n*\n\n\n\n", initialCursorPosition: 58, expectedText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n*\n\n", initialCursorPosition: 59, expectedText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n*\n", initialCursorPosition: 59, expectedText: "\n// Move down with j to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                ]
            ),
            // Exercise 2: Move up with k — navigate to the * and delete it
            Exercise(
                id: "ch1.l1.e2",
                instruction: "Move up to the * using `k`, then delete it with `x`",
                initialText: "// Move up with k to reach *, then x to delete it\n\n*\n\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 55,
                expectedText: "// Move up with k to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Press `k` repeatedly to move up, then `x` to delete the *"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "// Move up with k to reach *, then x to delete it\n\n\n*\n\n\n\n\n\n\n\n\n\n\n", initialCursorPosition: 57, expectedText: "// Move up with k to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "// Move up with k to reach *, then x to delete it\n\n\n\n*\n\n\n\n\n\n\n\n\n\n", initialCursorPosition: 59, expectedText: "// Move up with k to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "// Move up with k to reach *, then x to delete it\n\n\n\n\n*\n\n\n\n\n\n\n\n\n", initialCursorPosition: 58, expectedText: "// Move up with k to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "// Move up with k to reach *, then x to delete it\n\n\n\n\n\n*\n\n\n\n\n\n\n\n", initialCursorPosition: 60, expectedText: "// Move up with k to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "// Move up with k to reach *, then x to delete it\n\n\n\n\n\n\n*\n\n\n\n\n\n\n", initialCursorPosition: 62, expectedText: "// Move up with k to reach *, then x to delete it\n\n\n\n\n\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                ]
            ),
            // Exercise 3: Move right with l — navigate to the * and delete it
            Exercise(
                id: "ch1.l1.e3",
                instruction: "Move right to the * using `l`, then delete it with `x`",
                initialText: "\n\n// Move right with l to reach *, then x to delete it\n        *\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 55,
                expectedText: "\n\n// Move right with l to reach *, then x to delete it\n        \n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Press `l` repeatedly to move right, then `x` to delete the *"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Move right with l to reach *, then x to delete it\n              *\n\n\n\n\n\n\n\n", initialCursorPosition: 58, expectedText: "\n\n\n\n\n// Move right with l to reach *, then x to delete it\n              \n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Move right with l to reach *, then x to delete it\n                    *\n\n\n\n\n", initialCursorPosition: 61, expectedText: "\n\n\n\n\n\n\n\n// Move right with l to reach *, then x to delete it\n                    \n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Move right with l to reach *, then x to delete it\n                          *\n\n\n", initialCursorPosition: 63, expectedText: "\n\n\n\n\n\n\n\n\n\n// Move right with l to reach *, then x to delete it\n                          \n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n// Move right with l to reach *, then x to delete it\n                                *\n\n\n\n\n\n\n\n\n", initialCursorPosition: 57, expectedText: "\n\n\n\n// Move right with l to reach *, then x to delete it\n                                \n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Move right with l to reach *, then x to delete it\n                                      *\n\n", initialCursorPosition: 64, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Move right with l to reach *, then x to delete it\n                                      \n\n", expectedCursorPosition: nil),
                ]
            ),
            // Exercise 4: Combined hjkl — navigate to the * anywhere on the grid
            Exercise(
                id: "ch1.l1.e4",
                instruction: "Navigate to the * using `h`, `j`, `k`, `l` and delete it with `x`",
                initialText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . * . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n\n\n\n\n\n",
                initialCursorPosition: 56,
                expectedText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. .   . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Use `j`/`k` to move vertically, `h`/`l` to move horizontally"],
                difficulty: .practice,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . . * . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n\n\n\n\n\n", initialCursorPosition: 56, expectedText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . .   . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . . . . .\n* . . . . . . .\n. . . . . . . .\n. . . . . . . .\n\n\n\n\n\n", initialCursorPosition: 56, expectedText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . . . . .\n  . . . . . . .\n. . . . . . . .\n. . . . . . . .\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . *\n. . . . . . . .\n\n\n\n\n\n", initialCursorPosition: 56, expectedText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . .  \n. . . . . . . .\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . * . . . .\n\n\n\n\n\n", initialCursorPosition: 56, expectedText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . . . . . . .\n. . .   . . . .\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . . . . .\n. . . . . . * .\n. . . . . . . .\n. . . . . . . .\n\n\n\n\n\n", initialCursorPosition: 56, expectedText: "\n\n// Navigate to * using h j k l then delete it with x\n\n. . . . . . . .\n. . . . . . . .\n. . . . . .   .\n. . . . . . . .\n. . . . . . . .\n\n\n\n\n\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["h", "j", "k", "l"]
    )

    // MARK: - Lesson 1.2: Deleting Characters

    private static let lesson1_2 = Lesson(
        id: "ch1.l2",
        number: 3,
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
                instruction: "Fix the sentence by deleting the extra characters with `x`",
                initialText: "\n\n// Navigate to the duplicate letter and press x\nThe ccow jumped\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 71,
                expectedText: "\n\n// Navigate to the duplicate letter and press x\nThe cow jumped\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to the extra 'c' and press `x`"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Navigate to the duplicate letter and press x\nThe cow jumpedd\n\n\n\n\n\n\n\n", initialCursorPosition: 76, expectedText: "\n\n\n\n\n// Navigate to the duplicate letter and press x\nThe cow jumped\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Navigate to the duplicate letter and press x\nThee quick fox\n\n\n\n\n", initialCursorPosition: 7, expectedText: "\n\n\n\n\n\n\n\n// Navigate to the duplicate letter and press x\nThe quick fox\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Navigate to the duplicate letter and press x\nHello wworld\n\n\n", initialCursorPosition: 6, expectedText: "\n\n\n\n\n\n\n\n\n\n// Navigate to the duplicate letter and press x\nHello world\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n// Navigate to the duplicate letter and press x\nGood mmorning\n\n\n\n\n\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n// Navigate to the duplicate letter and press x\nGood morning\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Navigate to the duplicate letter and press x\nHello worldd\n\n", initialCursorPosition: 7, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Navigate to the duplicate letter and press x\nHello world\n\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["x"]
    )

    // MARK: - Lesson 1.3: Inserting Text

    private static let lesson1_3 = Lesson(
        id: "ch1.l3",
        number: 4,
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
                instruction: "Press `i` to enter Insert mode, type \"Hello\", then press `Esc`",
                initialText: "\n\n// Fix the typo by inserting \"n\" with i\nfunctio test\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 62,
                expectedText: "\n\n// Fix the typo by inserting \"n\" with i\nfunction test\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Navigate to the gap, press `i`, type the missing letter, press `Esc`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Fix the typo by inserting \"n\" with i\nretur value\n\n\n\n\n\n\n\n", initialCursorPosition: 61, expectedText: "\n\n\n\n\n// Fix the typo by inserting \"n\" with i\nreturn value\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Fix the typo by inserting \"t\" with i\nprin message\n\n\n\n\n", initialCursorPosition: 5, expectedText: "\n\n\n\n\n\n\n\n// Fix the typo by inserting \"t\" with i\nprint message\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Fix the typo by inserting \"s\" with i\nclas Name\n\n\n", initialCursorPosition: 8, expectedText: "\n\n\n\n\n\n\n\n\n\n// Fix the typo by inserting \"s\" with i\nclass Name\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n// Fix the typo by inserting \"e\" with i\nwhil active\n\n\n\n\n\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n// Fix the typo by inserting \"e\" with i\nwhile active\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Fix the typo by inserting \"e\" with i\ncontinu loop\n\n", initialCursorPosition: 65, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Fix the typo by inserting \"e\" with i\ncontinue loop\n\n", expectedCursorPosition: nil),
                ]
            ),
            Exercise(
                id: "ch1.l3.e2",
                instruction: "Insert a missing word using `i`",
                initialText: "\n\n// Insert \"some\" using i (press i, type, Esc)\nThere is text missing\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 77,
                expectedText: "\n\n// Insert \"some\" using i (press i, type, Esc)\nThere is some text missing\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to the right spot, press `i`, type the word + space, press `Esc`"],
                difficulty: .practice,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Insert \"just\" using i (press i, type, Esc)\nI ate breakfast\n\n\n\n\n\n\n\n", initialCursorPosition: 68, expectedText: "\n\n\n\n\n// Insert \"just\" using i (press i, type, Esc)\nI just ate breakfast\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Insert \"it\" using i (press i, type, Esc)\nDo it now\n\n\n\n\n", initialCursorPosition: 63, expectedText: "\n\n\n\n\n\n\n\n// Insert \"it\" using i (press i, type, Esc)\nDo it it now\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Insert \"really\" using i (press i, type, Esc)\nCode works fine\n\n\n", initialCursorPosition: 9, expectedText: "\n\n\n\n\n\n\n\n\n\n// Insert \"really\" using i (press i, type, Esc)\nCode really works fine\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n// Insert \"really\" using i (press i, type, Esc)\nThis is good\n\n\n\n\n\n\n\n\n", initialCursorPosition: 67, expectedText: "\n\n\n\n// Insert \"really\" using i (press i, type, Esc)\nThis really is good\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Insert \"to\" using i (press i, type, Esc)\nWe learn vim\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Insert \"to\" using i (press i, type, Esc)\nWe to learn vim\n\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["i", "Esc"]
    )

    // MARK: - Lesson 1.4: Appending Text

    private static let lesson1_4 = Lesson(
        id: "ch1.l4",
        number: 5,
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
                instruction: "Complete the line using `A`. It should read \"This line is complete.\"",
                initialText: "\n\n// Use A to append \"complete.\" at the end\nThis line is\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 62,
                expectedText: "\n\n// Use A to append \"complete.\" at the end\nThis line is complete.\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Press `A` to jump to end and enter Insert mode, type the suffix, press `Esc`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Use A to append \"powerful.\" at the end\nVim is\n\n\n\n\n\n\n\n", initialCursorPosition: 3, expectedText: "\n\n\n\n\n// Use A to append \"powerful.\" at the end\nVim is powerful.\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Use A to append \"ready.\" at the end\nI am\n\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n\n\n// Use A to append \"ready.\" at the end\nI am ready.\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Use A to append \"leave.\" at the end\nTime to\n\n\n", initialCursorPosition: 3, expectedText: "\n\n\n\n\n\n\n\n\n\n// Use A to append \"leave.\" at the end\nTime to leave.\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n// Use A to append \"done.\" at the end\nAlmost\n\n\n\n\n\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n// Use A to append \"done.\" at the end\nAlmost done.\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use A to append \"go now.\" at the end\nLet us\n\n", initialCursorPosition: 8, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use A to append \"go now.\" at the end\nLet us go now.\n\n", expectedCursorPosition: nil),
                ]
            ),
            Exercise(
                id: "ch1.l4.e2",
                instruction: "Complete the line. It should read \"Vim is powerful.\"",
                initialText: "Vim is",
                initialCursorPosition: 0,
                expectedText: "Vim is powerful.",
                expectedCursorPosition: nil,
                hints: ["Press `A`, type \" powerful.\", press `Esc`"],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["A", "a"]
    )

    // MARK: - Lesson 1.5: Undoing Mistakes

    private static let lesson1_5 = Lesson(
        id: "ch1.l5",
        number: 6,
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
                instruction: "The word \"world\" was deleted by mistake. Press `u` to undo and restore it.",
                initialText: "Hello ",
                initialCursorPosition: 5,
                expectedText: "Hello world",
                expectedCursorPosition: nil,
                hints: ["Press `u` to undo the last change"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["u", "Ctrl+r"]
    )

    // MARK: - Lesson 1.6: Word Hopping

    private static let lesson1_6 = Lesson(
        id: "ch1.l6",
        number: 7,
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
                instruction: "Jump from the beginning to the word \"fox\" using `w`",
                initialText: "\n\n// Use w to jump forward to \"fox\"\nA sly fox chased rabbits\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 36,
                expectedText: "\n\n// Use w to jump forward to \"fox\"\nA sly fox chased rabbits\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: 42,
                hints: ["Press `w` three times: The → quick → brown → fox"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Use w to jump forward to \"fox\"\nEvery wild fox hunts alone\n\n\n\n\n\n\n\n", initialCursorPosition: 39, expectedText: "\n\n\n\n\n// Use w to jump forward to \"fox\"\nEvery wild fox hunts alone\n\n\n\n\n\n\n\n", expectedCursorPosition: 50),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Use w to jump forward to \"fox\"\nThe tall fox looked around\n\n\n\n\n", initialCursorPosition: 42, expectedText: "\n\n\n\n\n\n\n\n// Use w to jump forward to \"fox\"\nThe tall fox looked around\n\n\n\n\n", expectedCursorPosition: 51),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Use w to jump forward to \"fox\"\nWatch the fox carefully\n\n\n", initialCursorPosition: 44, expectedText: "\n\n\n\n\n\n\n\n\n\n// Use w to jump forward to \"fox\"\nWatch the fox carefully\n\n\n", expectedCursorPosition: 54),
                    .init(initialText: "\n\n\n\n// Use w to jump forward to \"fox\"\nA lone fox walked slowly\n\n\n\n\n\n\n\n\n", initialCursorPosition: 38, expectedText: "\n\n\n\n// Use w to jump forward to \"fox\"\nA lone fox walked slowly\n\n\n\n\n\n\n\n\n", expectedCursorPosition: 45),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use w to jump forward to \"fox\"\nSee the fox move fast\n\n", initialCursorPosition: 45, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use w to jump forward to \"fox\"\nSee the fox move fast\n\n", expectedCursorPosition: 53),
                ]
            ),
            Exercise(
                id: "ch1.l6.e2",
                instruction: "Jump backward from the end to \"quick\" using `b`",
                initialText: "\n\n// Start at end of line, use b to jump back to \"quick\"\nThe quick brown fox jumps\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 81,
                expectedText: "\n\n// Start at end of line, use b to jump back to \"quick\"\nThe quick brown fox jumps\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: 61,
                hints: ["From end of line, press `b` to jump back word-by-word"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nA quick brown cat ran\n\n\n\n\n\n\n\n", initialCursorPosition: 80, expectedText: "\n\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nA quick brown cat ran\n\n\n\n\n\n\n\n", expectedCursorPosition: 62),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nSee the quick deer run\n\n\n\n\n", initialCursorPosition: 84, expectedText: "\n\n\n\n\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nSee the quick deer run\n\n\n\n\n", expectedCursorPosition: 71),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nFind the quick rabbit here\n\n\n", initialCursorPosition: 90, expectedText: "\n\n\n\n\n\n\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nFind the quick rabbit here\n\n\n", expectedCursorPosition: 74),
                    .init(initialText: "\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nThe quick bird flew up\n\n\n\n\n\n\n\n\n", initialCursorPosition: 80, expectedText: "\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nThe quick bird flew up\n\n\n\n\n\n\n\n\n", expectedCursorPosition: 63),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nWatch the quick fish swim\n\n", initialCursorPosition: 90, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Start at end of line, use b to jump back to \"quick\"\nWatch the quick fish swim\n\n", expectedCursorPosition: 76),
                ]
            ),
            Exercise(
                id: "ch1.l6.e3",
                instruction: "Jump to the end of \"brown\" using `e`",
                initialText: "\n\n// Use e to jump to the end of \"brown\"\nThe quick brown fox jumps\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 49,
                expectedText: "\n\n// Use e to jump to the end of \"brown\"\nThe quick brown fox jumps\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: 55,
                hints: ["Press `e` to jump to the end of the current/next word"],
                difficulty: .practice,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Use e to jump to the end of \"brown\"\nSee the brown bear walk\n\n\n\n\n\n\n\n", initialCursorPosition: 50, expectedText: "\n\n\n\n\n// Use e to jump to the end of \"brown\"\nSee the brown bear walk\n\n\n\n\n\n\n\n", expectedCursorPosition: 56),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Use e to jump to the end of \"brown\"\nA big brown dog barks\n\n\n\n\n", initialCursorPosition: 51, expectedText: "\n\n\n\n\n\n\n\n// Use e to jump to the end of \"brown\"\nA big brown dog barks\n\n\n\n\n", expectedCursorPosition: 57),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Use e to jump to the end of \"brown\"\nThe brown leaf fell\n\n\n", initialCursorPosition: 51, expectedText: "\n\n\n\n\n\n\n\n\n\n// Use e to jump to the end of \"brown\"\nThe brown leaf fell\n\n\n", expectedCursorPosition: 57),
                    .init(initialText: "\n\n\n\n// Use e to jump to the end of \"brown\"\nWatch the brown cat\n\n\n\n\n\n\n\n\n", initialCursorPosition: 51, expectedText: "\n\n\n\n// Use e to jump to the end of \"brown\"\nWatch the brown cat\n\n\n\n\n\n\n\n\n", expectedCursorPosition: 57),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use e to jump to the end of \"brown\"\nThe brown horse runs\n\n", initialCursorPosition: 52, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use e to jump to the end of \"brown\"\nThe brown horse runs\n\n", expectedCursorPosition: 58),
                ]
            ),
        ],
        motionsIntroduced: ["w", "b", "e"]
    )

    // MARK: - Lesson 1.7: Line Jumps

    private static let lesson1_7 = Lesson(
        id: "ch1.l7",
        number: 8,
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
                instruction: "Jump to the end of the line using `$`",
                initialText: "\n\n// Use $ to jump to the end of the line\nJump to the very end of this line\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 42,
                expectedText: "\n\n// Use $ to jump to the end of the line\nJump to the very end of this line\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: 74,
                hints: ["Press `$` to jump to the last character"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Use $ to jump to the end of the line\nA shorter line\n\n\n\n\n\n\n\n", initialCursorPosition: 45, expectedText: "\n\n\n\n\n// Use $ to jump to the end of the line\nA shorter line\n\n\n\n\n\n\n\n", expectedCursorPosition: 58),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Use $ to jump to the end of the line\nThis one is a bit longer\n\n\n\n\n", initialCursorPosition: 48, expectedText: "\n\n\n\n\n\n\n\n// Use $ to jump to the end of the line\nThis one is a bit longer\n\n\n\n\n", expectedCursorPosition: 71),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Use $ to jump to the end of the line\nGo to the end\n\n\n", initialCursorPosition: 50, expectedText: "\n\n\n\n\n\n\n\n\n\n// Use $ to jump to the end of the line\nGo to the end\n\n\n", expectedCursorPosition: 62),
                    .init(initialText: "\n\n\n\n// Use $ to jump to the end of the line\nPractice makes perfect\n\n\n\n\n\n\n\n\n", initialCursorPosition: 44, expectedText: "\n\n\n\n// Use $ to jump to the end of the line\nPractice makes perfect\n\n\n\n\n\n\n\n\n", expectedCursorPosition: 65),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use $ to jump to the end of the line\nEnd me here fast\n\n", initialCursorPosition: 51, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use $ to jump to the end of the line\nEnd me here fast\n\n", expectedCursorPosition: 66),
                ]
            ),
            Exercise(
                id: "ch1.l7.e2",
                instruction: "Jump to the beginning of the line using `0`",
                initialText: "\n\n// Use 0 to jump to the first character of the line\nGet back to the start\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 74,
                expectedText: "\n\n// Use 0 to jump to the first character of the line\nGet back to the start\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: 54,
                hints: ["Press `0` to jump to the first character"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Use 0 to jump to the first character of the line\nGo all the way left\n\n\n\n\n\n\n\n", initialCursorPosition: 75, expectedText: "\n\n\n\n\n// Use 0 to jump to the first character of the line\nGo all the way left\n\n\n\n\n\n\n\n", expectedCursorPosition: 57),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Use 0 to jump to the first character of the line\nReturn to the beginning\n\n\n\n\n", initialCursorPosition: 82, expectedText: "\n\n\n\n\n\n\n\n// Use 0 to jump to the first character of the line\nReturn to the beginning\n\n\n\n\n", expectedCursorPosition: 60),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Use 0 to jump to the first character of the line\nJump to column zero\n\n\n", initialCursorPosition: 80, expectedText: "\n\n\n\n\n\n\n\n\n\n// Use 0 to jump to the first character of the line\nJump to column zero\n\n\n", expectedCursorPosition: 62),
                    .init(initialText: "\n\n\n\n// Use 0 to jump to the first character of the line\nStart of the line now\n\n\n\n\n\n\n\n\n", initialCursorPosition: 76, expectedText: "\n\n\n\n// Use 0 to jump to the first character of the line\nStart of the line now\n\n\n\n\n\n\n\n\n", expectedCursorPosition: 56),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use 0 to jump to the first character of the line\nBack to home position\n\n", initialCursorPosition: 83, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use 0 to jump to the first character of the line\nBack to home position\n\n", expectedCursorPosition: 63),
                ]
            ),
            Exercise(
                id: "ch1.l7.e3",
                instruction: "Jump to the first non-space character using `^`",
                initialText: "\n\n// Use ^ to jump to the first non-blank character\n    indented text here\n\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 73,
                expectedText: "\n\n// Use ^ to jump to the first non-blank character\n    indented text here\n\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: 56,
                hints: ["Press `^` to jump past the leading spaces"],
                difficulty: .practice,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n// Use ^ to jump to the first non-blank character\n        deeply indented\n\n\n\n\n\n\n\n", initialCursorPosition: 77, expectedText: "\n\n\n\n\n// Use ^ to jump to the first non-blank character\n        deeply indented\n\n\n\n\n\n\n\n", expectedCursorPosition: 63),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Use ^ to jump to the first non-blank character\n  two spaces first\n\n\n\n\n", initialCursorPosition: 75, expectedText: "\n\n\n\n\n\n\n\n// Use ^ to jump to the first non-blank character\n  two spaces first\n\n\n\n\n", expectedCursorPosition: 60),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Use ^ to jump to the first non-blank character\n      six spaces here\n\n\n", initialCursorPosition: 80, expectedText: "\n\n\n\n\n\n\n\n\n\n// Use ^ to jump to the first non-blank character\n      six spaces here\n\n\n", expectedCursorPosition: 66),
                    .init(initialText: "\n\n\n\n// Use ^ to jump to the first non-blank character\n   three spaces then text\n\n\n\n\n\n\n\n\n", initialCursorPosition: 78, expectedText: "\n\n\n\n// Use ^ to jump to the first non-blank character\n   three spaces then text\n\n\n\n\n\n\n\n\n", expectedCursorPosition: 57),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use ^ to jump to the first non-blank character\n          ten spaces here\n\n", initialCursorPosition: 85, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use ^ to jump to the first non-blank character\n          ten spaces here\n\n", expectedCursorPosition: 71),
                ]
            ),
        ],
        motionsIntroduced: ["0", "$", "^"]
    )
}
