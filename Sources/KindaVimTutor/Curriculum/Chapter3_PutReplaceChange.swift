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
            .text("This is how you move text around: delete it from one place, move to where you want it, and put it there."),
            .tip("When you delete a whole line with dd, p puts it on the line below and P puts it on the line above."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l1.e1",
                instruction: "Move the second line below the third. Delete it with dd, move down, paste with p.",
                initialText: "Line A\nLine C\nLine B",
                initialCursorPosition: 7,
                expectedText: "Line A\nLine B\nLine C",
                expectedCursorPosition: nil,
                hints: ["On 'Line C', press dd. Move to 'Line B', press p."],
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
            .text("Press r followed by a character to replace the character under the cursor. You stay in Normal mode — no need for i and Esc."),
            .spacer,
            .keyCommand(keys: ["r", "x"], description: "Replace character under cursor with x"),
            .spacer,
            .text("This is faster than x followed by i for single-character fixes."),
            .tip("r is perfect for fixing typos: move to the wrong character, press r, then the correct character."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l2.e1",
                instruction: "Fix the typos using r. \"Whan\" should be \"When\", \"tine\" should be \"time\".",
                initialText: "Whan is the best tine?",
                initialCursorPosition: 2,
                expectedText: "When is the best time?",
                expectedCursorPosition: nil,
                hints: ["Move to 'a' in 'Whan', press re. Move to 'n' in 'tine', press rm."],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Tha cat sot down.", initialCursorPosition: 2,
                          expectedText: "The cat sat down.", expectedCursorPosition: nil),
                    .init(initialText: "She wint to thr store.", initialCursorPosition: 5,
                          expectedText: "She went to the store.", expectedCursorPosition: nil),
                    .init(initialText: "Ir is a nicd day.", initialCursorPosition: 1,
                          expectedText: "It is a nice day.", expectedCursorPosition: nil),
                    .init(initialText: "Goof morning friends.", initialCursorPosition: 3,
                          expectedText: "Good morning friends.", expectedCursorPosition: nil),
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
        subtitle: "Delete and replace with ce and cw",
        explanation: [
            .heading("Delete and Start Typing"),
            .text("The change operator c works like d, but after deleting it puts you in Insert mode so you can type the replacement."),
            .spacer,
            .keyCommand(keys: ["c", "e"], description: "Change to end of word (delete + insert)"),
            .keyCommand(keys: ["c", "w"], description: "Change word (delete + insert)"),
            .spacer,
            .text("ce deletes from the cursor to the end of the word and drops you into Insert mode. Type the replacement, then press Esc."),
            .tip("Think of c as \"change\" — it's d (delete) + i (insert) in one step."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l3.e1",
                instruction: "Change the wrong word to the right one using ce",
                initialText: "The cat jumped over the mooon.",
                initialCursorPosition: 24,
                expectedText: "The cat jumped over the moon.",
                expectedCursorPosition: nil,
                hints: ["Move to 'mooon', press ce, type 'moon', press Esc"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "She ate the appple.", initialCursorPosition: 12,
                          expectedText: "She ate the apple.", expectedCursorPosition: nil),
                    .init(initialText: "He ran to the stoore.", initialCursorPosition: 14,
                          expectedText: "He ran to the store.", expectedCursorPosition: nil),
                    .init(initialText: "The sunn is bright.", initialCursorPosition: 4,
                          expectedText: "The sun is bright.", expectedCursorPosition: nil),
                    .init(initialText: "I like programmming.", initialCursorPosition: 7,
                          expectedText: "I like programming.", expectedCursorPosition: nil),
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
        subtitle: "Rewrite the rest with c$ or C",
        explanation: [
            .heading("Replace Everything After the Cursor"),
            .text("c$ (or C) deletes from the cursor to the end of the line and puts you in Insert mode to type the replacement."),
            .spacer,
            .keyCommand(keys: ["c", "$"], description: "Change to end of line"),
            .keyCommand(keys: ["C"], description: "Same as c$ (shortcut)"),
            .spacer,
            .text("This is useful when the end of a line is wrong and you want to retype it."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l4.e1",
                instruction: "Fix the end of the line. It should read \"The end of this line is correct.\"",
                initialText: "The end of this line is WRONG WRONG.",
                initialCursorPosition: 23,
                expectedText: "The end of this line is correct.",
                expectedCursorPosition: nil,
                hints: ["Move to 'WRONG', press C, type 'correct.', press Esc"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Keep this but fix the rest XXXXX.", initialCursorPosition: 26,
                          expectedText: "Keep this but fix the rest here.", expectedCursorPosition: nil),
                    .init(initialText: "Good start bad end goes here.", initialCursorPosition: 11,
                          expectedText: "Good start, good end.", expectedCursorPosition: nil),
                    .init(initialText: "Hello REPLACE THIS PART.", initialCursorPosition: 6,
                          expectedText: "Hello world!", expectedCursorPosition: nil),
                    .init(initialText: "The answer is NOPE.", initialCursorPosition: 14,
                          expectedText: "The answer is 42.", expectedCursorPosition: nil),
                ]
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
            .text("Press o to open a new line below the cursor and enter Insert mode. Press O to open a new line above."),
            .spacer,
            .keyCommand(keys: ["o"], description: "Open line below and enter Insert mode"),
            .keyCommand(keys: ["O"], description: "Open line above and enter Insert mode"),
            .spacer,
            .tip("o is one of the most common ways to start typing new text. It saves you from pressing A, Enter."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l5.e1",
                instruction: "Add a new line between the two existing lines. Use o to open below.",
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
