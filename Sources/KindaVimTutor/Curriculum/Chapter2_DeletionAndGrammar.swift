import Foundation

extension Curriculum {
    static let chapter2 = Chapter(
        id: "ch2",
        number: 2,
        title: "Deleting & The Vim Grammar",
        subtitle: "Operators, motions, and counts",
        systemImage: "scissors",
        lessons: [
            lesson2_1, lesson2_2, lesson2_3, lesson2_4, lesson2_5, lesson2_6,
        ]
    )

    // MARK: - Lesson 2.1: Delete Word

    private static let lesson2_1 = Lesson(
        id: "ch2.l1",
        number: 1,
        title: "Delete Word",
        subtitle: "Remove whole words with dw",
        explanation: [
            .heading("Delete From Cursor to Next Word"),
            .text("Deleting one character at a time with x is slow. Use dw to delete from the cursor to the start of the next word."),
            .spacer,
            .keyCommand(keys: ["d", "w"], description: "Delete to start of next word"),
            .spacer,
            .tip("Position your cursor at the beginning of the word you want to remove, then type dw."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l1.e1",
                instruction: "Delete the extra words. The line should read \"This is a sentence.\"",
                initialText: "This is a very long sentence.",
                initialCursorPosition: 10,
                expectedText: "This is a sentence.",
                expectedCursorPosition: nil,
                hints: ["Move to 'very', then press dw twice to delete 'very' and 'long'"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "There are a some words here.", initialCursorPosition: 10,
                          expectedText: "There are a here.", expectedCursorPosition: nil),
                    .init(initialText: "Delete the extra bad words now.", initialCursorPosition: 11,
                          expectedText: "Delete the words now.", expectedCursorPosition: nil),
                    .init(initialText: "She ran very quickly home.", initialCursorPosition: 8,
                          expectedText: "She ran home.", expectedCursorPosition: nil),
                    .init(initialText: "The old big cat sat.", initialCursorPosition: 4,
                          expectedText: "The cat sat.", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["dw"]
    )

    // MARK: - Lesson 2.2: Delete to End of Line

    private static let lesson2_2 = Lesson(
        id: "ch2.l2",
        number: 2,
        title: "Delete to End of Line",
        subtitle: "Clean up with d$ and D",
        explanation: [
            .heading("Delete Everything After the Cursor"),
            .text("Use d$ to delete from the cursor position to the end of the line. D does the same thing — it's a shortcut."),
            .spacer,
            .keyCommand(keys: ["d", "$"], description: "Delete to end of line"),
            .keyCommand(keys: ["D"], description: "Same as d$ (shortcut)"),
            .spacer,
            .tip("This is useful when a line has trailing junk you want to remove."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l2.e1",
                instruction: "Delete the duplicate text at the end. Keep only \"This line is correct.\"",
                initialText: "This line is correct. This line is wrong.",
                initialCursorPosition: 21,
                expectedText: "This line is correct.",
                expectedCursorPosition: nil,
                hints: ["Move to the space after the period, then press D or d$"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Keep this part. Remove this part.", initialCursorPosition: 15,
                          expectedText: "Keep this part.", expectedCursorPosition: nil),
                    .init(initialText: "First sentence. Extra junk here.", initialCursorPosition: 16,
                          expectedText: "First sentence.", expectedCursorPosition: nil),
                    .init(initialText: "Hello world. Goodbye world.", initialCursorPosition: 12,
                          expectedText: "Hello world.", expectedCursorPosition: nil),
                    .init(initialText: "Good code. Bad code here.", initialCursorPosition: 10,
                          expectedText: "Good code.", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["d$", "D"]
    )

    // MARK: - Lesson 2.3: Delete Entire Line

    private static let lesson2_3 = Lesson(
        id: "ch2.l3",
        number: 3,
        title: "Delete Entire Line",
        subtitle: "Remove whole lines with dd",
        explanation: [
            .heading("Delete the Whole Line"),
            .text("Press dd to delete the entire line the cursor is on. The lines below move up to fill the gap."),
            .spacer,
            .keyCommand(keys: ["d", "d"], description: "Delete entire current line"),
            .spacer,
            .text("This is one of the most commonly used Vim commands. The d key is pressed twice because whole-line deletion is so frequent it deserves a shortcut."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l3.e1",
                instruction: "Delete the line that doesn't belong",
                initialText: "Line one\nDELETE THIS LINE\nLine three",
                initialCursorPosition: 9,
                expectedText: "Line one\nLine three",
                expectedCursorPosition: nil,
                hints: ["Move to the middle line with j, then press dd"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Keep me\nRemove me\nKeep me too", initialCursorPosition: 8,
                          expectedText: "Keep me\nKeep me too", expectedCursorPosition: nil),
                    .init(initialText: "First\nSecond\nDELETE\nFourth", initialCursorPosition: 13,
                          expectedText: "First\nSecond\nFourth", expectedCursorPosition: nil),
                    .init(initialText: "Alpha\nREMOVE\nBravo\nCharlie", initialCursorPosition: 6,
                          expectedText: "Alpha\nBravo\nCharlie", expectedCursorPosition: nil),
                    .init(initialText: "Stay\nGo away\nStay", initialCursorPosition: 5,
                          expectedText: "Stay\nStay", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["dd"]
    )

    // MARK: - Lesson 2.4: The Vim Grammar

    private static let lesson2_4 = Lesson(
        id: "ch2.l4",
        number: 4,
        title: "The Vim Grammar",
        subtitle: "Operator + Motion = Command",
        explanation: [
            .heading("The Most Important Concept in Vim"),
            .text("Vim commands follow a grammar: an operator (what to do) followed by a motion (where to do it)."),
            .spacer,
            .text("You already know this! When you typed dw, you used the delete operator (d) with the word motion (w). When you typed d$, you used delete (d) with the end-of-line motion ($)."),
            .spacer,
            .text("This means every motion you learn multiplies every operator you know:"),
            .keyCommand(keys: ["d", "e"], description: "Delete to end of word"),
            .keyCommand(keys: ["d", "0"], description: "Delete to start of line"),
            .keyCommand(keys: ["d", "G"], description: "Delete to end of file"),
            .keyCommand(keys: ["d", "gg"], description: "Delete to start of file"),
            .spacer,
            .tip("This grammar is why Vim is so powerful. Learn a few operators and a few motions, and you can combine them freely."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l4.e1",
                instruction: "Use de to delete to the end of the word (including the last character)",
                initialText: "Fix theee broken word.",
                initialCursorPosition: 6,
                expectedText: "Fix th broken word.",
                expectedCursorPosition: nil,
                hints: ["Position on the first extra 'e', then press de"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Remove extrrra letters.", initialCursorPosition: 10,
                          expectedText: "Remove ext letters.", expectedCursorPosition: nil),
                    .init(initialText: "The badddd dog ran.", initialCursorPosition: 6,
                          expectedText: "The ba dog ran.", expectedCursorPosition: nil),
                    .init(initialText: "Helloooo world.", initialCursorPosition: 5,
                          expectedText: "Hello world.", expectedCursorPosition: nil),
                    .init(initialText: "Nice daaay today.", initialCursorPosition: 7,
                          expectedText: "Nice da today.", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["de", "d0", "dG", "dgg"]
    )

    // MARK: - Lesson 2.5: Counts with Motions

    private static let lesson2_5 = Lesson(
        id: "ch2.l5",
        number: 5,
        title: "Counts with Motions",
        subtitle: "Move faster with 2w, 3j, 4l",
        explanation: [
            .heading("Repeat a Motion Multiple Times"),
            .text("Type a number before a motion to repeat it that many times:"),
            .spacer,
            .keyCommand(keys: ["2", "w"], description: "Move forward 2 words"),
            .keyCommand(keys: ["3", "j"], description: "Move down 3 lines"),
            .keyCommand(keys: ["4", "l"], description: "Move right 4 characters"),
            .spacer,
            .text("Instead of pressing w three times, just type 3w. The number goes before the motion."),
            .tip("You can use counts with any motion: 5j moves down 5 lines, 10l moves right 10 characters."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l5.e1",
                instruction: "Use 3w to jump forward 3 words to reach \"target\"",
                initialText: "one two three target five six",
                initialCursorPosition: 0,
                expectedText: "one two three target five six",
                expectedCursorPosition: 14,
                hints: ["Type 3w to jump forward exactly 3 words"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "skip these two target here", initialCursorPosition: 0,
                          expectedText: "skip these two target here", expectedCursorPosition: 15),
                    .init(initialText: "a b c d target f g", initialCursorPosition: 0,
                          expectedText: "a b c d target f g", expectedCursorPosition: 8),
                    .init(initialText: "go past both words target end", initialCursorPosition: 0,
                          expectedText: "go past both words target end", expectedCursorPosition: 19),
                    .init(initialText: "one two target four five", initialCursorPosition: 0,
                          expectedText: "one two target four five", expectedCursorPosition: 8),
                ]
            ),
        ],
        motionsIntroduced: ["2w", "3j"]
    )

    // MARK: - Lesson 2.6: Counts with Operators

    private static let lesson2_6 = Lesson(
        id: "ch2.l6",
        number: 6,
        title: "Counts with Operators",
        subtitle: "Delete more with d2w, 2dd",
        explanation: [
            .heading("Combine Counts with Operators"),
            .text("Counts work with operator-motion combinations too:"),
            .spacer,
            .keyCommand(keys: ["d", "2", "w"], description: "Delete 2 words"),
            .keyCommand(keys: ["d", "3", "w"], description: "Delete 3 words"),
            .keyCommand(keys: ["2", "d", "d"], description: "Delete 2 lines"),
            .spacer,
            .text("The full Vim grammar is: [count] operator [count] motion. The count can go before the operator or before the motion — both work."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l6.e1",
                instruction: "Use d2w to delete exactly 2 words",
                initialText: "Keep REMOVE THESE words here.",
                initialCursorPosition: 5,
                expectedText: "Keep words here.",
                expectedCursorPosition: nil,
                hints: ["Move to 'REMOVE', then type d2w"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Good BAD UGLY text.", initialCursorPosition: 5,
                          expectedText: "Good text.", expectedCursorPosition: nil),
                    .init(initialText: "First EXTRA JUNK last.", initialCursorPosition: 6,
                          expectedText: "First last.", expectedCursorPosition: nil),
                    .init(initialText: "Save DELETE BOTH end.", initialCursorPosition: 5,
                          expectedText: "Save end.", expectedCursorPosition: nil),
                    .init(initialText: "Alpha GO AWAY Beta.", initialCursorPosition: 6,
                          expectedText: "Alpha Beta.", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["d2w", "2dd"]
    )
}
