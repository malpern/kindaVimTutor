import Foundation

extension Curriculum {
    static let chapter3 = Chapter(
        id: "ch3",
        number: 3,
        title: "Put, Replace, Change",
        subtitle: "Rearrange and transform text",
        systemImage: "arrow.triangle.swap",
        lessons: [
            lesson3_1, lesson3_2, lesson3_3, lesson3_4, lesson3_5,
        ]
    )

    // MARK: - Lesson 3.1: Put (Paste)

    private static let lesson3_1 = Lesson(
        id: "ch3.l1",
        number: 1,
        title: "Put (Paste)",
        subtitle: "Paste deleted text with p",
        explanation: [
            .heading("What You Delete, You Can Put Back"),
            .text("When you delete text with d or dd, Vim remembers it. Press p to put (paste) it after the cursor, or P to put it before."),
            .spacer,
            .keyCommand(keys: ["p"], description: "Put (paste) after cursor"),
            .keyCommand(keys: ["P"], description: "Put (paste) before cursor"),
            .spacer,
            .tip("Delete a line with dd, move to where you want it, press p. That's how you move lines around."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l1.e1",
                instruction: "Swap the lines: delete line B with dd, move down, paste with p",
                initialText: "A) First\nC) Third\nB) Second",
                initialCursorPosition: 9,
                expectedText: "A) First\nB) Second\nC) Third",
                expectedCursorPosition: nil,
                hints: ["On 'C) Third', press dd to cut it, move to 'B) Second', press p"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["p", "P"]
    )

    // MARK: - Lesson 3.2: Replace Character

    private static let lesson3_2 = Lesson(
        id: "ch3.l2",
        number: 2,
        title: "Replace Character",
        subtitle: "Fix single characters with r",
        explanation: [
            .heading("Replace Without Entering Insert Mode"),
            .text("Press r followed by a character to replace the character under the cursor. You stay in Normal mode."),
            .spacer,
            .keyCommand(keys: ["r", "x"], description: "Replace character under cursor with x"),
            .spacer,
            .tip("r is perfect for fixing single-character typos: navigate to it, press r, type the correction."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l2.e1",
                instruction: "Fix the wrong letter using r — change * to the correct character shown after //",
                initialText: "Th* cat // e",
                initialCursorPosition: 2,
                expectedText: "The cat // e",
                expectedCursorPosition: nil,
                hints: ["Move to *, press r, then type the letter shown after //"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "H*llo // e", initialCursorPosition: 1,
                          expectedText: "Hello // e", expectedCursorPosition: nil),
                    .init(initialText: "wo*ld // r", initialCursorPosition: 2,
                          expectedText: "world // r", expectedCursorPosition: nil),
                    .init(initialText: "g*od // o", initialCursorPosition: 1,
                          expectedText: "good // o", expectedCursorPosition: nil),
                    .init(initialText: "ni*e // c", initialCursorPosition: 2,
                          expectedText: "nice // c", expectedCursorPosition: nil),
                    .init(initialText: "co*e // d", initialCursorPosition: 2,
                          expectedText: "code // d", expectedCursorPosition: nil),
                    .init(initialText: "t*me // i", initialCursorPosition: 1,
                          expectedText: "time // i", expectedCursorPosition: nil),
                    .init(initialText: "li*e // n", initialCursorPosition: 2,
                          expectedText: "line // n", expectedCursorPosition: nil),
                    .init(initialText: "m*ke // a", initialCursorPosition: 1,
                          expectedText: "make // a", expectedCursorPosition: nil),
                    .init(initialText: "fi*e // l", initialCursorPosition: 2,
                          expectedText: "file // l", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["r"]
    )

    // MARK: - Lesson 3.3: Change Word

    private static let lesson3_3 = Lesson(
        id: "ch3.l3",
        number: 3,
        title: "Change Word",
        subtitle: "Delete and replace with ce",
        explanation: [
            .heading("Delete and Start Typing"),
            .text("The change operator c works like d, but drops you into Insert mode to type the replacement."),
            .spacer,
            .keyCommand(keys: ["c", "e"], description: "Change to end of word (delete + insert)"),
            .spacer,
            .tip("Think of c as \"change\" — delete the target, then immediately type what goes there instead."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l3.e1",
                instruction: "Change the WRONG word to RIGHT using ce",
                initialText: "This is WRONG here.",
                initialCursorPosition: 8,
                expectedText: "This is RIGHT here.",
                expectedCursorPosition: nil,
                hints: ["Move to WRONG, press ce, type RIGHT, press Esc"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "Say GOODBYE now.", initialCursorPosition: 4,
                          expectedText: "Say HELLO now.", expectedCursorPosition: nil),
                    .init(initialText: "The OLD way.", initialCursorPosition: 4,
                          expectedText: "The NEW way.", expectedCursorPosition: nil),
                    .init(initialText: "Go SLOW here.", initialCursorPosition: 3,
                          expectedText: "Go FAST here.", expectedCursorPosition: nil),
                    .init(initialText: "It is BAD code.", initialCursorPosition: 6,
                          expectedText: "It is GOOD code.", expectedCursorPosition: nil),
                    .init(initialText: "Turn LEFT now.", initialCursorPosition: 5,
                          expectedText: "Turn RIGHT now.", expectedCursorPosition: nil),
                    .init(initialText: "Press STOP here.", initialCursorPosition: 6,
                          expectedText: "Press START here.", expectedCursorPosition: nil),
                    .init(initialText: "Open INPUT file.", initialCursorPosition: 5,
                          expectedText: "Open OUTPUT file.", expectedCursorPosition: nil),
                    .init(initialText: "The FIRST try.", initialCursorPosition: 4,
                          expectedText: "The LAST try.", expectedCursorPosition: nil),
                    .init(initialText: "Set FALSE now.", initialCursorPosition: 4,
                          expectedText: "Set TRUE now.", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["ce", "cw"]
    )

    // MARK: - Lesson 3.4: Change to End of Line

    private static let lesson3_4 = Lesson(
        id: "ch3.l4",
        number: 4,
        title: "Change to End of Line",
        subtitle: "Rewrite the rest with C",
        explanation: [
            .heading("Replace Everything After the Cursor"),
            .text("C (or c$) deletes from the cursor to the end of the line and puts you in Insert mode."),
            .spacer,
            .keyCommand(keys: ["C"], description: "Change to end of line"),
            .spacer,
            .text("Useful when the end of a line is wrong and you want to retype it."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l4.e1",
                instruction: "Use C to replace everything after | with the text shown in // comment",
                initialText: "Good start |XXXXX // good end.",
                initialCursorPosition: 11,
                expectedText: "Good start good end.",
                expectedCursorPosition: nil,
                hints: ["Move to |, press C, type what the // comment says, press Esc"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["c$", "C"]
    )

    // MARK: - Lesson 3.5: Open Lines

    private static let lesson3_5 = Lesson(
        id: "ch3.l5",
        number: 5,
        title: "Open Lines",
        subtitle: "Create new lines with o and O",
        explanation: [
            .heading("Insert a New Line"),
            .text("Press o to open a new line below and enter Insert mode. Press O to open above."),
            .spacer,
            .keyCommand(keys: ["o"], description: "Open line below"),
            .keyCommand(keys: ["O"], description: "Open line above"),
            .spacer,
            .tip("o is one of the most common ways to start typing. Much faster than going to end of line and pressing Enter."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l5.e1",
                instruction: "Add 'Line two' between the lines using o",
                initialText: "Line one\nLine three",
                initialCursorPosition: 0,
                expectedText: "Line one\nLine two\nLine three",
                expectedCursorPosition: nil,
                hints: ["On 'Line one', press o, type 'Line two', press Esc"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["o", "O"]
    )
}
